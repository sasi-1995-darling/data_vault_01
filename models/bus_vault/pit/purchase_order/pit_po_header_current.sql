---- SRC LAYER ----
WITH
SRC_H              as ( 
    SELECT 
        PO_HEADER_HK, 
        PO_HEADER_BK, 
        BKCC, 
        REC_SRC 
    FROM {{ ref('hub_po_header') }} as SRC 
    WHERE REC_SRC not in ('USOHNO.SAP.ECCPRD.Z_EKBE', 'USOHNO.SAP.ECCPRD.Z_RESB')
    /*The above filter is to handle orphan records from the PO receipt WINN which is causing Null issue*/ ),
SRC_SAT_ML         as ( 
    SELECT 
        SEGMENT1, 
        TYPE_LOOKUP_CODE, 
        CANCEL_FLAG, 
        AUTHORIZATION_STATUS, 
        CREATION_DATE, 
        TERMS_ID, 
        PO_HEADER_HK, 
        FOB_LOOKUP_CODE, 
        AGENT_ID, 
        CURRENCY_CODE, 
        DESCRIPTION,
        _FIVETRAN_DELETED
    FROM {{ ref('sat_po_header__ml_ebs') }} as SRC 
    QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) 
),
SRC_SAT_WINN       as ( 
    SELECT 
        INCO2, 
        EKORG, 
        BEDAT, 
        EBELN, 
        BSART, 
        LOEKZ, 
        PROCSTAT, 
        ZTERM, 
        PO_HEADER_HK, 
        INCO1, 
        EKGRP, 
        WAERS, 
        PSA_DELETE_IND, 
        ZBD1T 
    FROM {{ ref('sat_po_header__winn_sap') }} as SRC 
    QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) 
),
SRC_SAT_LRSN       as ( 
    SELECT 
        PO_HEADER_HK, 
        BUSINESS_UNIT, 
        PO_ID, 
        PO_TYPE, 
        PO_STATUS, 
        PO_DT, 
        PYMNT_TERMS_CD, 
        BUYER_ID, 
        CURRENCY_CD, 
        _FIVETRAN_DELETED 
    FROM {{ ref('sat_po_header__lrsn_psft') }} as SRC 
    QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) 
),
SRC_SAT_TT_GP      as ( 
    SELECT 
        PO_HEADER_HK, 
        PONUMBER, 
        POTYPE, 
        POSTATUS, 
        DOCDATE, 
        PYMTRMID, 
        BUYERID, 
        PSA_DELETE_IND 
    FROM {{ ref('sat_po_header__tt_gp') }} as SRC 
    QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) 
),
SRC_SAT_TT_E21     as ( 
    SELECT 
        PO_HEADER_HK, 
        PO_NUMBER, 
        PO_TYPE, 
        PO_STATUS, 
        DATE_ENTERED, 
        TERMS_CODE, 
        BUYER_ID, 
        PSA_DELETE_IND, 
        REL_NUMB, 
        RELEASE_DATE,
        LOAD_DTS 
    FROM {{ ref('msat_po_header__tt_e21') }} as SRC 
    QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY REL_NUMB DESC, LOAD_DTS DESC) 
),
SRC_REF_TT_E21     as ( 
    SELECT 
        PO_STATUS_CODE_VALUE, 
        PO_STATUS_NUM_VALUE, 
        PO_STATUS_CODE_TYPE, 
        LOAD_DTS 
    FROM {{ ref('ref_po_status__tt_e21') }} as SRC 
    QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_STATUS_CODE_TYPE ORDER BY LOAD_DTS DESC) 
),
SRC_SAT_EMTK       as ( 
    SELECT 
        SEGMENT1, 
        TYPE_LOOKUP_CODE, 
        CANCEL_FLAG, 
        AUTHORIZATION_STATUS, 
        CREATION_DATE, 
        PO_HEADER_HK, 
        FOB_LOOKUP_CODE, 
        TERM_DESCRIPTION, 
        CURRENCY_CODE, 
        TERMS_ID, 
        AGENT_ID, 
        _FIVETRAN_DELETED 
    FROM {{ ref('sat_po_header__emtk_ebs') }} as SRC 
    QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) 
),
SRC_SAT_FIB        as ( 
    SELECT 
        AGENT_ID,
        CANCEL_FLAG, 
        CREATION_DATE, 
        CURRENCY_CODE, 
        DOCUMENT_STATUS, 
        FOB_LOOKUP_CODE, 
        PO_HEADER_HK, 
        SEGMENT_1, 
        TERM_DESCRIPTION, 
        TERMS_ID,
        TYPE_LOOKUP_CODE, 
        _FIVETRAN_DELETED 
    FROM {{ ref('sat_po_header__fib_ocf') }} as SRC 
    QUALIFY 1 = ROW_NUMBER() OVER(PARTITION BY PO_HEADER_HK ORDER BY LOAD_DTS DESC) 
)

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_PO_HEADER )
SRC_SAT_ML         as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__ML_EBS )
SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__WINN_SAP )
SRC_SAT_LRSN       as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__LRSN_PSFT )
SRC_SAT_TT_GP      as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__TT_GP )
SRC_SAT_TT_E21     as ( SELECT * FROM RAW_VAULT.MSAT_PO_HEADER__TT_E21 )
SRC_REF_TT_E21     as ( SELECT * FROM BUS_VAULT.REF_PO_STATUS__TT_E21 )
SRC_SAT_EMTK       as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__EMTK_EBS )
SRC_SAT_FIB        as ( SELECT * FROM RAW_VAULT.SAT_PO_HEADER__FIB_OCF )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_PO_HEADER'                                              as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_ML as (
    SELECT
        SEGMENT1
      , TYPE_LOOKUP_CODE
      , CANCEL_FLAG
      , AUTHORIZATION_STATUS
      , CREATION_DATE
      , TERMS_ID::TEXT                                               as                                           TERMS_ID
      , PO_HEADER_HK                                                 as                                SAT_ML_PO_HEADER_HK
      , FOB_LOOKUP_CODE
      , AGENT_ID::TEXT                                               as                                           AGENT_ID
      , CURRENCY_CODE
      , DESCRIPTION
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                                  _FIVETRAN_DELETED
    FROM SRC_SAT_ML
)

