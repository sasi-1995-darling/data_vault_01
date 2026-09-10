---- SRC LAYER ----
WITH
SRC_s              as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'posetup') }} as SRC 
                          UNPIVOT (code_value FOR code_type IN (ENT_CODE, REL_CODE, RECV_CODE,INV_CODE,HOLD_CODE,CLOSE_CODE,CAN_CODE))
                          UNPIVOT (num_value FOR num_type IN (ENT_NUM, REL_NUM, RECV_NUM,INV_NUM,HOLD_NUM,CLOSE_NUM,CAN_NUM)) )

/*
SRC_s              as ( SELECT * FROM tt_e21prd_e21trubis.posetup )
*/
---- LOGIC LAYER ----

, LOGIC_s as (
    SELECT
        _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CODE_TYPE                                                    as                                PO_STATUS_CODE_TYPE
      , NUM_TYPE                                                     as                                 PO_STATUS_NUM_TYPE
      , CODE_VALUE                                                   as                               PO_STATUS_CODE_VALUE
      , NUM_VALUE                                                    as                                PO_STATUS_NUM_VALUE
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_s
)
---- RENAME LAYER ----

, RENAME_s as (
    SELECT
        _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PO_STATUS_CODE_TYPE
      , PO_STATUS_NUM_TYPE
      , PO_STATUS_CODE_VALUE
      , PO_STATUS_NUM_VALUE
      , LOAD_DTS
    FROM LOGIC_s
)
---- FILTER LAYER ----

, FILTER_s as (
    SELECT *
    FROM RENAME_s
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_s
)

---- FINAL LAYER ----
SELECT
          _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , PO_STATUS_CODE_TYPE
        , PO_STATUS_CODE_VALUE
        , PO_STATUS_NUM_VALUE
        , LOAD_DTS
FROM JOIN_RESULT
WHERE PO_STATUS_CODE_TYPE = REPLACE(PO_STATUS_NUM_TYPE, '_NUM', '_CODE')