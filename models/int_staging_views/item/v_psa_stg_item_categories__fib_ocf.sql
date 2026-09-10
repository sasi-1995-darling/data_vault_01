---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('outd_ocf_egp', 'egp_item_cat_assignments') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S2             as ( SELECT * FROM {{ source('outd_ocf_egp', 'egp_system_items_b') }} as SRC 
                        qualify 1 = row_number()over (partition by inventory_item_id, organization_id order by psa_load_dts )  )

/*
SRC_S              as ( SELECT * FROM outd_ocf_egp.egp_item_cat_assignments )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_S2             as ( SELECT * FROM outd_ocf_egp.egp_system_items_b )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        INVENTORY_ITEM_ID
      , ORGANIZATION_ID
      , CATEGORY_ID
      , CATEGORY_SET_ID
      , CREATION_DATE
      , ALT_ITEM_CAT_CODE
      , START_DATE
      , LAST_UPDATED_BY
      , PROGRAM_NAME
      , PROGRAM_APP_NAME
      , OBJECT_VERSION_NUMBER
      , CREATED_BY
      , ITEM_CATEGORY_ASSIGNMENT_ID
      , END_DATE
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , JOB_DEFINITION_PACKAGE
      , JOB_DEFINITION_NAME
      , SEQUENCE_NUMBER
      , REQUEST_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED )                   as                                           LOAD_DTS
    FROM SRC_S
)

, LOGIC_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_A
)

, LOGIC_S2 as (
    SELECT
        ITEM_NUMBER
      , INVENTORY_ITEM_ID                                            as                               S2_INVENTORY_ITEM_ID
      , ORGANIZATION_ID                                              as                                 S2_organization_id
    FROM SRC_S2
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        INVENTORY_ITEM_ID
      , ORGANIZATION_ID
      , CATEGORY_ID
      , CATEGORY_SET_ID
      , CREATION_DATE
      , ALT_ITEM_CAT_CODE
      , START_DATE
      , LAST_UPDATED_BY
      , PROGRAM_NAME
      , PROGRAM_APP_NAME
      , OBJECT_VERSION_NUMBER
      , CREATED_BY
      , ITEM_CATEGORY_ASSIGNMENT_ID
      , END_DATE
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , JOB_DEFINITION_PACKAGE
      , JOB_DEFINITION_NAME
      , SEQUENCE_NUMBER
      , REQUEST_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , LOAD_DTS
    FROM LOGIC_S
)

, RENAME_A as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_A
)

, RENAME_S2 as (
    SELECT
        ITEM_NUMBER
      , S2_INVENTORY_ITEM_ID
      , S2_organization_id
    FROM LOGIC_S2
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.EGP_ITEM_CAT_ASSIGNMENTS'
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
    LEFT JOIN FILTER_S2
        ON organization_id = S2_organization_id
and inventory_item_id = S2_inventory_item_id
)

---- FINAL LAYER ----
SELECT
          coalesce(nullif(trim(ITEM_NUMBER), ''), '-1')                as ITEM_BK
        , INVENTORY_ITEM_ID
        , ORGANIZATION_ID
        , CATEGORY_ID
        , CATEGORY_SET_ID
        , CREATION_DATE
        , ALT_ITEM_CAT_CODE
        , START_DATE
        , LAST_UPDATED_BY
        , PROGRAM_NAME
        , PROGRAM_APP_NAME
        , OBJECT_VERSION_NUMBER
        , CREATED_BY
        , ITEM_CATEGORY_ASSIGNMENT_ID
        , END_DATE
        , LAST_UPDATE_DATE
        , LAST_UPDATE_LOGIN
        , JOB_DEFINITION_PACKAGE
        , JOB_DEFINITION_NAME
        , SEQUENCE_NUMBER
        , REQUEST_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_SET_ID::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ALT_ITEM_CAT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CATEGORY_ASSIGNMENT_ID::text), '^^') 
            , '||', IFNULL(TRIM(END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_PACKAGE::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(SEQUENCE_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
