---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'ccmstr') }} as SRC 
                        /* The following qualify clause is required to pick the latest change for a day when there are Intra day changes,
                            when Fivetran resync triggered by manual sync multiple times in a day(Resync Happens usually once per week currently). Ex. cust_id ='36196' */
                            qualify 1 = row_number() over(partition by COST_CTR, _fivetran_synced order by psa_load_dts desc) ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM tt_e21prd_e21trubis.ccmstr )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        COST_CTR                                                     as                                           PLANT_BK
      , COST_CTR
      , ZIP
      , CONTACT
      , DELIVERY_PROMPT
      , ALT_DEL_GEO
      , SLOB_IGNORE_DAYS
      , CITY_EXID
      , TAX_TYPE1_EXID
      , STATE_EXID
      , BUS_NAME
      , ALOC_WINDOW
      , DEF_BOL_PRNTR
      , FAC_TYPE
      , LOCK_BOX_CODE
      , CNTRY_CODE
      , GEO_CODE
      , ALLOC_XFER
      , ACCT_PREFIX
      , ALLOW_CONS_PICK
      , TAX_EXEMPT_ID
      , RF_COUNT_TYPE
      , INCOME_MASK
      , COUNTRY_EXID
      , TAX_TYPE2_EXID
      , VMI_CUST_CODE
      , TAX_TYPE3_EXID
      , ALT_DEL_ADDER1
      , DEF_PICK_PRNTR
      , ALT_DEL_ADDER3
      , WO_SCHED_DATE
      , ALT_DEL_COUNTRY
      , ALT_DEL_ADDER2
      , MANAGER_ID
      , VMI_SHIPTO_CODE
      , DEF_LABEL_PRNTR
      , ALT_DEL_STATE
      , TAX_TYPE4_EXID
      , PHONE
      , STATE
      , DEF_PRO_PRNTR
      , BAL_LEDGER
      , ALT_DEL_CITY
      , ALT_DEL_ZIP
      , ADDRESS1
      , PRINT_BORD_TALLY
      , ADDRESS3
      , AUTO_MTO_ICT
      , ADDRESS2
      , MFG_OFFSET
      , SHIP_FUDGE
      , PARENT_LOC
      , DEF_CST_SRV_ID
      , BAL_MASK
      , INT_COMP
      , CITY
      , DEF_PACK_PRNTR
      , BUS_NAME2
      , COUNTY_EXID
      , FAX
      , TAX_CODE
      , DEF_BUYER_ID
      , AUTOCALC_FRT
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
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
        PLANT_BK
      , COST_CTR
      , ZIP
      , CONTACT
      , DELIVERY_PROMPT
      , ALT_DEL_GEO
      , SLOB_IGNORE_DAYS
      , CITY_EXID
      , TAX_TYPE1_EXID
      , STATE_EXID
      , BUS_NAME
      , ALOC_WINDOW
      , DEF_BOL_PRNTR
      , FAC_TYPE
      , LOCK_BOX_CODE
      , CNTRY_CODE
      , GEO_CODE
      , ALLOC_XFER
      , ACCT_PREFIX
      , ALLOW_CONS_PICK
      , TAX_EXEMPT_ID
      , RF_COUNT_TYPE
      , INCOME_MASK
      , COUNTRY_EXID
      , TAX_TYPE2_EXID
      , VMI_CUST_CODE
      , TAX_TYPE3_EXID
      , ALT_DEL_ADDER1
      , DEF_PICK_PRNTR
      , ALT_DEL_ADDER3
      , WO_SCHED_DATE
      , ALT_DEL_COUNTRY
      , ALT_DEL_ADDER2
      , MANAGER_ID
      , VMI_SHIPTO_CODE
      , DEF_LABEL_PRNTR
      , ALT_DEL_STATE
      , TAX_TYPE4_EXID
      , PHONE
      , STATE
      , DEF_PRO_PRNTR
      , BAL_LEDGER
      , ALT_DEL_CITY
      , ALT_DEL_ZIP
      , ADDRESS1
      , PRINT_BORD_TALLY
      , ADDRESS3
      , AUTO_MTO_ICT
      , ADDRESS2
      , MFG_OFFSET
      , SHIP_FUDGE
      , PARENT_LOC
      , DEF_CST_SRV_ID
      , BAL_MASK
      , INT_COMP
      , CITY
      , DEF_PACK_PRNTR
      , BUS_NAME2
      , COUNTY_EXID
      , FAX
      , TAX_CODE
      , DEF_BUYER_ID
      , AUTOCALC_FRT
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , _FIVETRAN_ID
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
    WHERE rec_src = 'USOHMA.ORCL.E21PRD.CCMSTR'
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
          PLANT_BK
        , COST_CTR
        , ZIP
        , CONTACT
        , DELIVERY_PROMPT
        , ALT_DEL_GEO
        , SLOB_IGNORE_DAYS
        , CITY_EXID
        , TAX_TYPE1_EXID
        , STATE_EXID
        , BUS_NAME
        , ALOC_WINDOW
        , DEF_BOL_PRNTR
        , FAC_TYPE
        , LOCK_BOX_CODE
        , CNTRY_CODE
        , GEO_CODE
        , ALLOC_XFER
        , ACCT_PREFIX
        , ALLOW_CONS_PICK
        , TAX_EXEMPT_ID
        , RF_COUNT_TYPE
        , INCOME_MASK
        , COUNTRY_EXID
        , TAX_TYPE2_EXID
        , VMI_CUST_CODE
        , TAX_TYPE3_EXID
        , ALT_DEL_ADDER1
        , DEF_PICK_PRNTR
        , ALT_DEL_ADDER3
        , WO_SCHED_DATE
        , ALT_DEL_COUNTRY
        , ALT_DEL_ADDER2
        , MANAGER_ID
        , VMI_SHIPTO_CODE
        , DEF_LABEL_PRNTR
        , ALT_DEL_STATE
        , TAX_TYPE4_EXID
        , PHONE
        , STATE
        , DEF_PRO_PRNTR
        , BAL_LEDGER
        , ALT_DEL_CITY
        , ALT_DEL_ZIP
        , ADDRESS1
        , PRINT_BORD_TALLY
        , ADDRESS3
        , AUTO_MTO_ICT
        , ADDRESS2
        , MFG_OFFSET
        , SHIP_FUDGE
        , PARENT_LOC
        , DEF_CST_SRV_ID
        , BAL_MASK
        , INT_COMP
        , CITY
        , DEF_PACK_PRNTR
        , BUS_NAME2
        , COUNTY_EXID
        , FAX
        , TAX_CODE
        , DEF_BUYER_ID
        , AUTOCALC_FRT
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , _FIVETRAN_ID
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(ZIP::text), '^^') 
            , '||', IFNULL(TRIM(CONTACT::text), '^^') 
            , '||', IFNULL(TRIM(DELIVERY_PROMPT::text), '^^') 
            , '||', IFNULL(TRIM(ALT_DEL_GEO::text), '^^') 
            , '||', IFNULL(TRIM(SLOB_IGNORE_DAYS::text), '^^') 
            , '||', IFNULL(TRIM(CITY_EXID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_TYPE1_EXID::text), '^^') 
            , '||', IFNULL(TRIM(STATE_EXID::text), '^^') 
            , '||', IFNULL(TRIM(BUS_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ALOC_WINDOW::text), '^^') 
            , '||', IFNULL(TRIM(DEF_BOL_PRNTR::text), '^^') 
            , '||', IFNULL(TRIM(FAC_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(LOCK_BOX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CNTRY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(GEO_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ALLOC_XFER::text), '^^') 
            , '||', IFNULL(TRIM(ACCT_PREFIX::text), '^^') 
            , '||', IFNULL(TRIM(ALLOW_CONS_PICK::text), '^^') 
            , '||', IFNULL(TRIM(TAX_EXEMPT_ID::text), '^^') 
            , '||', IFNULL(TRIM(RF_COUNT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(INCOME_MASK::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY_EXID::text), '^^') 
            , '||', IFNULL(TRIM(TAX_TYPE2_EXID::text), '^^') 
            , '||', IFNULL(TRIM(VMI_CUST_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_TYPE3_EXID::text), '^^') 
            , '||', IFNULL(TRIM(ALT_DEL_ADDER1::text), '^^') 
            , '||', IFNULL(TRIM(DEF_PICK_PRNTR::text), '^^') 
            , '||', IFNULL(TRIM(ALT_DEL_ADDER3::text), '^^') 
            , '||', IFNULL(TRIM(WO_SCHED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ALT_DEL_COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(ALT_DEL_ADDER2::text), '^^') 
            , '||', IFNULL(TRIM(MANAGER_ID::text), '^^') 
            , '||', IFNULL(TRIM(VMI_SHIPTO_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DEF_LABEL_PRNTR::text), '^^') 
            , '||', IFNULL(TRIM(ALT_DEL_STATE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_TYPE4_EXID::text), '^^') 
            , '||', IFNULL(TRIM(PHONE::text), '^^') 
            , '||', IFNULL(TRIM(STATE::text), '^^') 
            , '||', IFNULL(TRIM(DEF_PRO_PRNTR::text), '^^') 
            , '||', IFNULL(TRIM(BAL_LEDGER::text), '^^') 
            , '||', IFNULL(TRIM(ALT_DEL_CITY::text), '^^') 
            , '||', IFNULL(TRIM(ALT_DEL_ZIP::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS1::text), '^^') 
            , '||', IFNULL(TRIM(PRINT_BORD_TALLY::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS3::text), '^^') 
            , '||', IFNULL(TRIM(AUTO_MTO_ICT::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS2::text), '^^') 
            , '||', IFNULL(TRIM(MFG_OFFSET::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_FUDGE::text), '^^') 
            , '||', IFNULL(TRIM(PARENT_LOC::text), '^^') 
            , '||', IFNULL(TRIM(DEF_CST_SRV_ID::text), '^^') 
            , '||', IFNULL(TRIM(BAL_MASK::text), '^^') 
            , '||', IFNULL(TRIM(INT_COMP::text), '^^') 
            , '||', IFNULL(TRIM(CITY::text), '^^') 
            , '||', IFNULL(TRIM(DEF_PACK_PRNTR::text), '^^') 
            , '||', IFNULL(TRIM(BUS_NAME2::text), '^^') 
            , '||', IFNULL(TRIM(COUNTY_EXID::text), '^^') 
            , '||', IFNULL(TRIM(FAX::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(DEF_BUYER_ID::text), '^^') 
            , '||', IFNULL(TRIM(AUTOCALC_FRT::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
