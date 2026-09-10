
---- SRC LAYER ----
WITH
    SRC_DEMAND_PLANNING AS (
        SELECT *
        FROM {{ ref('v_psa_stg_demand_planning__winn_sap') }} AS src ),
    SRC_DEMAND_PLANNING_HISTORY AS (
        SELECT *
        FROM {{ ref('v_psa_stg_demand_planning_history__winn_sap') }} AS src )

---- LOGIC LAYER ----

, LOGIC_DEMAND_PLANNING AS (
    SELECT
        forecasting_plan_period_hk,
        forecasting_plan_period_bk,
        bkcc,
        load_dts,
        rec_src
    FROM src_demand_planning
),

LOGIC_DEMAND_PLANNING_HISTORY AS (
    SELECT
        forecasting_plan_period_hk,
        forecasting_plan_period_bk,
        bkcc,
        load_dts,
        rec_src
    FROM src_demand_planning_history
)

---- RENAME LAYER ----

, RENAME_DEMAND_PLANNING AS (
    SELECT
        forecasting_plan_period_hk,
        forecasting_plan_period_bk,
        bkcc,
        load_dts,
        rec_src
    FROM logic_demand_planning
),

RENAME_DEMAND_PLANNING_HISTORY AS (
    SELECT
        forecasting_plan_period_hk,
        forecasting_plan_period_bk,
        bkcc,
        load_dts,
        rec_src
    FROM logic_demand_planning_history
)

---- FILTER LAYER ----

, FILTER_DEMAND_PLANNING AS (
    SELECT *
    FROM rename_demand_planning
),

FILTER_DEMAND_PLANNING_HISTORY AS (
    SELECT *
    FROM rename_demand_planning_history
    WHERE forecasting_plan_period_hk NOT IN (
        SELECT forecasting_plan_period_hk
        FROM filter_demand_planning
    )
)

---- JOIN LAYER ----

, JOIN_RESULT AS (
    SELECT * FROM filter_demand_planning
    UNION ALL
    SELECT * FROM filter_demand_planning_history
)

---- FINAL LAYER ----

SELECT
    forecasting_plan_period_hk,
    forecasting_plan_period_bk,
    bkcc,
    load_dts,
    rec_src
FROM join_result
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.forecasting_plan_period_hk = join_result.forecasting_plan_period_hk
)
{% endif %}
qualify 1 = row_number() over (partition by forecasting_plan_period_bk, BKCC order by LOAD_DTS)
{% if not is_incremental() %}
UNION ALL

SELECT
    MD5_BINARY(GR.VALUE) AS FORECASTING_PLAN_PERIOD_HK,
    GR.VALUE::text AS FORECASTING_PLAN_PERIOD_BK,
    DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
    CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP) AS LOAD_DTS,
    'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
    TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}