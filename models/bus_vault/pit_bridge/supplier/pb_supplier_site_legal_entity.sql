---- SRC LAYER ----
WITH
SRC_HSUPP          as ( SELECT SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('hub_supplier_v2') }} as SRC  ),
SRC_MDM_HUB_LKUP   as ( SELECT BKCC, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('hub_supplier_v2') }} as SRC 
                        /* This SRC Filter to include only the MDM records to get the equivalent MDM Supplier HK */
                        WHERE BKCC = 'Laying_Goose' ),
SRC_LSAS           as ( SELECT SAME_AS_SUPPLIER_HK, SUPPLIER_HK FROM {{ ref('lnk_same_as_supplier') }} as SRC 
                        /* The Following Qualify clause is required to handle the prevailing issue with MDM where Supplier_hk(source) is tied to Two Different Same As Supplier(Golden Record) */
                        
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_L              as ( SELECT LEGAL_ENTITY_HK, SUPPLIER_HK, SUPPLIER_SITE_HK, SUPPLIER_SITE_LEGAL_ENTITY_HK FROM {{ ref('lnk_supplier_site_legal_entity') }} as SRC 
                        /* The Following Qualify clause is required to handle the prevailing issue with MDM where Supplier_hk(source) is tied to Two Different Same As Supplier(Golden Record) */
                        
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_H              as ( SELECT BKCC, REC_SRC, SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('hub_supplier_site_v2') }} as SRC  ),
SRC_HL             as ( SELECT LEGAL_ENTITY_BK, LEGAL_ENTITY_HK FROM {{ ref('hub_legal_entity') }} as SRC  ),
SRC_SAT_MDM        as ( SELECT LAST_RUN_DATE, ORGANIZATION_ID, PSA_DELETE_IND, SUPPLIER_SITE_LEGAL_ENTITY_HK FROM {{ ref('lsat_supplier_site_legal_entity__mdm') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_SITE_LEGAL_ENTITY_HK ORDER BY LOAD_DTS DESC))=1 )

/*
SRC_HSUPP          as ( SELECT * FROM RAW_VAULT.hub_supplier_v2 )
SRC_MDM_HUB_LKUP   as ( SELECT * FROM RAW_VAULT.hub_supplier_v2 )
SRC_LSAS           as ( SELECT * FROM RAW_VAULT.lnk_same_as_supplier )
SRC_L              as ( SELECT * FROM RAW_VAULT.lnk_supplier_site_legal_entity )
SRC_H              as ( SELECT * FROM RAW_VAULT.hub_supplier_site_v2 )
SRC_HL             as ( SELECT * FROM RAW_VAULT.hub_legal_entity )
SRC_SAT_MDM        as ( SELECT * FROM RAW_VAULT.lsat_supplier_site_legal_entity__mdm )
*/
---- LOGIC LAYER ----

, LOGIC_HSUPP as (
    SELECT
        SUPPLIER_BK
      , SUPPLIER_HK                                                  as                                  HSUPP_SUPPLIER_HK
    FROM SRC_HSUPP
)

, LOGIC_MDM_HUB_LKUP as (
    SELECT
        SUPPLIER_BK                                                  as                                    MDM_SUPPLIER_BK
      , REC_SRC                                                      as                                        MDM_REC_SRC
      , BKCC                                                         as                                           MDM_BKCC
      , SUPPLIER_HK                                                  as                           MDM_HUB_LKUP_SUPPLIER_HK
    FROM SRC_MDM_HUB_LKUP
)

, LOGIC_LSAS as (
    SELECT
        SUPPLIER_HK                                                  as                                   LSAS_SUPPLIER_HK
      , SAME_AS_SUPPLIER_HK                                          as                           LSAS_SAME_AS_SUPPLIER_HK
    FROM SRC_LSAS
)

, LOGIC_L as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_LEGAL_ENTITY_HK
      , LEGAL_ENTITY_HK
      , SUPPLIER_HK                                                  as                                    LNK_SUPPLIER_HK
    FROM SRC_L
)

, LOGIC_H as (
    SELECT
        SUPPLIER_SITE_BK                                             as                               MDM_SUPPLIER_SITE_BK
      , REC_SRC
      , BKCC
      , SUPPLIER_SITE_HK                                             as                               HUB_SUPPLIER_SITE_HK
    FROM SRC_H
)

, LOGIC_HL as (
    SELECT
        LEGAL_ENTITY_HK                                              as                                HUB_LEGAL_ENTITY_HK
      , LEGAL_ENTITY_BK                                              as                                MDM_LEGAL_ENTITY_BK
    FROM SRC_HL
)

, LOGIC_SAT_MDM as (
    SELECT
        ORGANIZATION_ID                                              as                              MDM_LEGAL_ENTITY_CODE
      , LAST_RUN_DATE                                                as                 MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD
      , PSA_DELETE_IND                                               as                                     MDM_IS_DELETED
      , SUPPLIER_SITE_LEGAL_ENTITY_HK                                as              SAT_MDM_SUPPLIER_SITE_LEGAL_ENTITY_HK
    FROM SRC_SAT_MDM
)
---- RENAME LAYER ----

