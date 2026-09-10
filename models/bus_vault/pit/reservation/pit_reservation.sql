---- SRC LAYER ----
WITH
SRC_HR             as ( SELECT BKCC, RESERVATION_BK, RESERVATION_HK, REC_SRC FROM {{ ref('hub_reservation') }} as SRC  ),
SRC_SR             as ( SELECT BWART, PSA_DELETE_IND, RESERVATION_HK, RSNUM, USNAM FROM {{ ref('sat_reservation__winn_sap') }} as SRC 
                        qualify 1= row_number() over(partition by RESERVATION_HK order by LOAD_DTS DESC) )

/*
SRC_HR             as ( SELECT * FROM RAW_VAULT.HUB_RESERVATION )
SRC_SR             as ( SELECT * FROM RAW_VAULT.SAT_RESERVATION__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_HR as (
    SELECT
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , BKCC
      , 'PIT_RESERVATION'                                            as                                       PIT_REC_SRC
      , RESERVATION_BK
      , RESERVATION_HK
      , REC_SRC
    FROM SRC_HR
)

, LOGIC_SR as (
    SELECT
        RESERVATION_HK                                               as                                  SR_RESERVATION_HK
      , RSNUM                                                        as                                     RESERVATION_ID
      , BWART                                                        as                                 MOVEMENT_TYPE_CODE
      , USNAM                                                        as                               RESERVATION_CREATION
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SR
)
---- RENAME LAYER ----

, RENAME_HR as (
    SELECT
        PIT_LOAD_DTS
      , BKCC
      , PIT_REC_SRC
      , RESERVATION_BK
      , RESERVATION_HK
      , REC_SRC
    FROM LOGIC_HR
)

, RENAME_SR as (
    SELECT
        SR_RESERVATION_HK
      , RESERVATION_ID
      , MOVEMENT_TYPE_CODE
      , RESERVATION_CREATION
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SR
)
---- FILTER LAYER ----

, FILTER_HR as (
    SELECT *
    FROM RENAME_HR
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

, FILTER_SR as (
    SELECT *
    FROM RENAME_SR
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HR
    INNER JOIN FILTER_SR
        ON FILTER_HR.RESERVATION_HK = FILTER_SR.SR_RESERVATION_HK
)

---- FINAL LAYER ----
SELECT
          row_number() over(order by 1)                                as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , PIT_LOAD_DTS
        , BKCC
        , PIT_REC_SRC
        , RESERVATION_BK
        , RESERVATION_HK
        , RESERVATION_ID
        , MOVEMENT_TYPE_CODE
        , RESERVATION_CREATION
        , REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN SAT_WINN_PSA_DELETE_IND
    END as IS_DELETED
FROM JOIN_RESULT