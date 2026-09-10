{{ config(
    materialized='table',
    post_hook="{{apply_dmf_frameworkv1() }}")}}


WITH pk_inventory AS (
    
     SELECT
        i.TEST_UNIQUE_ID,
        i.TEST_NAME,
        i.TEST_TYPE,
        i.TESTED_COLUMN,
        i.COUNT_OF_COLUMNS_IN_PK,
        i.PK_DATA_TYPES_JSON,
        i.ACCEPTED_VALUES,
        i.MODEL_DATABASE,
        i.MODEL_SCHEMA,
        i.MODEL_TABLE,
        i.MODEL_TYPE,
        i.FK_PK_TABLE_NAME,
        i.FK_PK_COLUMN_NAME,
        i.MODEL_FILE_PATH,
        i.LOADED_AT,
        LISTAGG(
            UPPER(TRIM(f.VALUE::STRING)),
            ','
        ) WITHIN GROUP (
            ORDER BY UPPER(TRIM(f.VALUE::STRING))
        ) AS PK_COLUMNS
    FROM {{ref('dbt_yml_test_inventory') }} i,
         LATERAL FLATTEN(INPUT => SPLIT(i.TESTED_COLUMN, ',')) f
    WHERE UPPER(i.TEST_TYPE) = 'PRIMARY_KEY'
    GROUP BY
        i.TEST_UNIQUE_ID,
        i.TEST_NAME,
        i.TEST_TYPE,
        i.TESTED_COLUMN,
        i.COUNT_OF_COLUMNS_IN_PK,
        i.PK_DATA_TYPES_JSON,
        i.ACCEPTED_VALUES,
        i.MODEL_DATABASE,
        i.MODEL_SCHEMA,
        i.MODEL_TABLE,
        i.MODEL_TYPE,
        i.FK_PK_TABLE_NAME,
        i.FK_PK_COLUMN_NAME,
        i.MODEL_FILE_PATH,
        i.LOADED_AT
),

pk_dmf AS (
    SELECT
        a.REF_DATABASE_NAME,
        a.REF_SCHEMA_NAME,
        a.REF_ENTITY_NAME,
        a.METRIC_NAME,
        LISTAGG(
            DISTINCT UPPER(TRIM(PARSE_JSON(r.VALUE):name::STRING)),
            ','
        ) WITHIN GROUP (
            ORDER BY UPPER(TRIM(PARSE_JSON(r.VALUE):name::STRING))
        ) AS PK_COLUMNS
    FROM SNOWFLAKE.ACCOUNT_USAGE.DATA_METRIC_FUNCTION_REFERENCES a,
         LATERAL FLATTEN(INPUT => a.REF_ARGUMENTS) r
    WHERE UPPER(a.METRIC_NAME) LIKE 'DMF_PK%'
    AND UPPER(a.REF_DATABASE_NAME) = UPPER('{{ target.database }}')
      AND PARSE_JSON(r.VALUE):name::STRING IS NOT NULL
      AND TRIM(PARSE_JSON(r.VALUE):name::STRING) != ''
    GROUP BY
        a.REF_DATABASE_NAME,
        a.REF_SCHEMA_NAME,
        a.REF_ENTITY_NAME,
        a.METRIC_NAME
),