, RENAME_HSUPP as (
    SELECT
        SUPPLIER_BK
      , HSUPP_SUPPLIER_HK
    FROM LOGIC_HSUPP
)

, RENAME_MDM_HUB_LKUP as (
    SELECT
        MDM_SUPPLIER_BK
      , MDM_REC_SRC
      , MDM_BKCC
      , MDM_HUB_LKUP_SUPPLIER_HK
    FROM LOGIC_MDM_HUB_LKUP
)

, RENAME_H as (
    SELECT
        MDM_SUPPLIER_SITE_BK
      , REC_SRC
      , BKCC
      , HUB_SUPPLIER_SITE_HK
    FROM LOGIC_H
)

, RENAME_HL as (
    SELECT
        HUB_LEGAL_ENTITY_HK
      , MDM_LEGAL_ENTITY_BK
    FROM LOGIC_HL
)

, RENAME_SAT_MDM as (
    SELECT
        MDM_LEGAL_ENTITY_CODE
      , MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD
      , MDM_IS_DELETED
      , SAT_MDM_SUPPLIER_SITE_LEGAL_ENTITY_HK
    FROM LOGIC_SAT_MDM
)

, RENAME_L as (
    SELECT
        SUPPLIER_SITE_HK
      , SUPPLIER_HK
      , SUPPLIER_SITE_LEGAL_ENTITY_HK
      , LEGAL_ENTITY_HK
      , LNK_SUPPLIER_HK
    FROM LOGIC_L
)

, RENAME_LSAS as (
    SELECT
        LSAS_SUPPLIER_HK
      , LSAS_SAME_AS_SUPPLIER_HK
    FROM LOGIC_LSAS
)
---- FILTER LAYER ----

, FILTER_HSUPP as (
    SELECT *
    FROM RENAME_HSUPP
)

, FILTER_MDM_HUB_LKUP as (
    SELECT *
    FROM RENAME_MDM_HUB_LKUP
)

, FILTER_LSAS as (
    SELECT *
    FROM RENAME_LSAS
)

, FILTER_L as (
    SELECT *
    FROM RENAME_L
)

, FILTER_H as (
    SELECT *
    FROM RENAME_H
)

, FILTER_HL as (
    SELECT *
    FROM RENAME_HL
)

, FILTER_SAT_MDM as (
    SELECT *
    FROM RENAME_SAT_MDM
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HSUPP
    INNER JOIN FILTER_LSAS
        ON HSUPP_SUPPLIER_HK = LSAS_SUPPLIER_HK
/* The Lnk is not being used as Driver due to the fact that the Lnk has only subset of MDM data, but the intent of this PB is to have all the Supplier Source data*/

    INNER JOIN FILTER_L
        ON LNK_SUPPLIER_HK = LSAS_SAME_AS_SUPPLIER_HK
    INNER JOIN FILTER_H
        ON FILTER_L.SUPPLIER_SITE_HK = HUB_SUPPLIER_SITE_HK
    INNER JOIN FILTER_HL
        ON FILTER_L.LEGAL_ENTITY_HK = HUB_LEGAL_ENTITY_HK
    LEFT JOIN FILTER_SAT_MDM
        ON FILTER_L.SUPPLIER_SITE_LEGAL_ENTITY_HK = SAT_MDM_SUPPLIER_SITE_LEGAL_ENTITY_HK
    INNER JOIN FILTER_MDM_HUB_LKUP
        ON LSAS_SAME_AS_SUPPLIER_HK = MDM_HUB_LKUP_SUPPLIER_HK
)

---- FINAL LAYER ----
SELECT
          ROW_NUMBER() OVER(ORDER BY 1)                                as SEQ_ID
        , CURRENT_TIMESTAMP                                            as SNAPSHOTDATE
        ,  md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(MDM_SUPPLIER_BK)), ''), '^^')
            , coalesce(nullif(upper(trim(MDM_SUPPLIER_SITE_BK)), ''), '^^')        
             , coalesce(nullif(upper(trim(supplier_bk)), ''), '^^')  
              , coalesce(nullif(upper(trim(MDM_LEGAL_ENTITY_CODE)), ''), '^^')  )
            , '^^||^^')) as SUPPLIER_SITE_LEGAL_ENTITY_KEY
        , LNK_SUPPLIER_HK                                              as SUPPLIER_HK
        , SUPPLIER_BK
        , MDM_SUPPLIER_BK
        , MDM_SUPPLIER_SITE_BK
        , HUB_LEGAL_ENTITY_HK
        , MDM_LEGAL_ENTITY_BK
        , iff(LSAS_SAME_AS_SUPPLIER_HK IS NULL, 'N', 'Y')              as MDM_GOLDEN_RECORD
        , MDM_LEGAL_ENTITY_CODE
        , TO_CHAR(MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD, 'YYYYMMDD')::INTEGER          as MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD
        , MDM_IS_DELETED
        , REC_SRC
        , BKCC
        , MDM_REC_SRC
        , MDM_BKCC
        , SUPPLIER_SITE_HK
        , LEGAL_ENTITY_HK
FROM JOIN_RESULT
