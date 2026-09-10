---- SRC LAYER ----
WITH
SRC_a              as ( SELECT CLASS, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, IDALT, IDFEAT, IDFEAV, IDFHM, IDMST, IDOPR, IDPHAS, IDSEQ, IDSUB, LINESIZE, MANDT, OBJALT, OBJFEAT, OBJFEAV, OBJFHM, OBJMST, OBJOPR, OBJPHAS, OBJSEQ, OBJSUB, PLNAW, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE FROM {{ source('sap_ecc_prd', 'z_tca09') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_tca09 )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        MANDT
      , PLNAW
      , GLREQUEST
      , OBJSUB
      , IDSUB
      , OBJALT
      , IDALT
      , OBJSEQ
      , IDSEQ
      , OBJOPR
      , IDOPR
      , OBJFHM
      , IDFHM
      , CLASS
      , LINESIZE
      , OBJPHAS
      , IDPHAS
      , OBJFEAT
      , IDFEAT
      , OBJMST
      , IDMST
      , OBJFEAV
      , IDFEAV
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            )
        ))                                                           as                                           LOAD_DTS
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
        MANDT
      , PLNAW
      , GLREQUEST
      , OBJSUB
      , IDSUB
      , OBJALT
      , IDALT
      , OBJSEQ
      , IDSEQ
      , OBJOPR
      , IDOPR
      , OBJFHM
      , IDFHM
      , CLASS
      , LINESIZE
      , OBJPHAS
      , IDPHAS
      , OBJFEAT
      , IDFEAT
      , OBJMST
      , IDMST
      , OBJFEAV
      , IDFEAV
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , LOAD_DTS
    FROM LOGIC_a
)

, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_TCA09'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          MANDT
        , PLNAW
        , GLREQUEST
        , OBJSUB
        , IDSUB
        , OBJALT
        , IDALT
        , OBJSEQ
        , IDSEQ
        , OBJOPR
        , IDOPR
        , OBJFHM
        , IDFHM
        , CLASS
        , LINESIZE
        , OBJPHAS
        , IDPHAS
        , OBJFEAT
        , IDFEAT
        , OBJMST
        , IDMST
        , OBJFEAV
        , IDFEAV
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
FROM JOIN_RESULT