pk_missing AS (
    SELECT
        i.TEST_UNIQUE_ID,
        i.TEST_NAME,
        i.TEST_TYPE,
        i.TESTED_COLUMN,
        i.COUNT_OF_COLUMNS_IN_PK,
        i.PK_DATA_TYPES_JSON,
        i.ACCEPTED_VALUES,
        i.MODEL_DATABASE,
        i.MODEL_SCHEMA,
        i.MODEL_TABLE,
        i.MODEL_TYPE,
        i.FK_PK_TABLE_NAME,
        i.FK_PK_COLUMN_NAME,
        i.MODEL_FILE_PATH,
        i.LOADED_AT,
        i.PK_COLUMNS
    FROM pk_inventory i
    WHERE NOT EXISTS (
        SELECT 1
        FROM pk_dmf d
        WHERE UPPER(TRIM(i.MODEL_DATABASE)) = UPPER(TRIM(d.REF_DATABASE_NAME))
          AND UPPER(TRIM(i.MODEL_SCHEMA))   = UPPER(TRIM(d.REF_SCHEMA_NAME))
          AND UPPER(TRIM(i.MODEL_TABLE))    = UPPER(TRIM(d.REF_ENTITY_NAME))
          AND i.PK_COLUMNS = d.PK_COLUMNS
    )
),

inventory_cols AS (
    SELECT
        i.TEST_UNIQUE_ID,
        i.TEST_NAME,
        i.TEST_TYPE,
        i.TESTED_COLUMN,
        i.COUNT_OF_COLUMNS_IN_PK,
        i.PK_DATA_TYPES_JSON,
        i.ACCEPTED_VALUES,
        i.MODEL_DATABASE,
        i.MODEL_SCHEMA,
        i.MODEL_TABLE,
        i.MODEL_TYPE,
        i.FK_PK_TABLE_NAME,
        i.FK_PK_COLUMN_NAME,
        i.MODEL_FILE_PATH,
        i.LOADED_AT,
        TRIM(f.VALUE::STRING) AS TEST_COLUMN
    FROM {{ref('dbt_yml_test_inventory') }} i,
         LATERAL FLATTEN(INPUT => SPLIT(i.TESTED_COLUMN, ',')) f
    WHERE UPPER(i.TEST_TYPE) IN ('NOT_NULL', 'UNIQUE')
),

matched_cols AS (
    SELECT DISTINCT
        i.MODEL_DATABASE,
        i.MODEL_SCHEMA,
        i.MODEL_TABLE,
        i.TEST_TYPE,
        i.TEST_COLUMN
    FROM inventory_cols i,
         SNOWFLAKE.ACCOUNT_USAGE.DATA_METRIC_FUNCTION_REFERENCES a,
         LATERAL FLATTEN(INPUT => a.REF_ARGUMENTS) r
    WHERE  UPPER(a.REF_DATABASE_NAME) = UPPER('{{ target.database }}')
      AND UPPER(TRIM(i.MODEL_DATABASE)) = UPPER(TRIM(a.REF_DATABASE_NAME))
      AND UPPER(TRIM(i.MODEL_SCHEMA))   = UPPER(TRIM(a.REF_SCHEMA_NAME))
      AND UPPER(TRIM(i.MODEL_TABLE))    = UPPER(TRIM(a.REF_ENTITY_NAME))
      AND UPPER(TRIM(i.TEST_COLUMN))    = UPPER(TRIM(PARSE_JSON(r.VALUE):name::STRING))
      AND PARSE_JSON(r.VALUE):name::STRING IS NOT NULL
      AND TRIM(PARSE_JSON(r.VALUE):name::STRING) != ''
      AND (
            (UPPER(i.TEST_TYPE) = 'NOT_NULL'
             AND UPPER(a.METRIC_NAME) IN ('NULL_COUNT', 'DMF_HASHKEY_NULL_COUNT'))
         OR (UPPER(i.TEST_TYPE) = 'UNIQUE'
             AND UPPER(a.METRIC_NAME) IN ('DUPLICATE_COUNT', 'DMF_HASHKEY_UNIQUE_COUNT'))
          )
),

