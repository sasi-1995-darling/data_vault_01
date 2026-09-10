---- SRC LAYER ----
WITH
SRC_H              as ( SELECT BKCC, LEGAL_ENTITY_BK, LEGAL_ENTITY_HK, REC_SRC FROM {{ ref('hub_legal_entity') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT BUKRS, BUTXT, LAND1, LEGAL_ENTITY_HK, LOAD_DTS, ORT01, PSA_DELETE_IND, SPRAS, WAERS FROM {{ ref('sat_legal_entity__winn_sap') }} as SRC 
                        /* The below Decode in order by clause is to pick the most applicable Language for a given Legal Entity */
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY DECODE(SPRAS, 'E', 1, '1', 2, 10), LOAD_DTS DESC) ),
SRC_SAT_EBS        as ( SELECT ATTRIBUTE6, LEGAL_ENTITY_HK, NAME, ORGANIZATION_ID, _FIVETRAN_DELETED FROM {{ ref('sat_legal_entity__ml_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_LRSN       as ( SELECT BUSINESS_UNIT, DESCR, LEGAL_ENTITY_HK, _FIVETRAN_DELETED FROM {{ ref('sat_legal_entity__lrsn_psft') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_EMTK       as ( SELECT LEGAL_ENTITY_HK, NAME, ORGANIZATION_ID, _FIVETRAN_DELETED FROM {{ ref('sat_legal_entity__emtk_ebs') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_TTGP       as ( SELECT CMPANYID, CMPNYNAM FROM {{ ref('sat_po_header__tt_gp') }} as SRC 
                        /*This filter is utilized to select the valid company ID from the latest PO Header data, as there is no Master table for Legal Entity in TT-GP. */
                        WHERE  CMPANYID != 0  AND POTYPE = 1
                        QUALIFY 1 = ROW_NUMBER() OVER (PARTITION BY CMPANYID ORDER BY PSA_LOAD_DTS DESC, DEX_ROW_ID DESC) ),
SRC_SAT_TTE21      as ( SELECT BUS_NAME, CITY, CNTRY_CODE, COST_CTR, LEGAL_ENTITY_HK, _FIVETRAN_DELETED FROM {{ ref('sat_legal_entity__tt_e21') }} as SRC 
                        QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC) ),
SRC_SAT_FIB        as ( SELECT ATTRIBUTE_CATEGORY, LEGAL_ENTITY_HK, LEGAL_ENTITY_IDENTIFIER, NAME, _FIVETRAN_DELETED FROM {{ ref('sat_legal_entity__fib_ocf') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.hub_legal_entity )
SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.sat_legal_entity__winn_sap )
SRC_SAT_EBS        as ( SELECT * FROM RAW_VAULT.sat_legal_entity__ml_ebs )
SRC_SAT_LRSN       as ( SELECT * FROM RAW_VAULT.sat_legal_entity__lrsn_psft )
SRC_SAT_EMTK       as ( SELECT * FROM RAW_VAULT.sat_legal_entity__emtk_ebs )
SRC_SAT_TTGP       as ( SELECT * FROM RAW_VAULT.sat_po_header__tt_gp )
SRC_SAT_TTE21      as ( SELECT * FROM RAW_VAULT.sat_legal_entity__tt_e21 )
SRC_SAT_FIB        as ( SELECT * FROM RAW_VAULT.sat_legal_entity__fib_ocf )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_LEGAL_ENTITY'                                           as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , REC_SRC
      , BKCC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
    SELECT
        LEGAL_ENTITY_HK                                              as                           SAT_WINN_LEGAL_ENTITY_HK
      , BUKRS
      , BUTXT
      , WAERS
      , ORT01
      , LAND1
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
    FROM SRC_SAT_WINN
)

, LOGIC_SAT_EBS as (
    SELECT
        LEGAL_ENTITY_HK                                              as                            SAT_EBS_LEGAL_ENTITY_HK
      , ORGANIZATION_ID::text                                        as                                    ORGANIZATION_ID
      , NAME
      , ATTRIBUTE6
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                           SAT_EBS_FIVETRAN_DELETED
    FROM SRC_SAT_EBS
)

, LOGIC_SAT_LRSN as (
    SELECT
        LEGAL_ENTITY_HK                                              as                           SAT_LRSN_LEGAL_ENTITY_HK
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                          SAT_LRSN_FIVETRAN_DELETED
      , BUSINESS_UNIT
      , DESCR
    FROM SRC_SAT_LRSN
)

, LOGIC_SAT_EMTK as (
    SELECT
        LEGAL_ENTITY_HK                                              as                           SAT_EMTK_LEGAL_ENTITY_HK
      , ORGANIZATION_ID::text                                        as                           SAT_EMTK_ORGANIZATION_ID
      , NAME                                                         as                                      SAT_EMTK_NAME
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                          SAT_EMTK_FIVETRAN_DELETED
    FROM SRC_SAT_EMTK
)

, LOGIC_SAT_TTGP as (
    SELECT
        CMPANYID
      , CMPANYID::text                                               as                                  SAT_TTGP_CMPANYID
      , CMPNYNAM                                                     as                                  SAT_TTGP_CMPNYNAM
    FROM SRC_SAT_TTGP
)

, LOGIC_SAT_TTE21 as (
    SELECT
        LEGAL_ENTITY_HK                                              as                          SAT_TTE21_LEGAL_ENTITY_HK
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                         SAT_TTE21_FIVETRAN_DELETED
      , COST_CTR
      , BUS_NAME
      , CITY
      , CNTRY_CODE
    FROM SRC_SAT_TTE21
)

, LOGIC_SAT_FIB as (
    SELECT
        LEGAL_ENTITY_HK                                              as                            SAT_FIB_LEGAL_ENTITY_HK
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                           SAT_FIB_FIVETRAN_DELETED
      , LEGAL_ENTITY_IDENTIFIER
      , NAME                                                         as                                           FIB_NAME
      , ATTRIBUTE_CATEGORY
    FROM SRC_SAT_FIB
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK
      , REC_SRC
      , BKCC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        SAT_WINN_LEGAL_ENTITY_HK
      , BUKRS
      , BUTXT
      , WAERS
      , ORT01
      , LAND1
      , SAT_WINN_PSA_DELETE_IND
    FROM LOGIC_SAT_WINN
)

, RENAME_SAT_EBS as (
    SELECT
        SAT_EBS_LEGAL_ENTITY_HK
      , ORGANIZATION_ID
      , NAME
      , ATTRIBUTE6
      , _FIVETRAN_DELETED
      , SAT_EBS_FIVETRAN_DELETED
    FROM LOGIC_SAT_EBS
)

, RENAME_SAT_LRSN as (
    SELECT
        SAT_LRSN_LEGAL_ENTITY_HK
      , _FIVETRAN_DELETED
      , SAT_LRSN_FIVETRAN_DELETED
      , BUSINESS_UNIT
      , DESCR
    FROM LOGIC_SAT_LRSN
)

, RENAME_SAT_EMTK as (
    SELECT
        SAT_EMTK_LEGAL_ENTITY_HK
      , SAT_EMTK_ORGANIZATION_ID
      , SAT_EMTK_NAME
      , _FIVETRAN_DELETED
      , SAT_EMTK_FIVETRAN_DELETED
    FROM LOGIC_SAT_EMTK
)

, RENAME_SAT_TTGP as (
    SELECT
        CMPANYID
      , SAT_TTGP_CMPANYID
      , SAT_TTGP_CMPNYNAM
    FROM LOGIC_SAT_TTGP
)

, RENAME_SAT_TTE21 as (
    SELECT
        SAT_TTE21_LEGAL_ENTITY_HK
      , _FIVETRAN_DELETED
      , SAT_TTE21_FIVETRAN_DELETED
      , COST_CTR
      , BUS_NAME
      , CITY
      , CNTRY_CODE
    FROM LOGIC_SAT_TTE21
)

, RENAME_SAT_FIB as (
    SELECT
        SAT_FIB_LEGAL_ENTITY_HK
      , _FIVETRAN_DELETED
      , SAT_FIB_FIVETRAN_DELETED
      , LEGAL_ENTITY_IDENTIFIER
      , FIB_NAME
      , ATTRIBUTE_CATEGORY
    FROM LOGIC_SAT_FIB
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'  /* This filter is to exclude the ghost records */
and BKCC IN ('Crouching_Dragon','Hiding_Tiger','Swimming_Ocean','Diving_Sea','Kicking_Panda','Jumping_River')
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

, FILTER_SAT_EBS as (
    SELECT *
    FROM RENAME_SAT_EBS
)

, FILTER_SAT_LRSN as (
    SELECT *
    FROM RENAME_SAT_LRSN
)

, FILTER_SAT_EMTK as (
    SELECT *
    FROM RENAME_SAT_EMTK
)

, FILTER_SAT_TTGP as (
    SELECT *
    FROM RENAME_SAT_TTGP
)

, FILTER_SAT_TTE21 as (
    SELECT *
    FROM RENAME_SAT_TTE21
)

, FILTER_SAT_FIB as (
    SELECT *
    FROM RENAME_SAT_FIB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_H.LEGAL_ENTITY_HK = SAT_WINN_LEGAL_ENTITY_HK
    LEFT JOIN FILTER_SAT_EBS
        ON FILTER_H.LEGAL_ENTITY_HK = SAT_EBS_LEGAL_ENTITY_HK
    LEFT JOIN FILTER_SAT_LRSN
        ON FILTER_H.LEGAL_ENTITY_HK = SAT_LRSN_LEGAL_ENTITY_HK
    LEFT JOIN FILTER_SAT_EMTK
        ON FILTER_H.LEGAL_ENTITY_HK = SAT_EMTK_LEGAL_ENTITY_HK
    LEFT JOIN FILTER_SAT_TTGP
        ON FILTER_H.LEGAL_ENTITY_BK = SAT_TTGP_CMPANYID
    LEFT JOIN FILTER_SAT_TTE21
        ON FILTER_H.LEGAL_ENTITY_HK = SAT_TTE21_LEGAL_ENTITY_HK
    LEFT JOIN FILTER_SAT_FIB
        ON FILTER_H.LEGAL_ENTITY_HK = SAT_FIB_LEGAL_ENTITY_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , LEGAL_ENTITY_HK
        , LEGAL_ENTITY_BK
        , COALESCE(BUKRS, ORGANIZATION_ID,BUSINESS_UNIT, SAT_EMTK_ORGANIZATION_ID,SAT_TTGP_CMPANYID, COST_CTR,LEGAL_ENTITY_IDENTIFIER) as LEGAL_ENTITY_CODE
        , COALESCE(BUTXT, NAME,DESCR,SAT_EMTK_NAME,SAT_TTGP_CMPNYNAM,BUS_NAME,FIB_NAME) as LEGAL_ENTITY_NAME
        , COALESCE(ORT01,CITY)                                         as LEGAL_ENTITY_REGION
        , COALESCE(LAND1,CNTRY_CODE,ATTRIBUTE_CATEGORY)                as LEGAL_ENTITY_COUNTRY_CODE
        , COALESCE(WAERS, ATTRIBUTE6)                                  as LEGAL_ENTITY_CURRENCY_CODE
        , CASE WHEN SAT_TTGP_CMPANYID IS NOT NULL 
            THEN 'N'
            ELSE COALESCE(SAT_WINN_PSA_DELETE_IND, SAT_EBS_FIVETRAN_DELETED,SAT_LRSN_FIVETRAN_DELETED,SAT_EMTK_FIVETRAN_DELETED,SAT_TTE21_FIVETRAN_DELETED,SAT_FIB_FIVETRAN_DELETED)
        END as IS_DELETED
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
/* Exclude LEGAL_ENTITY_NAME with NULL or empty names to ensure only valid and named legal entities are included in the PIT table. */
WHERE (NULLIF(LEGAL_ENTITY_NAME,'') IS NOT NULL)