, LOGIC_SAT_WINN as (
    SELECT
        EKORG                                                        as                                     PURCHASING_ORG
      , TRY_TO_DATE(BEDAT, 'YYYYMMDD')                               as                                              BEDAT
      , EBELN
      , BSART
      , LOEKZ
      , PROCSTAT
      , ZTERM
      , PO_HEADER_HK                                                 as                              SAT_WINN_PO_HEADER_HK
      , INCO1
      , EKGRP
      , WAERS
      , PSA_DELETE_IND                                               as                            SAT_WINN_PSA_DELETE_IND
      , ZBD1T
      , INCO2
    FROM SRC_SAT_WINN
)

, LOGIC_SAT_LRSN as (
    SELECT
        PO_HEADER_HK                                                 as                              SAT_LRSN_PO_HEADER_HK
      , BUSINESS_UNIT
      , PO_ID
      , PO_TYPE
      , PO_STATUS
      , PO_DT
      , PYMNT_TERMS_CD
      , BUYER_ID
      , CURRENCY_CD
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                                  _FIVETRAN_DELETED
    FROM SRC_SAT_LRSN
)

, LOGIC_SAT_TT_GP as (
    SELECT
        PO_HEADER_HK                                                 as                             SAT_TT_GP_PO_HEADER_HK
      , PONUMBER
      , POTYPE
      , POSTATUS
      , DOCDATE
      , PYMTRMID
      , BUYERID
      , 'USD'                                                        as                                  TT_GP_CURRENCY_CD
      , PSA_DELETE_IND                                               as                           SAT_TT_GP_PSA_DELETE_IND
    FROM SRC_SAT_TT_GP
)

