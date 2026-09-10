---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('lrsn_psft_sysadm', 'ps_l_prod_grp_lu') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by  L_GRP_TYPE, L_GRP_CODE, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_l_prod_grp_lu )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        L_GRP_TYPE
      , L_GRP_CODE
      , SETID
      , DESCR
      , L_DESCR_SP
      , L_DESCR_FR
      , L_DESCR
      , DATETIME_ADDED
      , LASTUPDDTTM
      , LAST_MAINT_OPRID
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
        L_GRP_TYPE
      , L_GRP_CODE
      , SETID
      , DESCR
      , L_DESCR_SP
      , L_DESCR_FR
      , L_DESCR
      , DATETIME_ADDED
      , LASTUPDDTTM
      , LAST_MAINT_OPRID
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
    WHERE rec_src = 'USSDBR.ORCL.PSFTPRD.PS_L_PROD_GRP_LU'
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
          CONCAT (L_GRP_TYPE, '||',L_GRP_CODE)                         as PROD_GRP_BK
        , L_GRP_TYPE
        , L_GRP_CODE
        , SETID
        , DESCR
        , L_DESCR_SP
        , L_DESCR_FR
        , L_DESCR
        , DATETIME_ADDED
        , LASTUPDDTTM
        , LAST_MAINT_OPRID
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
              IFNULL(TRIM(SETID::text), '^^') 
            , '||', IFNULL(TRIM(DESCR::text), '^^') 
            , '||', IFNULL(TRIM(L_DESCR_SP::text), '^^') 
            , '||', IFNULL(TRIM(L_DESCR_FR::text), '^^') 
            , '||', IFNULL(TRIM(L_DESCR::text), '^^') 
            , '||', IFNULL(TRIM(DATETIME_ADDED::text), '^^') 
            , '||', IFNULL(TRIM(LASTUPDDTTM::text), '^^') 
            , '||', IFNULL(TRIM(LAST_MAINT_OPRID::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
