---- SRC LAYER ----
WITH
SRC_hub_dist       as ( SELECT BKCC, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_HK, REC_SRC FROM {{ ref('hub_distribution_channel') }} as SRC  ),
SRC_sat_dist       as ( SELECT SPRAS, VTEXT, VTWEG, PSA_DELETE_IND, DISTRIBUTION_CHANNEL_HK FROM {{ ref('sat_distribution_channel__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by DISTRIBUTION_CHANNEL_HK,SPRAS order by load_dts DESC) )

/*
SRC_hub_dist       as ( SELECT * FROM RAW_VAULT.hub_distribution_channel )
SRC_sat_dist       as ( SELECT * FROM RAW_VAULT.sat_distribution_channel__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_hub_dist as (
    SELECT
        'PIT_DISTRIBUTION_CHANNEL'                                   as                          PIT_REC_SRC
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                          PIT_LOAD_DTS
      , CURRENT_DATE                                                 as                          SNAPSHOT_DTS
      , DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , REC_SRC
      , BKCC
    FROM SRC_hub_dist
)

, LOGIC_sat_dist as (
    SELECT
        DISTRIBUTION_CHANNEL_HK                                      as                          sat_dist_DISTRIBUTION_CHANNEL_HK
      , SPRAS                                                        as                                       LANGUAGE_KEY
      , VTWEG                                                        as                           DISTRIBUTION_CHANNEL_CODE
      , VTEXT                                                        as                          DISTRIBUTION_CHANNEL_NAME
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_sat_dist
)
---- RENAME LAYER ----

, RENAME_hub_dist as (
    SELECT
        PIT_REC_SRC
      , PIT_LOAD_DTS
      , SNAPSHOT_DTS
      , DISTRIBUTION_CHANNEL_HK
      , DISTRIBUTION_CHANNEL_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_hub_dist
)

, RENAME_sat_dist as (
    SELECT
        sat_dist_DISTRIBUTION_CHANNEL_HK
      , LANGUAGE_KEY
      , DISTRIBUTION_CHANNEL_CODE
      , DISTRIBUTION_CHANNEL_NAME
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_sat_dist
)
---- FILTER LAYER ----

, FILTER_hub_dist as (
    SELECT *
    FROM RENAME_hub_dist
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
)

, FILTER_sat_dist as (
    SELECT *
    FROM RENAME_sat_dist
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_hub_dist
    INNER JOIN FILTER_sat_dist
        ON FILTER_hub_dist.DISTRIBUTION_CHANNEL_HK = sat_dist_DISTRIBUTION_CHANNEL_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , PIT_LOAD_DTS
        , SNAPSHOT_DTS
        , DISTRIBUTION_CHANNEL_HK
        , DISTRIBUTION_CHANNEL_BK
        , REC_SRC
        , BKCC
        , LANGUAGE_KEY
        , DISTRIBUTION_CHANNEL_CODE
        , DISTRIBUTION_CHANNEL_NAME
        , CASE  WHEN BKCC = 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
           END as IS_DELETED 
FROM JOIN_RESULT