, LOGIC_SAT_TT_E21 as (
    SELECT
        PO_HEADER_HK                                                 as                            SAT_TT_E21_PO_HEADER_HK
      , PO_NUMBER
      , PO_TYPE                                                      as                                 SAT_TT_E21_PO_TYPE
      , PO_STATUS                                                    as                               SAT_TT_E21_PO_STATUS
      , DATE_ENTERED
      , TERMS_CODE
      , BUYER_ID                                                     as                                       BUYER_ID_E21
      , 'USD'                                                        as                                 TT_E21_CURRENCY_CD
      , PSA_DELETE_IND                                               as                          SAT_TT_E21_PSA_DELETE_IND
      , RELEASE_DATE                                                 as                                    SAT_TT_E21_RELEASE_DATE
    FROM SRC_SAT_TT_E21
)

, LOGIC_REF_TT_E21 as (
    SELECT
        PO_STATUS_CODE_VALUE                                         as                           REF_PO_STATUS_CODE_VALUE
      , PO_STATUS_NUM_VALUE                                          as                            REF_PO_STATUS_NUM_VALUE
    FROM SRC_REF_TT_E21
)

, LOGIC_SAT_EMTK as (
    SELECT
        SEGMENT1                                                     as                                  SAT_EMTK_SEGMENT1
      , TYPE_LOOKUP_CODE                                             as                          SAT_EMTK_TYPE_LOOKUP_CODE
      , CANCEL_FLAG                                                  as                               SAT_EMTK_CANCEL_FLAG
      , AUTHORIZATION_STATUS                                         as                      SAT_EMTK_AUTHORIZATION_STATUS
      , CREATION_DATE                                                as                             SAT_EMTK_CREATION_DATE
      , TERMS_ID::TEXT                                               as                                  SAT_EMTK_TERMS_ID
      , PO_HEADER_HK                                                 as                              SAT_EMTK_PO_HEADER_HK
      , FOB_LOOKUP_CODE                                              as                           SAT_EMTK_FOB_LOOKUP_CODE
      , AGENT_ID::TEXT                                               as                                  SAT_EMTK_AGENT_ID
      , TERM_DESCRIPTION                                             as                          SAT_EMTK_TERM_DESCRIPTION
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                          SAT_EMTK_FIVETRAN_DELETED
      , CURRENCY_CODE                                                as                             SAT_EMTK_CURRENCY_CODE
    FROM SRC_SAT_EMTK
)

