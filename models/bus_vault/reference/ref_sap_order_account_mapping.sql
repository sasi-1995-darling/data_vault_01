---- SRC LAYER ----
WITH
SRC_gl          as ( SELECT * FROM {{ ref('v_psa_stg_gl__winn_sap') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY MANDT, KAPPL, KSCHL, KTOPL, VKORG, VTWEG, KVSL1
                                  , KVSL1, ZZPSTYV, ZZAUGRU, ZZAUART ORDER BY LOAD_DTS ))=1 )

/*
SRC_gl             as ( SELECT * FROM None.v_psa_stg_general_ledger_account )
*/
---- LOGIC LAYER ----

, LOGIC_gl as (
    SELECT
        GL_SO_BK
      , LOAD_DTS
      , MANDT
      , KAPPL
      , KSCHL
      , KTOPL
      , VKORG
      , VTWEG
      , KVSL1
      , ZZPSTYV
      , ZZAUGRU
      , ZZAUART
      , ZZKUNAG
      , MATNR
      , GLREQUEST
      , SAKN1
      , SAKN2
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , REC_SRC
      , BKCC
    FROM SRC_gl
)
---- RENAME LAYER ----

, RENAME_gl as (
    SELECT
        GL_SO_BK
      , LOAD_DTS
      ,  MANDT
      ,  KAPPL
      ,  KSCHL
      ,  KTOPL
      ,  VKORG
      ,  VTWEG
      ,  KVSL1
      ,  ZZPSTYV
      ,  ZZAUGRU
      ,  ZZAUART
      ,  ZZKUNAG
      ,  MATNR
      ,  GLREQUEST
      ,  SAKN1
      ,  SAKN2
      ,  GLDELFLAG
      ,  GLCHANGETIME
      ,  GLSOURCESYSTEM
      ,  PSA_DELETE_IND
      ,  PSA_LOAD_DTS
      ,  REC_SRC
      ,  BKCC
    FROM LOGIC_gl
)
---- FILTER LAYER ----

, FILTER_gl as (
    SELECT *
    FROM RENAME_gl
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_gl
)

---- FINAL LAYER ----
SELECT
          GL_SO_BK
        , LOAD_DTS
        ,  MANDT
        ,  KAPPL
        ,  KSCHL
        ,  KTOPL
        ,  VKORG
        ,  VTWEG
        ,  KVSL1
        ,  ZZPSTYV
        ,  ZZAUGRU
        ,  ZZAUART
        ,  ZZKUNAG
        ,  MATNR
        ,  GLREQUEST
        ,  SAKN1
        ,  SAKN2
        ,  GLDELFLAG
        ,  GLCHANGETIME
        ,  GLSOURCESYSTEM
        ,  PSA_DELETE_IND
        ,  PSA_LOAD_DTS
        ,  REC_SRC
        ,  BKCC
FROM JOIN_RESULT
