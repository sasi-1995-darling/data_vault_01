---- SRC LAYER ----
WITH
SRC_HSUPP          as ( SELECT BKCC, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('hub_supplier_v2') }} as SRC  ),
SRC_MDM_HUB_LKUP   as ( SELECT BKCC, REC_SRC, SUPPLIER_BK, SUPPLIER_HK FROM {{ ref('hub_supplier_v2') }} as SRC 
                        /* This SRC Filter to include only the MDM records to get the equivalent MDM Supplier HK */
                        WHERE BKCC = 'Laying_Goose' ),
SRC_LSAS           as ( SELECT SAME_AS_SUPPLIER_HK, SUPPLIER_HK FROM {{ ref('lnk_same_as_supplier') }} as SRC 
                        /* The Following Qualify clause is required to handle the prevailing issue with MDM where Supplier_hk(source) is tied to Two Different Same As Supplier(Golden Record) */
                        
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_L              as ( SELECT SUPPLIER_HK, SUPPLIER_SITE_HK FROM {{ ref('lnk_supplier_site') }} as SRC 
                        
                        
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_SITE_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_H              as ( SELECT SUPPLIER_SITE_BK, SUPPLIER_SITE_HK FROM {{ ref('hub_supplier_site_v2') }} as SRC  ),
SRC_SAT_MDM        as ( SELECT ADDRESS_LINE_1, ADDRESS_LINE_2, ADDRESS_TYPE, CITY, COUNTRY, INACTIVE_DATE, LAST_RUN_DATE, POSTAL_CODE, PSA_DELETE_IND, SITE_STATUS, STATE, SUPPLIER_SITE_HK, SUPPLIER_TYPE, TAX_NUMBER FROM {{ ref('sat_supplier_site__mdm') }} as SRC 
                        QUALIFY (ROW_NUMBER() OVER(PARTITION BY SUPPLIER_SITE_HK ORDER BY LOAD_DTS DESC))=1 ),
SRC_SATP_MDM       as ( SELECT FAX_NUMBER, LAST_RUN_DATE, PHONE_NUMBER, SUPPLIER_SITE_HK FROM {{ ref('stg_pb_supplier_sites_phone') }} as SRC  ),
SRC_SATE_MDM       as ( SELECT EMAIL_ADDRESS, LAST_RUN_DATE, SUPPLIER_SITE_HK FROM {{ ref('stg_pb_supplier_sites_email') }} as SRC  )

/*
SRC_HSUPP          as ( SELECT * FROM RAW_VAULT.hub_supplier_v2 )
SRC_MDM_HUB_LKUP   as ( SELECT * FROM RAW_VAULT.hub_supplier_v2 )
SRC_LSAS           as ( SELECT * FROM RAW_VAULT.lnk_same_as_supplier )
SRC_L              as ( SELECT * FROM RAW_VAULT.lnk_supplier_site )
SRC_H              as ( SELECT * FROM RAW_VAULT.hub_supplier_site_v2 )
SRC_SAT_MDM        as ( SELECT * FROM RAW_VAULT.sat_supplier_site__mdm )
SRC_SATP_MDM       as ( SELECT * FROM BUS_VAULT.stg_pb_supplier_sites_phone )
SRC_SATE_MDM       as ( SELECT * FROM BUS_VAULT.stg_pb_supplier_sites_email )
*/
---- LOGIC LAYER ----

, LOGIC_HSUPP as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , REC_SRC
      , BKCC
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
      , SUPPLIER_HK                                                  as                                    LNK_SUPPLIER_HK
    FROM SRC_L
)

, LOGIC_H as (
    SELECT
        SUPPLIER_SITE_BK                                             as                               MDM_SUPPLIER_SITE_BK
      , SUPPLIER_SITE_HK                                             as                               HUB_SUPPLIER_SITE_HK
    FROM SRC_H
)

, LOGIC_SAT_MDM as (
    SELECT
        ADDRESS_TYPE                                                 as                                   MDM_ADDRESS_TYPE
      , ADDRESS_LINE_1                                               as                                 MDM_ADDRESS_LINE_1
      , ADDRESS_LINE_2                                               as                                 MDM_ADDRESS_LINE_2
      , CITY                                                         as                                           MDM_CITY
      , STATE                                                        as                                          MDM_STATE
      , POSTAL_CODE                                                  as                                    MDM_POSTAL_CODE
      , COUNTRY                                                      as                                        MDM_COUNTRY
      , TAX_NUMBER                                                   as                                     MDM_TAX_NUMBER
      , SUPPLIER_TYPE                                                as                                  MDM_SUPPLIER_TYPE
      , LAST_RUN_DATE                                                as                 MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD
      , SITE_STATUS                                                  as                                    MDM_SITE_STATUS
      , INACTIVE_DATE                                                as                        MDM_INACTIVE_DATE__YYYYMMDD
      , PSA_DELETE_IND                                               as                                     MDM_IS_DELETED
      , SUPPLIER_SITE_HK                                             as                           SAT_MDM_SUPPLIER_SITE_HK
    FROM SRC_SAT_MDM
)

, LOGIC_SATP_MDM as (
    SELECT
        PHONE_NUMBER                                                 as                                   MDM_PHONE_NUMBER
      , FAX_NUMBER                                                   as                                     MDM_FAX_NUMBER
      , LAST_RUN_DATE                                                as             MDM_PHN_SOURCE_LAST_RUN_DATE__YYYYMMDD
      , SUPPLIER_SITE_HK                                             as                          SATP_MDM_SUPPLIER_SITE_HK
    FROM SRC_SATP_MDM
)

, LOGIC_SATE_MDM as (
    SELECT
        EMAIL_ADDRESS                                                as                          MDM_PRIMARY_EMAIL_ADDRESS
      , LAST_RUN_DATE                                                as           MDM_EMAIL_SOURCE_LAST_RUN_DATE__YYYYMMDD
      , SUPPLIER_SITE_HK                                             as                          SATE_MDM_SUPPLIER_SITE_HK
    FROM SRC_SATE_MDM
)
---- RENAME LAYER ----

, RENAME_HSUPP as (
    SELECT
        SUPPLIER_HK
      , SUPPLIER_BK
      , REC_SRC
      , BKCC
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
      , HUB_SUPPLIER_SITE_HK
    FROM LOGIC_H
)

, RENAME_SAT_MDM as (
    SELECT
        MDM_ADDRESS_TYPE
      , MDM_ADDRESS_LINE_1
      , MDM_ADDRESS_LINE_2
      , MDM_CITY
      , MDM_STATE
      , MDM_POSTAL_CODE
      , MDM_COUNTRY
      , MDM_TAX_NUMBER
      , MDM_SUPPLIER_TYPE
      , MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD
      , MDM_SITE_STATUS
      , MDM_INACTIVE_DATE__YYYYMMDD
      , MDM_IS_DELETED
      , SAT_MDM_SUPPLIER_SITE_HK
    FROM LOGIC_SAT_MDM
)

, RENAME_SATP_MDM as (
    SELECT
        MDM_PHONE_NUMBER
      , MDM_FAX_NUMBER
      , MDM_PHN_SOURCE_LAST_RUN_DATE__YYYYMMDD
      , SATP_MDM_SUPPLIER_SITE_HK
    FROM LOGIC_SATP_MDM
)

, RENAME_SATE_MDM as (
    SELECT
        MDM_PRIMARY_EMAIL_ADDRESS
      , MDM_EMAIL_SOURCE_LAST_RUN_DATE__YYYYMMDD
      , SATE_MDM_SUPPLIER_SITE_HK
    FROM LOGIC_SATE_MDM
)

, RENAME_L as (
    SELECT
        SUPPLIER_SITE_HK
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

, FILTER_SAT_MDM as (
    SELECT *
    FROM RENAME_SAT_MDM
)

, FILTER_SATP_MDM as (
    SELECT *
    FROM RENAME_SATP_MDM
)

, FILTER_SATE_MDM as (
    SELECT *
    FROM RENAME_SATE_MDM
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
    LEFT JOIN FILTER_SAT_MDM
        ON HUB_SUPPLIER_SITE_HK = SAT_MDM_SUPPLIER_SITE_HK
    LEFT JOIN FILTER_SATP_MDM
        ON HUB_SUPPLIER_SITE_HK = SATP_MDM_SUPPLIER_SITE_HK
    LEFT JOIN FILTER_SATE_MDM
        ON HUB_SUPPLIER_SITE_HK = SATE_MDM_SUPPLIER_SITE_HK
    INNER JOIN FILTER_MDM_HUB_LKUP
        ON LSAS_SAME_AS_SUPPLIER_HK = MDM_HUB_LKUP_SUPPLIER_HK
)

---- FINAL LAYER ----
SELECT
          ROW_NUMBER() OVER(ORDER BY 1)                                as SEQ_ID
        , CURRENT_TIMESTAMP                                            as SNAPSHOTDATE
        , SUPPLIER_HK
        , SUPPLIER_BK
        , md5_binary(nullif(concat_ws(
            '||'
            , coalesce(nullif(upper(trim(SUPPLIER_BK)), ''), '^^')
            , coalesce(nullif(upper(trim(MDM_SUPPLIER_SITE_BK)), ''), '^^')        
             , coalesce(nullif(upper(trim(MDM_SUPPLIER_BK)), ''), '^^')        )
            , '^^||^^')) as SUPPLIER_SITE_KEY
        , MDM_SUPPLIER_BK
        , iff(LSAS_SAME_AS_SUPPLIER_HK IS NULL, 'N', 'Y')                   as MDM_GOLDEN_RECORD
        , MDM_SUPPLIER_SITE_BK
        , MDM_ADDRESS_TYPE
        , MDM_ADDRESS_LINE_1
        , MDM_ADDRESS_LINE_2
        , MDM_CITY
        , MDM_STATE
        , MDM_POSTAL_CODE
        , MDM_COUNTRY
        , MDM_TAX_NUMBER
        , MDM_SUPPLIER_TYPE
        , TO_CHAR(MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD, 'YYYYMMDD')::INTEGER              as MDM_SOURCE_LAST_RUN_DATE__YYYYMMDD
        , MDM_SITE_STATUS
        , TO_CHAR(MDM_INACTIVE_DATE__YYYYMMDD, 'YYYYMMDD')::INTEGER                     as MDM_INACTIVE_DATE__YYYYMMDD
        , MDM_IS_DELETED
        , MDM_PHONE_NUMBER
        , MDM_FAX_NUMBER
        , MDM_PRIMARY_EMAIL_ADDRESS
        , TO_CHAR(MDM_PHN_SOURCE_LAST_RUN_DATE__YYYYMMDD, 'YYYYMMDD')::INTEGER           as MDM_PHN_SOURCE_LAST_RUN_DATE__YYYYMMDD
        , TO_CHAR(MDM_EMAIL_SOURCE_LAST_RUN_DATE__YYYYMMDD, 'YYYYMMDD')::INTEGER         as MDM_EMAIL_SOURCE_LAST_RUN_DATE__YYYYMMDD
        , SUPPLIER_SITE_HK
        , REC_SRC
        , BKCC
        , MDM_REC_SRC
        , MDM_BKCC
FROM JOIN_RESULT
