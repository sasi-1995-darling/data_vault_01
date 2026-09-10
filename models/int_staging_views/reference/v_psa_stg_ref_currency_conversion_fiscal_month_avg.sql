---- SRC LAYER ----
WITH
SRC_crncy          as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_tcurr') }} as SRC  ),
SRC_fscl_dt        as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zbwfiscalpr') }} as SRC 
                        qualify 1= row_number() over (partition by fp_fiscal_month, fp_date, glsourcesystem order by psa_load_dts desc) ),
SRC_fscl_mnth      as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zbwfiscalpr') }} as SRC 
                        qualify 1= row_number() over (partition by fp_fiscal_month, fp_date, glsourcesystem order by psa_load_dts desc) )

/*
SRC_crncy          as ( SELECT * FROM sap_ecc_prd.z_tcurr )
, SRC_fscl_dt        as ( SELECT * FROM sap_ecc_prd.z_zbwfiscalpr )
, SRC_fscl_mnth      as ( SELECT * FROM sap_ecc_prd.z_zbwfiscalpr )
*/
---- LOGIC LAYER ----

, LOGIC_crncy as (
    SELECT
        KURST
      , FCURR
      , TCURR
      , FFACT
      , TFACT
      , MANDT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
      , TO_DATE((99999999-GDATU)::INTEGER::STRING, 'YYYYMMDD')       as                                           GDATE_DT
      , UKURS
    FROM SRC_crncy
)

, LOGIC_fscl_dt as (
    SELECT
        FP_FISCAL_MONTH
      , TO_DATE(FP_DATE, 'DD-MON-YY')                                as                                 FSCL_DT_FP_DATE_DT
      , GLDELFLAG                                                    as                                  fscl_dt_GLDELFLAG
    FROM SRC_fscl_dt
)

, LOGIC_fscl_mnth as (
    SELECT
        TO_DATE(FP_DATE, 'DD-MON-YY')                                as                                         FP_DATE_DT
      , FP_FISCAL_MONTH                                              as                          FSCL_MNTH_FP_FISCAL_MONTH
      , GLDELFLAG
    FROM SRC_fscl_mnth
)
---- RENAME LAYER ----

, RENAME_fscl_dt as (
    SELECT
        FP_FISCAL_MONTH
      , FSCL_DT_FP_DATE_DT
      , fscl_dt_GLDELFLAG
    FROM LOGIC_fscl_dt
)

, RENAME_fscl_mnth as (
    SELECT
        FP_DATE_DT
      , FSCL_MNTH_FP_FISCAL_MONTH
      , GLDELFLAG
    FROM LOGIC_fscl_mnth
)

, RENAME_crncy as (
    SELECT
        KURST
      , FCURR
      , TCURR
      , FFACT
      , TFACT
      , MANDT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
      , GDATE_DT
      , UKURS
    FROM LOGIC_crncy
)
---- FILTER LAYER ----

, FILTER_crncy as (
    SELECT *
    FROM RENAME_crncy
    WHERE KURST = 'M' AND TCURR = 'USD'
)

, FILTER_fscl_dt as (
    SELECT *
    FROM RENAME_fscl_dt
    WHERE fscl_dt_GLDELFLAG <> 'D'
)

, FILTER_fscl_mnth as (
    SELECT *
    FROM RENAME_fscl_mnth
    WHERE GLDELFLAG <> 'D'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_crncy
    INNER JOIN FILTER_fscl_dt
        ON FILTER_crncy.gdate_dt = fscl_dt_fp_date_dt and kurst = 'M'
    INNER JOIN FILTER_fscl_mnth
        ON FILTER_fscl_dt.fp_fiscal_month = fscl_mnth_fp_fiscal_month
)

---- FINAL LAYER ----
SELECT Distinct
          FP_FISCAL_MONTH
        , FP_DATE_DT
        , KURST
        , FCURR
        , TCURR
        , AVG(UKURS) OVER(PARTITION BY FP_FISCAL_MONTH, FCURR, TCURR ) as FISCAL_MONTH_AVG_UKURS
        , FFACT
        , TFACT
        , MANDT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(FP_FISCAL_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(FP_DATE_DT::text), '^^') 
            , '||', IFNULL(TRIM(FISCAL_MONTH_AVG_UKURS::text), '^^') 
            , '||', IFNULL(TRIM(FFACT::text), '^^') 
            , '||', IFNULL(TRIM(TFACT::text), '^^') 
            , '||', IFNULL(TRIM(MANDT::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
/* Add Distinct clause in Final layer Select Clause */
-- group by all