column_missing AS (
    SELECT DISTINCT
        i.TEST_UNIQUE_ID,
        i.TEST_NAME,
        i.TEST_TYPE,
        i.TESTED_COLUMN,
        i.COUNT_OF_COLUMNS_IN_PK,
        i.PK_DATA_TYPES_JSON,
        i.ACCEPTED_VALUES,
        i.MODEL_DATABASE,
        i.MODEL_SCHEMA,
        i.MODEL_TABLE,
        i.MODEL_TYPE,
        i.FK_PK_TABLE_NAME,
        i.FK_PK_COLUMN_NAME,
        i.MODEL_FILE_PATH,
        i.LOADED_AT,
        NULL AS PK_COLUMNS
    FROM inventory_cols i
    LEFT JOIN matched_cols m
      ON UPPER(TRIM(i.MODEL_DATABASE)) = UPPER(TRIM(m.MODEL_DATABASE))
     AND UPPER(TRIM(i.MODEL_SCHEMA))   = UPPER(TRIM(m.MODEL_SCHEMA))
     AND UPPER(TRIM(i.MODEL_TABLE))    = UPPER(TRIM(m.MODEL_TABLE))
     AND UPPER(TRIM(i.TEST_TYPE))      = UPPER(TRIM(m.TEST_TYPE))
     AND UPPER(TRIM(i.TEST_COLUMN))    = UPPER(TRIM(m.TEST_COLUMN))
    WHERE m.TEST_COLUMN IS NULL
)
,fk_inventory AS (
    SELECT *
    FROM {{ref('dbt_yml_test_inventory') }}
    WHERE UPPER(TEST_TYPE)='FOREIGN_KEY'
),

fk_dmf AS (
    SELECT
        REF_DATABASE_NAME,
        REF_SCHEMA_NAME,
        REF_ENTITY_NAME,
        PARSE_JSON(REF_ARGUMENTS[0]):name::STRING AS FK_COLUMN,
        SPLIT_PART(PARSE_JSON(REF_ARGUMENTS[1]):name::STRING,'.',-1) AS PK_TABLE,
        PARSE_JSON(REF_ARGUMENTS[1]):columns[0].name::STRING AS PK_COLUMN
    FROM SNOWFLAKE.ACCOUNT_USAGE.DATA_METRIC_FUNCTION_REFERENCES
    WHERE UPPER(METRIC_NAME)='DMF_FOREIGN_KEY'
     AND UPPER(REF_DATABASE_NAME)=UPPER('{{ target.database }}')
),

fk_missing AS (
    SELECT
        i.TEST_UNIQUE_ID,
        i.TEST_NAME,
        i.TEST_TYPE,
        i.TESTED_COLUMN,
        i.COUNT_OF_COLUMNS_IN_PK,
        i.PK_DATA_TYPES_JSON,
        i.ACCEPTED_VALUES,
        i.MODEL_DATABASE,
        i.MODEL_SCHEMA,
        i.MODEL_TABLE,
        i.MODEL_TYPE,
        i.FK_PK_TABLE_NAME,
        i.FK_PK_COLUMN_NAME,
        i.MODEL_FILE_PATH,
        i.LOADED_AT,
        NULL AS PK_COLUMNS
    FROM fk_inventory i
    WHERE NOT EXISTS (
        SELECT 1
        FROM fk_dmf d
        WHERE UPPER(i.MODEL_DATABASE)=UPPER(d.REF_DATABASE_NAME)
          AND UPPER(i.MODEL_SCHEMA)=UPPER(d.REF_SCHEMA_NAME)
          AND UPPER(i.MODEL_TABLE)=UPPER(d.REF_ENTITY_NAME)
          AND UPPER(i.TESTED_COLUMN)=UPPER(d.FK_COLUMN)
          AND UPPER(i.FK_PK_TABLE_NAME)=UPPER(d.PK_TABLE)
          AND UPPER(i.FK_PK_COLUMN_NAME)=UPPER(d.PK_COLUMN)
    )
)

SELECT *
FROM pk_missing

UNION ALL

SELECT *
FROM column_missing
UNION ALL

SELECT *
FROM fk_missing

ORDER BY
    MODEL_DATABASE,
    MODEL_SCHEMA,
    MODEL_TABLE,
    TEST_TYPE,
    TEST_NAME