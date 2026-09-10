---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('tt_gpd', 'dbo_sy03300') }} as SRC  ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USOHMA.MSSQL.GPPRD.DBO_SY03300' )

/*
SRC_SRC            as ( SELECT * FROM tt_gpd.dbo_sy03300 )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        PYMTRMID                                                     as                                    PAYMENT_TERM_BK
      , PYMTRMID
      , DUETYPE
      , DUEDTDS
      , DISCTYPE
      , DISCDTDS
      , DSCLCTYP
      , DSCDLRAM
      , DSCPCTAM
      , SALPURCH
      , DISCNTCB
      , FREIGHT
      , MISC
      , TAX
      , NOTEINDX
      , CBUVATMD
      , LSTUSRED
      , MODIFDT
      , CREATDDT
      , USEGRPER
      , DEX_ROW_ID
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS)                        as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          PAYMENT_TERM_BK
        , PYMTRMID
        , DUETYPE
        , DUEDTDS
        , DISCTYPE
        , DISCDTDS
        , DSCLCTYP
        , DSCDLRAM
        , DSCPCTAM
        , SALPURCH
        , DISCNTCB
        , FREIGHT
        , MISC
        , TAX
        , NOTEINDX
        , CBUVATMD
        , LSTUSRED
        , MODIFDT
        , CREATDDT
        , USEGRPER
        , DEX_ROW_ID
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PYMTRMID as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PAYMENT_TERM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(DUETYPE::text), '^^') 
            , '||', IFNULL(TRIM(DUEDTDS::text), '^^') 
            , '||', IFNULL(TRIM(DISCTYPE::text), '^^') 
            , '||', IFNULL(TRIM(DISCDTDS::text), '^^') 
            , '||', IFNULL(TRIM(DSCLCTYP::text), '^^') 
            , '||', IFNULL(TRIM(DSCDLRAM::text), '^^') 
            , '||', IFNULL(TRIM(DSCPCTAM::text), '^^') 
            , '||', IFNULL(TRIM(SALPURCH::text), '^^') 
            , '||', IFNULL(TRIM(DISCNTCB::text), '^^') 
            , '||', IFNULL(TRIM(FREIGHT::text), '^^') 
            , '||', IFNULL(TRIM(MISC::text), '^^') 
            , '||', IFNULL(TRIM(TAX::text), '^^') 
            , '||', IFNULL(TRIM(NOTEINDX::text), '^^') 
            , '||', IFNULL(TRIM(CBUVATMD::text), '^^') 
            , '||', IFNULL(TRIM(LSTUSRED::text), '^^') 
            , '||', IFNULL(TRIM(MODIFDT::text), '^^') 
            , '||', IFNULL(TRIM(CREATDDT::text), '^^') 
            , '||', IFNULL(TRIM(USEGRPER::text), '^^') 
            , '||', IFNULL(TRIM(DEX_ROW_ID::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
