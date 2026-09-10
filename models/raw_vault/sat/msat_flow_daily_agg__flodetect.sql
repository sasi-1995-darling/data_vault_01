{{
  config(
    unique_key=['device_hk', 'device_rollup_surrogate_id', 'load_dts'],
    
    tags = ['materialization_override', 'large_volume', 'msat']
    
  ) 
}}
---- SRC LAYER ----
WITH
SRC_FE             as ( SELECT * FROM {{ ref('v_psa_stg_flow_event_daily') }} as SRC 
                         {% if is_incremental() %}
                            WHERE GREATEST(
                                    COALESCE(SRC.PSA_UPDATED_AT_DTS, SRC.PSA_LOAD_DTS),
                                    SRC.PSA_LOAD_DTS
                                ) >= DATEADD(
                                        day,
                                        -3,
                                        COALESCE(
                                            (
                                                SELECT MAX(
                                                    GREATEST(
                                                        COALESCE(TGT.PSA_UPDATED_AT_DTS, TGT.PSA_LOAD_DTS),
                                                        TGT.PSA_LOAD_DTS
                                                    )
                                                )
                                                FROM {{ this }} AS TGT
                                            ),
                                            '1900-01-01'::TIMESTAMP_NTZ
                                        )
                                    )
                            {% endif %}  
                        )

/*
SRC_FE             as ( SELECT * FROM staging.v_psa_stg_flow_event_daily )
*/
---- LOGIC LAYER ----

, LOGIC_FE as (
    SELECT
        DEVICE_HK
      , LOAD_DTS
      , DEVICE_ROLLUP_SURROGATE_ID
      , CREATED_AT
      , MONTH_CREATED
      , YEAR_CREATED
      , START_TIMESTAMP
      , END_TIMESTAMP
      , EVENT_COUNT
      , TOTAL_RECORDS
      , TOTAL_DURATION
      , MAX_FLOW_RATE
      , AVG_FLOW_RATE
      , TOTAL_GALLONS
      , MIN_PRESSURE
      , AVG_PRESSURE
      , MAX_PRESSURE
      , FIRST_EVENT_TIMESTAMP
      , LAST_EVENT_TIMESTAMP
      , UNIQUE_EVENT_COUNT
      , LOAD_TIMESTAMP
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PSA_UPDATED_AT_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_FE
)
---- RENAME LAYER ----

, RENAME_FE as (
    SELECT
        DEVICE_HK
      , LOAD_DTS
      , DEVICE_ROLLUP_SURROGATE_ID
      , CREATED_AT
      , MONTH_CREATED
      , YEAR_CREATED
      , START_TIMESTAMP
      , END_TIMESTAMP
      , EVENT_COUNT
      , TOTAL_RECORDS
      , TOTAL_DURATION
      , MAX_FLOW_RATE
      , AVG_FLOW_RATE
      , TOTAL_GALLONS
      , MIN_PRESSURE
      , AVG_PRESSURE
      , MAX_PRESSURE
      , FIRST_EVENT_TIMESTAMP
      , LAST_EVENT_TIMESTAMP
      , UNIQUE_EVENT_COUNT
      , LOAD_TIMESTAMP
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PSA_UPDATED_AT_DTS
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_FE
)
---- FILTER LAYER ----

, FILTER_FE as (
    SELECT *
    FROM RENAME_FE
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_FE
)

---- FINAL LAYER ----
SELECT
          DEVICE_HK
        , LOAD_DTS
        , DEVICE_ROLLUP_SURROGATE_ID
        , CREATED_AT
        , MONTH_CREATED
        , YEAR_CREATED
        , START_TIMESTAMP
        , END_TIMESTAMP
        , EVENT_COUNT
        , TOTAL_RECORDS
        , TOTAL_DURATION
        , MAX_FLOW_RATE
        , AVG_FLOW_RATE
        , TOTAL_GALLONS
        , MIN_PRESSURE
        , AVG_PRESSURE
        , MAX_PRESSURE
        , FIRST_EVENT_TIMESTAMP
        , LAST_EVENT_TIMESTAMP
        , UNIQUE_EVENT_COUNT
        , LOAD_TIMESTAMP
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , PSA_UPDATED_AT_DTS
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
/*
No incremental logic or qualify statements for this msat due to materialization_override.
This is to match the except in PSA for flodetect_events_device_daily_agg_v
*/
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS DEVICE_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as DEVICE_ROLLUP_SURROGATE_ID
,'1900-01-01' as CREATED_AT
,null as MONTH_CREATED
,null as YEAR_CREATED
,null as START_TIMESTAMP
,null as END_TIMESTAMP
,null as EVENT_COUNT
,null as TOTAL_RECORDS
,null as TOTAL_DURATION
,null as MAX_FLOW_RATE
,null as AVG_FLOW_RATE
,null as TOTAL_GALLONS
,null as MIN_PRESSURE
,null as AVG_PRESSURE
,null as MAX_PRESSURE
,null as FIRST_EVENT_TIMESTAMP
,null as LAST_EVENT_TIMESTAMP
,null as UNIQUE_EVENT_COUNT
,null as LOAD_TIMESTAMP
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
,null as PSA_UPDATED_AT_DTS
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}