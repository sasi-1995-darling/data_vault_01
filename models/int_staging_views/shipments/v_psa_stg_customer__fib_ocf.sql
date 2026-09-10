---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('outd_ocf_hz', 'hz_cust_accounts') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_S              as ( SELECT * FROM outd_ocf_hz.hz_cust_accounts )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        ACCOUNT_NUMBER                                               as                                        CUSTOMER_BK
      , CUST_ACCOUNT_ID
      , ACCOUNT_NUMBER
      , AUTOPAY_FLAG
      , LAST_BATCH_ID
      , ATTRIBUTE_3
      , ATTRIBUTE_4
      , ATTRIBUTE_5
      , ATTRIBUTE_6
      , ATTRIBUTE_7
      , ATTRIBUTE_8
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , JOB_DEFINITION_NAME
      , JOB_DEFINITION_PACKAGE
      , ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE_3
      , GLOBAL_ATTRIBUTE_4
      , GLOBAL_ATTRIBUTE_5
      , GLOBAL_ATTRIBUTE_6
      , GLOBAL_ATTRIBUTE_7
      , STATUS
      , CUSTOMER_TYPE
      , CUSTOMER_CLASS_CODE
      , TAX_CODE
      , TAX_HEADER_LEVEL_FLAG
      , TAX_ROUNDING_RULE
      , ATTRIBUTE_10
      , ATTRIBUTE_11
      , ATTRIBUTE_12
      , ATTRIBUTE_1
      , ATTRIBUTE_2
      , ATTRIBUTE_13
      , ATTRIBUTE_14
      , ATTRIBUTE_15
      , ATTRIBUTE_16
      , ATTRIBUTE_17
      , ATTRIBUTE_18
      , ATTRIBUTE_9
      , PARTY_ID
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , GLOBAL_ATTRIBUTE_DATE_1
      , GLOBAL_ATTRIBUTE_DATE_5
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE_1
      , GLOBAL_ATTRIBUTE_2
      , GLOBAL_ATTRIBUTE_8
      , GLOBAL_ATTRIBUTE_9
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , GLOBAL_ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_11
      , GLOBAL_ATTRIBUTE_12
      , GLOBAL_ATTRIBUTE_13
      , GLOBAL_ATTRIBUTE_14
      , GLOBAL_ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , GLOBAL_ATTRIBUTE_DATE_2
      , GLOBAL_ATTRIBUTE_DATE_3
      , GLOBAL_ATTRIBUTE_DATE_4
      , ATTRIBUTE_19
      , ATTRIBUTE_20
      , ORIG_SYSTEM_REFERENCE
      , COTERMINATE_DAY_MONTH
      , ACCOUNT_ESTABLISHED_DATE
      , HELD_BILL_EXPIRATION_DATE
      , HOLD_BILL_FLAG
      , ACCOUNT_NAME
      , DEPOSIT_REFUND_METHOD
      , NPA_NUMBER
      , SOURCE_CODE
      , COMMENTS
      , DATE_TYPE_PREFERENCE
      , OBJECT_VERSION_NUMBER
      , CREATED_BY_MODULE
      , SELLING_PARTY_ID
      , CONFLICT_ID
      , USER_LAST_UPDATE_DATE
      , ATTRIBUTE_NUMBER_8
      , ATTRIBUTE_NUMBER_9
      , ATTRIBUTE_NUMBER_10
      , ATTRIBUTE_NUMBER_11
      , ATTRIBUTE_NUMBER_12
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_DATE_4
      , ATTRIBUTE_DATE_5
      , ARRIVALSETS_INCLUDE_LINES_FLAG
      , STATUS_UPDATE_DATE
      , ATTRIBUTE_21
      , ATTRIBUTE_22
      , ATTRIBUTE_23
      , ATTRIBUTE_24
      , ATTRIBUTE_28
      , ATTRIBUTE_29
      , ATTRIBUTE_30
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_NUMBER_6
      , ATTRIBUTE_NUMBER_7
      , ATTRIBUTE_DATE_6
      , ATTRIBUTE_DATE_7
      , ATTRIBUTE_DATE_8
      , ATTRIBUTE_DATE_9
      , ATTRIBUTE_DATE_10
      , ATTRIBUTE_25
      , ATTRIBUTE_26
      , ATTRIBUTE_27
      , CPDRF_VER_SOR
      , CPDRF_VER_PILLAR
      , CPDRF_LAST_UPD
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_DATE_11
      , ATTRIBUTE_DATE_12
      , ACCOUNT_TERMINATION_DATE
      , GLOBAL_ATTRIBUTE_17
      , GLOBAL_ATTRIBUTE_18
      , GLOBAL_ATTRIBUTE_19
      , GLOBAL_ATTRIBUTE_20
      , GLOBAL_ATTRIBUTE_21
      , GLOBAL_ATTRIBUTE_22
      , GLOBAL_ATTRIBUTE_23
      , GLOBAL_ATTRIBUTE_24
      , GLOBAL_ATTRIBUTE_25
      , GLOBAL_ATTRIBUTE_26
      , GLOBAL_ATTRIBUTE_27
      , GLOBAL_ATTRIBUTE_28
      , GLOBAL_ATTRIBUTE_29
      , GLOBAL_ATTRIBUTE_30
      , GLOBAL_ATTRIBUTE_16
      , _FIVETRAN_DELETED
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
        CUSTOMER_BK
      , CUST_ACCOUNT_ID
      , ACCOUNT_NUMBER
      , AUTOPAY_FLAG
      , LAST_BATCH_ID
      , ATTRIBUTE_3
      , ATTRIBUTE_4
      , ATTRIBUTE_5
      , ATTRIBUTE_6
      , ATTRIBUTE_7
      , ATTRIBUTE_8
      , CREATION_DATE
      , CREATED_BY
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , JOB_DEFINITION_NAME
      , JOB_DEFINITION_PACKAGE
      , ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE_3
      , GLOBAL_ATTRIBUTE_4
      , GLOBAL_ATTRIBUTE_5
      , GLOBAL_ATTRIBUTE_6
      , GLOBAL_ATTRIBUTE_7
      , STATUS
      , CUSTOMER_TYPE
      , CUSTOMER_CLASS_CODE
      , TAX_CODE
      , TAX_HEADER_LEVEL_FLAG
      , TAX_ROUNDING_RULE
      , ATTRIBUTE_10
      , ATTRIBUTE_11
      , ATTRIBUTE_12
      , ATTRIBUTE_1
      , ATTRIBUTE_2
      , ATTRIBUTE_13
      , ATTRIBUTE_14
      , ATTRIBUTE_15
      , ATTRIBUTE_16
      , ATTRIBUTE_17
      , ATTRIBUTE_18
      , ATTRIBUTE_9
      , PARTY_ID
      , LAST_UPDATE_DATE
      , LAST_UPDATED_BY
      , GLOBAL_ATTRIBUTE_DATE_1
      , GLOBAL_ATTRIBUTE_DATE_5
      , GLOBAL_ATTRIBUTE_CATEGORY
      , GLOBAL_ATTRIBUTE_1
      , GLOBAL_ATTRIBUTE_2
      , GLOBAL_ATTRIBUTE_8
      , GLOBAL_ATTRIBUTE_9
      , GLOBAL_ATTRIBUTE_NUMBER_2
      , GLOBAL_ATTRIBUTE_NUMBER_3
      , GLOBAL_ATTRIBUTE_NUMBER_4
      , GLOBAL_ATTRIBUTE_NUMBER_5
      , GLOBAL_ATTRIBUTE_10
      , GLOBAL_ATTRIBUTE_11
      , GLOBAL_ATTRIBUTE_12
      , GLOBAL_ATTRIBUTE_13
      , GLOBAL_ATTRIBUTE_14
      , GLOBAL_ATTRIBUTE_15
      , GLOBAL_ATTRIBUTE_NUMBER_1
      , GLOBAL_ATTRIBUTE_DATE_2
      , GLOBAL_ATTRIBUTE_DATE_3
      , GLOBAL_ATTRIBUTE_DATE_4
      , ATTRIBUTE_19
      , ATTRIBUTE_20
      , ORIG_SYSTEM_REFERENCE
      , COTERMINATE_DAY_MONTH
      , ACCOUNT_ESTABLISHED_DATE
      , HELD_BILL_EXPIRATION_DATE
      , HOLD_BILL_FLAG
      , ACCOUNT_NAME
      , DEPOSIT_REFUND_METHOD
      , NPA_NUMBER
      , SOURCE_CODE
      , COMMENTS
      , DATE_TYPE_PREFERENCE
      , OBJECT_VERSION_NUMBER
      , CREATED_BY_MODULE
      , SELLING_PARTY_ID
      , CONFLICT_ID
      , USER_LAST_UPDATE_DATE
      , ATTRIBUTE_NUMBER_8
      , ATTRIBUTE_NUMBER_9
      , ATTRIBUTE_NUMBER_10
      , ATTRIBUTE_NUMBER_11
      , ATTRIBUTE_NUMBER_12
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_DATE_4
      , ATTRIBUTE_DATE_5
      , ARRIVALSETS_INCLUDE_LINES_FLAG
      , STATUS_UPDATE_DATE
      , ATTRIBUTE_21
      , ATTRIBUTE_22
      , ATTRIBUTE_23
      , ATTRIBUTE_24
      , ATTRIBUTE_28
      , ATTRIBUTE_29
      , ATTRIBUTE_30
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_NUMBER_6
      , ATTRIBUTE_NUMBER_7
      , ATTRIBUTE_DATE_6
      , ATTRIBUTE_DATE_7
      , ATTRIBUTE_DATE_8
      , ATTRIBUTE_DATE_9
      , ATTRIBUTE_DATE_10
      , ATTRIBUTE_25
      , ATTRIBUTE_26
      , ATTRIBUTE_27
      , CPDRF_VER_SOR
      , CPDRF_VER_PILLAR
      , CPDRF_LAST_UPD
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_DATE_11
      , ATTRIBUTE_DATE_12
      , ACCOUNT_TERMINATION_DATE
      , GLOBAL_ATTRIBUTE_17
      , GLOBAL_ATTRIBUTE_18
      , GLOBAL_ATTRIBUTE_19
      , GLOBAL_ATTRIBUTE_20
      , GLOBAL_ATTRIBUTE_21
      , GLOBAL_ATTRIBUTE_22
      , GLOBAL_ATTRIBUTE_23
      , GLOBAL_ATTRIBUTE_24
      , GLOBAL_ATTRIBUTE_25
      , GLOBAL_ATTRIBUTE_26
      , GLOBAL_ATTRIBUTE_27
      , GLOBAL_ATTRIBUTE_28
      , GLOBAL_ATTRIBUTE_29
      , GLOBAL_ATTRIBUTE_30
      , GLOBAL_ATTRIBUTE_16
      , _FIVETRAN_DELETED
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
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.HZ_CUST_ACCOUNTS'
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
          CUSTOMER_BK
        , CUST_ACCOUNT_ID
        , ACCOUNT_NUMBER
        , AUTOPAY_FLAG
        , LAST_BATCH_ID
        , ATTRIBUTE_3
        , ATTRIBUTE_4
        , ATTRIBUTE_5
        , ATTRIBUTE_6
        , ATTRIBUTE_7
        , ATTRIBUTE_8
        , CREATION_DATE
        , CREATED_BY
        , LAST_UPDATE_LOGIN
        , REQUEST_ID
        , JOB_DEFINITION_NAME
        , JOB_DEFINITION_PACKAGE
        , ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE_3
        , GLOBAL_ATTRIBUTE_4
        , GLOBAL_ATTRIBUTE_5
        , GLOBAL_ATTRIBUTE_6
        , GLOBAL_ATTRIBUTE_7
        , STATUS
        , CUSTOMER_TYPE
        , CUSTOMER_CLASS_CODE
        , TAX_CODE
        , TAX_HEADER_LEVEL_FLAG
        , TAX_ROUNDING_RULE
        , ATTRIBUTE_10
        , ATTRIBUTE_11
        , ATTRIBUTE_12
        , ATTRIBUTE_1
        , ATTRIBUTE_2
        , ATTRIBUTE_13
        , ATTRIBUTE_14
        , ATTRIBUTE_15
        , ATTRIBUTE_16
        , ATTRIBUTE_17
        , ATTRIBUTE_18
        , ATTRIBUTE_9
        , PARTY_ID
        , LAST_UPDATE_DATE
        , LAST_UPDATED_BY
        , GLOBAL_ATTRIBUTE_DATE_1
        , GLOBAL_ATTRIBUTE_DATE_5
        , GLOBAL_ATTRIBUTE_CATEGORY
        , GLOBAL_ATTRIBUTE_1
        , GLOBAL_ATTRIBUTE_2
        , GLOBAL_ATTRIBUTE_8
        , GLOBAL_ATTRIBUTE_9
        , GLOBAL_ATTRIBUTE_NUMBER_2
        , GLOBAL_ATTRIBUTE_NUMBER_3
        , GLOBAL_ATTRIBUTE_NUMBER_4
        , GLOBAL_ATTRIBUTE_NUMBER_5
        , GLOBAL_ATTRIBUTE_10
        , GLOBAL_ATTRIBUTE_11
        , GLOBAL_ATTRIBUTE_12
        , GLOBAL_ATTRIBUTE_13
        , GLOBAL_ATTRIBUTE_14
        , GLOBAL_ATTRIBUTE_15
        , GLOBAL_ATTRIBUTE_NUMBER_1
        , GLOBAL_ATTRIBUTE_DATE_2
        , GLOBAL_ATTRIBUTE_DATE_3
        , GLOBAL_ATTRIBUTE_DATE_4
        , ATTRIBUTE_19
        , ATTRIBUTE_20
        , ORIG_SYSTEM_REFERENCE
        , COTERMINATE_DAY_MONTH
        , ACCOUNT_ESTABLISHED_DATE
        , HELD_BILL_EXPIRATION_DATE
        , HOLD_BILL_FLAG
        , ACCOUNT_NAME
        , DEPOSIT_REFUND_METHOD
        , NPA_NUMBER
        , SOURCE_CODE
        , COMMENTS
        , DATE_TYPE_PREFERENCE
        , OBJECT_VERSION_NUMBER
        , CREATED_BY_MODULE
        , SELLING_PARTY_ID
        , CONFLICT_ID
        , USER_LAST_UPDATE_DATE
        , ATTRIBUTE_NUMBER_8
        , ATTRIBUTE_NUMBER_9
        , ATTRIBUTE_NUMBER_10
        , ATTRIBUTE_NUMBER_11
        , ATTRIBUTE_NUMBER_12
        , ATTRIBUTE_DATE_1
        , ATTRIBUTE_DATE_2
        , ATTRIBUTE_DATE_3
        , ATTRIBUTE_DATE_4
        , ATTRIBUTE_DATE_5
        , ARRIVALSETS_INCLUDE_LINES_FLAG
        , STATUS_UPDATE_DATE
        , ATTRIBUTE_21
        , ATTRIBUTE_22
        , ATTRIBUTE_23
        , ATTRIBUTE_24
        , ATTRIBUTE_28
        , ATTRIBUTE_29
        , ATTRIBUTE_30
        , ATTRIBUTE_NUMBER_2
        , ATTRIBUTE_NUMBER_3
        , ATTRIBUTE_NUMBER_4
        , ATTRIBUTE_NUMBER_5
        , ATTRIBUTE_NUMBER_6
        , ATTRIBUTE_NUMBER_7
        , ATTRIBUTE_DATE_6
        , ATTRIBUTE_DATE_7
        , ATTRIBUTE_DATE_8
        , ATTRIBUTE_DATE_9
        , ATTRIBUTE_DATE_10
        , ATTRIBUTE_25
        , ATTRIBUTE_26
        , ATTRIBUTE_27
        , CPDRF_VER_SOR
        , CPDRF_VER_PILLAR
        , CPDRF_LAST_UPD
        , ATTRIBUTE_NUMBER_1
        , ATTRIBUTE_DATE_11
        , ATTRIBUTE_DATE_12
        , ACCOUNT_TERMINATION_DATE
        , GLOBAL_ATTRIBUTE_17
        , GLOBAL_ATTRIBUTE_18
        , GLOBAL_ATTRIBUTE_19
        , GLOBAL_ATTRIBUTE_20
        , GLOBAL_ATTRIBUTE_21
        , GLOBAL_ATTRIBUTE_22
        , GLOBAL_ATTRIBUTE_23
        , GLOBAL_ATTRIBUTE_24
        , GLOBAL_ATTRIBUTE_25
        , GLOBAL_ATTRIBUTE_26
        , GLOBAL_ATTRIBUTE_27
        , GLOBAL_ATTRIBUTE_28
        , GLOBAL_ATTRIBUTE_29
        , GLOBAL_ATTRIBUTE_30
        , GLOBAL_ATTRIBUTE_16
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , conditional_change_event(hash(* exclude(psa_load_dts, load_dts, _fivetran_synced))) over(partition by CUSTOMER_BK order by _fivetran_synced) as CCE
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(CUSTOMER_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as CUSTOMER_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CUST_ACCOUNT_ID::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(AUTOPAY_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(LAST_BATCH_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_NAME::text), '^^') 
            , '||', IFNULL(TRIM(JOB_DEFINITION_PACKAGE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_6::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_7::text), '^^') 
            , '||', IFNULL(TRIM(STATUS::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(CUSTOMER_CLASS_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TAX_HEADER_LEVEL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(TAX_ROUNDING_RULE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_8::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_9::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_10::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_11::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_12::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_13::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_14::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_15::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(ORIG_SYSTEM_REFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(COTERMINATE_DAY_MONTH::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_ESTABLISHED_DATE::text), '^^') 
            , '||', IFNULL(TRIM(HELD_BILL_EXPIRATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(HOLD_BILL_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_NAME::text), '^^') 
            , '||', IFNULL(TRIM(DEPOSIT_REFUND_METHOD::text), '^^') 
            , '||', IFNULL(TRIM(NPA_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(SOURCE_CODE::text), '^^') 
            , '||', IFNULL(TRIM(COMMENTS::text), '^^') 
            , '||', IFNULL(TRIM(DATE_TYPE_PREFERENCE::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY_MODULE::text), '^^') 
            , '||', IFNULL(TRIM(SELLING_PARTY_ID::text), '^^') 
            , '||', IFNULL(TRIM(CONFLICT_ID::text), '^^') 
            , '||', IFNULL(TRIM(USER_LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(ARRIVALSETS_INCLUDE_LINES_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(STATUS_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_21::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_22::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_23::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_24::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_28::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_29::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_30::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_25::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_26::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_27::text), '^^') 
            , '||', IFNULL(TRIM(CPDRF_VER_SOR::text), '^^') 
            , '||', IFNULL(TRIM(CPDRF_VER_PILLAR::text), '^^') 
            , '||', IFNULL(TRIM(CPDRF_LAST_UPD::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_12::text), '^^') 
            , '||', IFNULL(TRIM(ACCOUNT_TERMINATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_17::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_18::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_19::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_20::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_21::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_22::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_23::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_24::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_25::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_26::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_27::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_28::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_29::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_30::text), '^^') 
            , '||', IFNULL(TRIM(GLOBAL_ATTRIBUTE_16::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(CCE::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
