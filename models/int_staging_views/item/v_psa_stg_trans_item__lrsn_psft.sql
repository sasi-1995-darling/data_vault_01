---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'psxlatitem') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by  FIELDNAME,FIELDVALUE, EFFDT, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.psxlatitem )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        FIELDNAME
      , FIELDVALUE
      , EFFDT
      , EFF_STATUS
      , XLATLONGNAME
      , XLATSHORTNAME
      , LASTUPDDTTM
      , LASTUPDOPRID
      , SYNCID
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
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
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        FIELDNAME
      , FIELDVALUE
      , EFFDT
      , EFF_STATUS
      , XLATLONGNAME
      , XLATSHORTNAME
      , LASTUPDDTTM
      , LASTUPDOPRID
      , SYNCID
      , _FIVETRAN_DELETED
      , _FIVETRAN_ID
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
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PSXLATITEM'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          CONCAT (FIELDNAME, '||',FIELDVALUE, '||',EFFDT)              as TRANS_ITEM_BK
        , FIELDNAME
        , FIELDVALUE
        , EFFDT
        , EFF_STATUS
        , XLATLONGNAME
        , XLATSHORTNAME
        , LASTUPDDTTM
        , LASTUPDOPRID
        , SYNCID
        , _FIVETRAN_DELETED
        , _FIVETRAN_ID
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(EFF_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(XLATLONGNAME::text), '^^') 
            , '||', IFNULL(TRIM(XLATSHORTNAME::text), '^^') 
            , '||', IFNULL(TRIM(LASTUPDDTTM::text), '^^') 
            , '||', IFNULL(TRIM(LASTUPDOPRID::text), '^^') 
            , '||', IFNULL(TRIM(SYNCID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