, LOGIC_SAT_FIB as (
    SELECT
        SEGMENT_1                                                    as                                      FIB_SEGMENT_1
      , COALESCE(FIB_SEGMENT_1, '-2')                                as                                  SAT_FIB_SEGMENT_1
      , TYPE_LOOKUP_CODE                                             as                           SAT_FIB_TYPE_LOOKUP_CODE
      , CANCEL_FLAG                                                  as                                SAT_FIB_CANCEL_FLAG
      , DOCUMENT_STATUS                                              as                            SAT_FIB_DOCUMENT_STATUS
      , CREATION_DATE                                                as                              SAT_FIB_CREATION_DATE
      , TERMS_ID::TEXT                                               as                                   SAT_FIB_TERMS_ID
      , PO_HEADER_HK                                                 as                               SAT_FIB_PO_HEADER_HK
      , FOB_LOOKUP_CODE                                              as                            SAT_FIB_FOB_LOOKUP_CODE
      , AGENT_ID::TEXT                                               as                                   SAT_FIB_AGENT_ID
      , TERM_DESCRIPTION                                             as                           SAT_FIB_TERM_DESCRIPTION
      , _FIVETRAN_DELETED
      , IFF(_FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                    as                           SAT_FIB_FIVETRAN_DELETED
      , CURRENCY_CODE                                                as                              SAT_FIB_CURRENCY_CODE
    FROM SRC_SAT_FIB
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , PO_HEADER_HK
      , PO_HEADER_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
        PURCHASING_ORG
      , BEDAT
      , EBELN
      , BSART
      , LOEKZ
      , PROCSTAT
      , ZTERM
      , SAT_WINN_PO_HEADER_HK
      , INCO1
      , EKGRP
      , WAERS
      , SAT_WINN_PSA_DELETE_IND
      , ZBD1T
      , INCO2
    FROM LOGIC_SAT_WINN
)

, RENAME_SAT_ML as (
    SELECT
        SEGMENT1
      , TYPE_LOOKUP_CODE
      , CANCEL_FLAG
      , AUTHORIZATION_STATUS
      , CREATION_DATE
      , TERMS_ID
      , SAT_ML_PO_HEADER_HK
      , FOB_LOOKUP_CODE
      , AGENT_ID
      , CURRENCY_CODE
      , DESCRIPTION
      , _FIVETRAN_DELETED
    FROM LOGIC_SAT_ML
)

, RENAME_SAT_LRSN as (
    SELECT
        SAT_LRSN_PO_HEADER_HK
      , BUSINESS_UNIT
      , PO_ID
      , PO_TYPE
      , PO_STATUS
      , PO_DT
      , PYMNT_TERMS_CD
      , BUYER_ID
      , CURRENCY_CD
      , _FIVETRAN_DELETED
    FROM LOGIC_SAT_LRSN
)

, RENAME_SAT_TT_GP as (
    SELECT
        SAT_TT_GP_PO_HEADER_HK
      , PONUMBER
      , POTYPE
      , POSTATUS
      , DOCDATE
      , PYMTRMID
      , BUYERID
      , TT_GP_CURRENCY_CD
      , SAT_TT_GP_PSA_DELETE_IND
    FROM LOGIC_SAT_TT_GP
)

, RENAME_SAT_TT_E21 as (
    SELECT
        SAT_TT_E21_PO_HEADER_HK
      , PO_NUMBER
      , SAT_TT_E21_PO_TYPE
      , SAT_TT_E21_PO_STATUS
      , DATE_ENTERED
      , TERMS_CODE
      , BUYER_ID_E21
      , TT_E21_CURRENCY_CD
      , SAT_TT_E21_PSA_DELETE_IND
      , SAT_TT_E21_RELEASE_DATE
    FROM LOGIC_SAT_TT_E21
)

, RENAME_REF_TT_E21 as (
    SELECT
        REF_PO_STATUS_CODE_VALUE
      , REF_PO_STATUS_NUM_VALUE
    FROM LOGIC_REF_TT_E21
)

, RENAME_SAT_EMTK as (
    SELECT
        SAT_EMTK_SEGMENT1
      , SAT_EMTK_TYPE_LOOKUP_CODE
      , SAT_EMTK_CANCEL_FLAG
      , SAT_EMTK_AUTHORIZATION_STATUS
      , SAT_EMTK_CREATION_DATE
      , SAT_EMTK_TERMS_ID
      , SAT_EMTK_PO_HEADER_HK
      , SAT_EMTK_FOB_LOOKUP_CODE
      , SAT_EMTK_AGENT_ID
      , SAT_EMTK_TERM_DESCRIPTION
      , SAT_EMTK_FIVETRAN_DELETED
      , SAT_EMTK_CURRENCY_CODE
    FROM LOGIC_SAT_EMTK
)

, RENAME_SAT_FIB as (
    SELECT
        FIB_SEGMENT_1
      , SAT_FIB_SEGMENT_1
      , SAT_FIB_TYPE_LOOKUP_CODE
      , SAT_FIB_CANCEL_FLAG
      , SAT_FIB_DOCUMENT_STATUS
      , SAT_FIB_CREATION_DATE
      , SAT_FIB_TERMS_ID
      , SAT_FIB_PO_HEADER_HK
      , SAT_FIB_FOB_LOOKUP_CODE
      , SAT_FIB_AGENT_ID
      , SAT_FIB_TERM_DESCRIPTION
      , _FIVETRAN_DELETED
      , SAT_FIB_FIVETRAN_DELETED
      , SAT_FIB_CURRENCY_CODE
    FROM LOGIC_SAT_FIB
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED' /* This filter is to exclude the ghost records */
)

, FILTER_SAT_ML as (
    SELECT *
    FROM RENAME_SAT_ML
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
)

, FILTER_SAT_LRSN as (
    SELECT *
    FROM RENAME_SAT_LRSN
)

, FILTER_SAT_TT_GP as (
    SELECT *
    FROM RENAME_SAT_TT_GP
)

, FILTER_SAT_TT_E21 as (
    SELECT *
    FROM RENAME_SAT_TT_E21
)

, FILTER_REF_TT_E21 as (
    SELECT *
    FROM RENAME_REF_TT_E21
)

, FILTER_SAT_EMTK as (
    SELECT *
    FROM RENAME_SAT_EMTK
)

, FILTER_SAT_FIB as (
    SELECT *
    FROM RENAME_SAT_FIB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_ML
        ON FILTER_H.PO_HEADER_HK = SAT_ML_PO_HEADER_HK
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_H.PO_HEADER_HK = SAT_WINN_PO_HEADER_HK
    LEFT JOIN FILTER_SAT_LRSN
        ON FILTER_H.PO_HEADER_HK = SAT_LRSN_PO_HEADER_HK
    LEFT JOIN FILTER_SAT_TT_GP
        ON FILTER_H.PO_HEADER_HK = SAT_TT_GP_PO_HEADER_HK
    LEFT JOIN FILTER_SAT_TT_E21
        ON FILTER_H.PO_HEADER_HK = SAT_TT_E21_PO_HEADER_HK
    LEFT JOIN FILTER_REF_TT_E21
        ON FILTER_SAT_TT_E21.SAT_TT_E21_PO_STATUS = REF_PO_STATUS_NUM_VALUE
    LEFT JOIN FILTER_SAT_EMTK
        ON FILTER_H.PO_HEADER_HK = SAT_EMTK_PO_HEADER_HK
    LEFT JOIN FILTER_SAT_FIB
        ON FILTER_H.PO_HEADER_HK = SAT_FIB_PO_HEADER_HK
)

---- FINAL LAYER ----
SELECT
          PIT_REC_SRC
        , SNAPSHOTDATE
        , PIT_LOAD_DTS
        , PO_HEADER_HK
        , PO_HEADER_BK
        , COALESCE(SEGMENT1, EBELN,PO_ID,PONUMBER,PO_NUMBER,SAT_EMTK_SEGMENT1,SAT_FIB_SEGMENT_1) as PO_NUMBER
        , COALESCE(TYPE_LOOKUP_CODE, BSART,PO_TYPE,POTYPE::TEXT,SAT_TT_E21_PO_TYPE,SAT_EMTK_TYPE_LOOKUP_CODE,SAT_FIB_TYPE_LOOKUP_CODE) as SYSTEM_PO_DOCUMENT_TYPE
        , COALESCE(TYPE_LOOKUP_CODE, BSART,PO_TYPE, DECODE(POTYPE,1,'STANDARD',2,'DROP SHIP',3,'BLANKET',4,'BLANKET DROP SHIP'), SAT_TT_E21_PO_TYPE,SAT_EMTK_TYPE_LOOKUP_CODE,SAT_FIB_TYPE_LOOKUP_CODE) as PO_DOCUMENT_TYPE
        , CASE WHEN CANCEL_FLAG = 'N' THEN 'N'
            WHEN BKCC = 'Crouching_Dragon' AND CANCEL_FLAG IS NULL THEN 'N'
            WHEN CANCEL_FLAG = 'Y' THEN 'Y' 
            WHEN LOEKZ IN ('L', 'C') THEN 'Y'
            WHEN LOEKZ ='' THEN 'N'  
		    WHEN po_status = 'X' OR po_status = 'PX' THEN 'Y'
            WHEN BKCC = 'Swimming_Ocean' AND (po_status <> 'X' OR po_status <> 'PX') THEN 'N'
            WHEN SAT_TT_GP_PO_HEADER_HK IS NOT NULL THEN DECODE(POSTATUS ,6 ,'Y','N') 
            WHEN SAT_TT_E21_PO_HEADER_HK IS NOT NULL THEN DECODE(REF_PO_STATUS_CODE_VALUE ,'X' ,'Y','N') 
            WHEN SAT_EMTK_CANCEL_FLAG = 'N' THEN 'N'
            WHEN BKCC = 'Diving_Sea' AND SAT_EMTK_CANCEL_FLAG IS NULL THEN 'N'
            WHEN SAT_EMTK_CANCEL_FLAG = 'Y' THEN 'Y' 
            WHEN SAT_FIB_CANCEL_FLAG = 'N' THEN 'N'
            WHEN BKCC = 'Jumping_River' AND SAT_FIB_CANCEL_FLAG IS NULL THEN 'N'
            WHEN SAT_FIB_CANCEL_FLAG = 'Y' THEN 'Y' 
         END as PO_HEADER_DEL_IND
        , COALESCE(AUTHORIZATION_STATUS, PROCSTAT,PO_STATUS,POSTATUS::TEXT,SAT_TT_E21_PO_STATUS,SAT_EMTK_AUTHORIZATION_STATUS) as SYSTEM_PO_STATUS
        , COALESCE(AUTHORIZATION_STATUS, PROCSTAT,PO_STATUS, DECODE(POSTATUS,1,'NEW',2,'RELEASED',3,'CHANGE ORDER',4,'RECEIVED',5,'CLOSED',6,'CANCELLED'),REF_PO_STATUS_CODE_VALUE,SAT_EMTK_AUTHORIZATION_STATUS,SAT_FIB_DOCUMENT_STATUS) as PO_PROCESSING_STATUS
        , COALESCE(CREATION_DATE, BEDAT,PO_DT,DOCDATE,DATE_ENTERED,SAT_EMTK_CREATION_DATE,SAT_FIB_CREATION_DATE)::DATE as PO_CREATION_DATE
        , COALESCE(DESCRIPTION, ZTERM,PYMNT_TERMS_CD,PYMTRMID,TERMS_CODE,SAT_EMTK_TERM_DESCRIPTION,SAT_FIB_TERM_DESCRIPTION) as PO_PAYMENT_TERMS
        , COALESCE(FOB_LOOKUP_CODE, INCO1,SAT_EMTK_FOB_LOOKUP_CODE)    as INCOTERMS_1
        , COALESCE(INCO2, SAT_FIB_FOB_LOOKUP_CODE)                     as INCOTERMS_2
        , PURCHASING_ORG
        , COALESCE(DESCRIPTION, ZBD1T::text,PYMNT_TERMS_CD,PYMTRMID,TERMS_CODE,SAT_EMTK_TERM_DESCRIPTION) as PAYMENT_TERMS
        , COALESCE(AGENT_ID, EKGRP,BUYER_ID,BUYERID,BUYER_ID_E21, SAT_EMTK_AGENT_ID,SAT_FIB_AGENT_ID) as BUYER_PLANNER_CODE
        , COALESCE(CURRENCY_CODE, WAERS,CURRENCY_CD,TT_GP_CURRENCY_CD,TT_E21_CURRENCY_CD,SAT_EMTK_CURRENCY_CODE,SAT_FIB_CURRENCY_CODE) as PO_CURRENCY
        , SAT_TT_E21_RELEASE_DATE::DATE                               as RELEASE_DATE 
        /* Applicable to Therma-Tru E21 only */
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
/*Filter TT GPD records created with defaulted DOCDATE */
WHERE (docdate <> '1900-01-01 00:00:00.000' OR DOCDATE IS NULL)
/* The below filter is to remove orphan record with PO_NUMBER(SEGMENT_1) bieng NULL for Fibron*/
AND (SAT_FIB_SEGMENT_1 <> '-2' OR SAT_FIB_SEGMENT_1 IS NULL)
