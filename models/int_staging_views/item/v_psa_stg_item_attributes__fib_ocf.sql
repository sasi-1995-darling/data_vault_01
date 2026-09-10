---- SRC LAYER ----
WITH
SRC_S              as ( SELECT * FROM {{ source('outd_ocf_ego', 'ego_item_eff_b') }} as SRC  ),
SRC_A              as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_S2             as ( SELECT * FROM {{ source('outd_ocf_egp', 'egp_system_items_b') }} as SRC 
                        qualify 1 = row_number()over (partition by inventory_item_id, organization_id order by psa_load_dts )  )

/*
SRC_S              as ( SELECT * FROM outd_ocf_ego.ego_item_eff_b )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
, SRC_S2             as ( SELECT * FROM outd_ocf_egp.egp_system_items_b )
*/
---- LOGIC LAYER ----

, LOGIC_S as (
    SELECT
        INVENTORY_ITEM_ID
      , ORGANIZATION_ID
      , EFF_LINE_ID
      , CHANGE_LINE_ID
      , VERSION_START_DATE
      , ATTRIBUTE_CHAR_25
      , ATTRIBUTE_NUMBER_2_UOM
      , ATTRIBUTE_CHAR_37
      , ATTRIBUTE_CHAR_39
      , ATTRIBUTE_CHAR_11
      , ATTRIBUTE_NUMBER_12
      , ATTRIBUTE_DATE_4
      , ATTRIBUTE_NUMBER_14
      , ATTRIBUTE_CHAR_24
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_NUMBER_18
      , ATTRIBUTE_CHAR_5
      , ATTRIBUTE_CHAR_12
      , ATTRIBUTE_NUMBER_20_UOM
      , ACD_TYPE
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_TIMESTAMP_2
      , ATTRIBUTE_CHAR_27
      , ATTRIBUTE_CHAR_13
      , ATTRIBUTE_NUMBER_16
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_7
      , ATTRIBUTE_CHAR_9
      , ATTRIBUTE_CHAR_30
      , ATTRIBUTE_NUMBER_18_UOM
      , ATTRIBUTE_NUMBER_10
      , ATTRIBUTE_CHAR_8
      , ATTRIBUTE_CHAR_15
      , ATTRIBUTE_CHAR_26
      , ATTRIBUTE_TIMESTAMP_9
      , ATTRIBUTE_CHAR_2
      , ATTRIBUTE_CHAR_29
      , CONTEXT_CODE
      , ATTRIBUTE_NUMBER_1_UOM
      , ATTRIBUTE_NUMBER_17_UOM
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_NUMBER_19_UOM
      , ATTRIBUTE_NUMBER_6_UOM
      , ATTRIBUTE_NUMBER_10_UOM
      , ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_NUMBER_7_UOM
      , ATTRIBUTE_NUMBER_11
      , CATEGORY_CODE
      , ATTRIBUTE_NUMBER_14_UOM
      , IMPLEMENTATION_DATE
      , ATTRIBUTE_NUMBER_17
      , ATTRIBUTE_CHAR_33
      , ATTRIBUTE_DATE_10
      , ATTRIBUTE_NUMBER_8_UOM
      , ATTRIBUTE_CHAR_23
      , ATTRIBUTE_DATE_6
      , ATTRIBUTE_DATE_7
      , CHANGE_BIT_MAP
      , ATTRIBUTE_NUMBER_4_UOM
      , ATTRIBUTE_CHAR_1
      , ATTRIBUTE_CHAR_34
      , ATTRIBUTE_NUMBER_16_UOM
      , ATTRIBUTE_CHAR_28
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_CHAR_6
      , ATTRIBUTE_CHAR_22
      , ATTRIBUTE_CHAR_35
      , ATTRIBUTE_CHAR_36
      , CREATED_BY
      , ATTRIBUTE_NUMBER_9
      , ATTRIBUTE_CHAR_38
      , ATTRIBUTE_TIMESTAMP_8
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_NUMBER_19
      , LAST_UPDATED_BY
      , ATTRIBUTE_CHAR_10
      , ATTRIBUTE_NUMBER_11_UOM
      , ATTRIBUTE_CHAR_16
      , ATTRIBUTE_NUMBER_20
      , VERSION_ID
      , ATTRIBUTE_CHAR_20
      , VERSION_END_DATE
      , PROGRAM_APP_NAME
      , ATTRIBUTE_TIMESTAMP_10
      , ATTRIBUTE_TIMESTAMP_4
      , ATTRIBUTE_NUMBER_9_UOM
      , ATTRIBUTE_TIMESTAMP_7
      , ATTRIBUTE_CHAR_32
      , ATTRIBUTE_CHAR_17
      , ATTRIBUTE_TIMESTAMP_5
      , ATTRIBUTE_NUMBER_5_UOM
      , ATTRIBUTE_DATE_5
      , ATTRIBUTE_NUMBER_6
      , REQUEST_ID
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE_CHAR_31
      , ATTRIBUTE_CHAR_21
      , ATTRIBUTE_NUMBER_13
      , CREATION_DATE
      , ATTRIBUTE_TIMESTAMP_3
      , ATTRIBUTE_NUMBER_3_UOM
      , ATTRIBUTE_NUMBER_13_UOM
      , ATTRIBUTE_NUMBER_15_UOM
      , ATTRIBUTE_CHAR_14
      , ATTRIBUTE_NUMBER_15
      , ATTRIBUTE_CHAR_3
      , ATTRIBUTE_CHAR_4
      , ATTRIBUTE_CHAR_19
      , ATTRIBUTE_DATE_8
      , OBJECT_VERSION_NUMBER
      , ATTRIBUTE_CHAR_40
      , ATTRIBUTE_NUMBER_12_UOM
      , ATTRIBUTE_DATE_9
      , ATTRIBUTE_CHAR_7
      , LAST_UPDATE_DATE
      , ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_TIMESTAMP_6
      , ATTRIBUTE_TIMESTAMP_1
      , ATTRIBUTE_CHAR_18
      , PROGRAM_NAME
      , ATTRIBUTE_NUMBER_8
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

, LOGIC_S2 as (
    SELECT
        ITEM_NUMBER
      , INVENTORY_ITEM_ID                                            as                               S2_INVENTORY_ITEM_ID
      , ORGANIZATION_ID                                              as                                 S2_ORGANIZATION_ID
    FROM SRC_S2
)
---- RENAME LAYER ----

, RENAME_S as (
    SELECT
        INVENTORY_ITEM_ID
      , ORGANIZATION_ID
      , EFF_LINE_ID
      , CHANGE_LINE_ID
      , VERSION_START_DATE
      , ATTRIBUTE_CHAR_25
      , ATTRIBUTE_NUMBER_2_UOM
      , ATTRIBUTE_CHAR_37
      , ATTRIBUTE_CHAR_39
      , ATTRIBUTE_CHAR_11
      , ATTRIBUTE_NUMBER_12
      , ATTRIBUTE_DATE_4
      , ATTRIBUTE_NUMBER_14
      , ATTRIBUTE_CHAR_24
      , ATTRIBUTE_DATE_3
      , ATTRIBUTE_NUMBER_18
      , ATTRIBUTE_CHAR_5
      , ATTRIBUTE_CHAR_12
      , ATTRIBUTE_NUMBER_20_UOM
      , ACD_TYPE
      , ATTRIBUTE_DATE_2
      , ATTRIBUTE_TIMESTAMP_2
      , ATTRIBUTE_CHAR_27
      , ATTRIBUTE_CHAR_13
      , ATTRIBUTE_NUMBER_16
      , ATTRIBUTE_NUMBER_2
      , ATTRIBUTE_NUMBER_7
      , ATTRIBUTE_CHAR_9
      , ATTRIBUTE_CHAR_30
      , ATTRIBUTE_NUMBER_18_UOM
      , ATTRIBUTE_NUMBER_10
      , ATTRIBUTE_CHAR_8
      , ATTRIBUTE_CHAR_15
      , ATTRIBUTE_CHAR_26
      , ATTRIBUTE_TIMESTAMP_9
      , ATTRIBUTE_CHAR_2
      , ATTRIBUTE_CHAR_29
      , CONTEXT_CODE
      , ATTRIBUTE_NUMBER_1_UOM
      , ATTRIBUTE_NUMBER_17_UOM
      , ATTRIBUTE_NUMBER_1
      , ATTRIBUTE_NUMBER_19_UOM
      , ATTRIBUTE_NUMBER_6_UOM
      , ATTRIBUTE_NUMBER_10_UOM
      , ATTRIBUTE_NUMBER_5
      , ATTRIBUTE_NUMBER_7_UOM
      , ATTRIBUTE_NUMBER_11
      , CATEGORY_CODE
      , ATTRIBUTE_NUMBER_14_UOM
      , IMPLEMENTATION_DATE
      , ATTRIBUTE_NUMBER_17
      , ATTRIBUTE_CHAR_33
      , ATTRIBUTE_DATE_10
      , ATTRIBUTE_NUMBER_8_UOM
      , ATTRIBUTE_CHAR_23
      , ATTRIBUTE_DATE_6
      , ATTRIBUTE_DATE_7
      , CHANGE_BIT_MAP
      , ATTRIBUTE_NUMBER_4_UOM
      , ATTRIBUTE_CHAR_1
      , ATTRIBUTE_CHAR_34
      , ATTRIBUTE_NUMBER_16_UOM
      , ATTRIBUTE_CHAR_28
      , ATTRIBUTE_NUMBER_3
      , ATTRIBUTE_CHAR_6
      , ATTRIBUTE_CHAR_22
      , ATTRIBUTE_CHAR_35
      , ATTRIBUTE_CHAR_36
      , CREATED_BY
      , ATTRIBUTE_NUMBER_9
      , ATTRIBUTE_CHAR_38
      , ATTRIBUTE_TIMESTAMP_8
      , ATTRIBUTE_DATE_1
      , ATTRIBUTE_NUMBER_19
      , LAST_UPDATED_BY
      , ATTRIBUTE_CHAR_10
      , ATTRIBUTE_NUMBER_11_UOM
      , ATTRIBUTE_CHAR_16
      , ATTRIBUTE_NUMBER_20
      , VERSION_ID
      , ATTRIBUTE_CHAR_20
      , VERSION_END_DATE
      , PROGRAM_APP_NAME
      , ATTRIBUTE_TIMESTAMP_10
      , ATTRIBUTE_TIMESTAMP_4
      , ATTRIBUTE_NUMBER_9_UOM
      , ATTRIBUTE_TIMESTAMP_7
      , ATTRIBUTE_CHAR_32
      , ATTRIBUTE_CHAR_17
      , ATTRIBUTE_TIMESTAMP_5
      , ATTRIBUTE_NUMBER_5_UOM
      , ATTRIBUTE_DATE_5
      , ATTRIBUTE_NUMBER_6
      , REQUEST_ID
      , LAST_UPDATE_LOGIN
      , ATTRIBUTE_CHAR_31
      , ATTRIBUTE_CHAR_21
      , ATTRIBUTE_NUMBER_13
      , CREATION_DATE
      , ATTRIBUTE_TIMESTAMP_3
      , ATTRIBUTE_NUMBER_3_UOM
      , ATTRIBUTE_NUMBER_13_UOM
      , ATTRIBUTE_NUMBER_15_UOM
      , ATTRIBUTE_CHAR_14
      , ATTRIBUTE_NUMBER_15
      , ATTRIBUTE_CHAR_3
      , ATTRIBUTE_CHAR_4
      , ATTRIBUTE_CHAR_19
      , ATTRIBUTE_DATE_8
      , OBJECT_VERSION_NUMBER
      , ATTRIBUTE_CHAR_40
      , ATTRIBUTE_NUMBER_12_UOM
      , ATTRIBUTE_DATE_9
      , ATTRIBUTE_CHAR_7
      , LAST_UPDATE_DATE
      , ATTRIBUTE_NUMBER_4
      , ATTRIBUTE_TIMESTAMP_6
      , ATTRIBUTE_TIMESTAMP_1
      , ATTRIBUTE_CHAR_18
      , PROGRAM_NAME
      , ATTRIBUTE_NUMBER_8
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

, RENAME_S2 as (
    SELECT
        ITEM_NUMBER
      , S2_INVENTORY_ITEM_ID
      , S2_ORGANIZATION_ID
    FROM LOGIC_S2
)
---- FILTER LAYER ----

, FILTER_S as (
    SELECT *
    FROM RENAME_S
)

, FILTER_A as (
    SELECT *
    FROM RENAME_A
    WHERE rec_src = 'USCLOUD.ORCL.OCFPRD.EGO_ITEM_EFF_B'
)

, FILTER_S2 as (
    SELECT *
    FROM RENAME_S2
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_S
    INNER JOIN FILTER_A
        ON '1' = '1'
    LEFT JOIN FILTER_S2
        ON organization_id = S2_organization_id
and inventory_item_id = S2_inventory_item_id
)

---- FINAL LAYER ----
SELECT
          coalesce(nullif(trim(ITEM_NUMBER), ''), '-1')                as ITEM_BK
        , INVENTORY_ITEM_ID
        , ORGANIZATION_ID
        , EFF_LINE_ID
        , CHANGE_LINE_ID
        , VERSION_START_DATE
        , ATTRIBUTE_CHAR_25
        , ATTRIBUTE_NUMBER_2_UOM
        , ATTRIBUTE_CHAR_37
        , ATTRIBUTE_CHAR_39
        , ATTRIBUTE_CHAR_11
        , ATTRIBUTE_NUMBER_12
        , ATTRIBUTE_DATE_4
        , ATTRIBUTE_NUMBER_14
        , ATTRIBUTE_CHAR_24
        , ATTRIBUTE_DATE_3
        , ATTRIBUTE_NUMBER_18
        , ATTRIBUTE_CHAR_5
        , ATTRIBUTE_CHAR_12
        , ATTRIBUTE_NUMBER_20_UOM
        , ACD_TYPE
        , ATTRIBUTE_DATE_2
        , ATTRIBUTE_TIMESTAMP_2
        , ATTRIBUTE_CHAR_27
        , ATTRIBUTE_CHAR_13
        , ATTRIBUTE_NUMBER_16
        , ATTRIBUTE_NUMBER_2
        , ATTRIBUTE_NUMBER_7
        , ATTRIBUTE_CHAR_9
        , ATTRIBUTE_CHAR_30
        , ATTRIBUTE_NUMBER_18_UOM
        , ATTRIBUTE_NUMBER_10
        , ATTRIBUTE_CHAR_8
        , ATTRIBUTE_CHAR_15
        , ATTRIBUTE_CHAR_26
        , ATTRIBUTE_TIMESTAMP_9
        , ATTRIBUTE_CHAR_2
        , ATTRIBUTE_CHAR_29
        , CONTEXT_CODE
        , ATTRIBUTE_NUMBER_1_UOM
        , ATTRIBUTE_NUMBER_17_UOM
        , ATTRIBUTE_NUMBER_1
        , ATTRIBUTE_NUMBER_19_UOM
        , ATTRIBUTE_NUMBER_6_UOM
        , ATTRIBUTE_NUMBER_10_UOM
        , ATTRIBUTE_NUMBER_5
        , ATTRIBUTE_NUMBER_7_UOM
        , ATTRIBUTE_NUMBER_11
        , CATEGORY_CODE
        , ATTRIBUTE_NUMBER_14_UOM
        , IMPLEMENTATION_DATE
        , ATTRIBUTE_NUMBER_17
        , ATTRIBUTE_CHAR_33
        , ATTRIBUTE_DATE_10
        , ATTRIBUTE_NUMBER_8_UOM
        , ATTRIBUTE_CHAR_23
        , ATTRIBUTE_DATE_6
        , ATTRIBUTE_DATE_7
        , CHANGE_BIT_MAP
        , ATTRIBUTE_NUMBER_4_UOM
        , ATTRIBUTE_CHAR_1
        , ATTRIBUTE_CHAR_34
        , ATTRIBUTE_NUMBER_16_UOM
        , ATTRIBUTE_CHAR_28
        , ATTRIBUTE_NUMBER_3
        , ATTRIBUTE_CHAR_6
        , ATTRIBUTE_CHAR_22
        , ATTRIBUTE_CHAR_35
        , ATTRIBUTE_CHAR_36
        , CREATED_BY
        , ATTRIBUTE_NUMBER_9
        , ATTRIBUTE_CHAR_38
        , ATTRIBUTE_TIMESTAMP_8
        , ATTRIBUTE_DATE_1
        , ATTRIBUTE_NUMBER_19
        , LAST_UPDATED_BY
        , ATTRIBUTE_CHAR_10
        , ATTRIBUTE_NUMBER_11_UOM
        , ATTRIBUTE_CHAR_16
        , ATTRIBUTE_NUMBER_20
        , VERSION_ID
        , ATTRIBUTE_CHAR_20
        , VERSION_END_DATE
        , PROGRAM_APP_NAME
        , ATTRIBUTE_TIMESTAMP_10
        , ATTRIBUTE_TIMESTAMP_4
        , ATTRIBUTE_NUMBER_9_UOM
        , ATTRIBUTE_TIMESTAMP_7
        , ATTRIBUTE_CHAR_32
        , ATTRIBUTE_CHAR_17
        , ATTRIBUTE_TIMESTAMP_5
        , ATTRIBUTE_NUMBER_5_UOM
        , ATTRIBUTE_DATE_5
        , ATTRIBUTE_NUMBER_6
        , REQUEST_ID
        , LAST_UPDATE_LOGIN
        , ATTRIBUTE_CHAR_31
        , ATTRIBUTE_CHAR_21
        , ATTRIBUTE_NUMBER_13
        , CREATION_DATE
        , ATTRIBUTE_TIMESTAMP_3
        , ATTRIBUTE_NUMBER_3_UOM
        , ATTRIBUTE_NUMBER_13_UOM
        , ATTRIBUTE_NUMBER_15_UOM
        , ATTRIBUTE_CHAR_14
        , ATTRIBUTE_NUMBER_15
        , ATTRIBUTE_CHAR_3
        , ATTRIBUTE_CHAR_4
        , ATTRIBUTE_CHAR_19
        , ATTRIBUTE_DATE_8
        , OBJECT_VERSION_NUMBER
        , ATTRIBUTE_CHAR_40
        , ATTRIBUTE_NUMBER_12_UOM
        , ATTRIBUTE_DATE_9
        , ATTRIBUTE_CHAR_7
        , LAST_UPDATE_DATE
        , ATTRIBUTE_NUMBER_4
        , ATTRIBUTE_TIMESTAMP_6
        , ATTRIBUTE_TIMESTAMP_1
        , ATTRIBUTE_CHAR_18
        , PROGRAM_NAME
        , ATTRIBUTE_NUMBER_8
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(INVENTORY_ITEM_ID::text), '^^') 
            , '||', IFNULL(TRIM(ORGANIZATION_ID::text), '^^') 
            , '||', IFNULL(TRIM(EFF_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_LINE_ID::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_START_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_25::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_37::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_39::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_11::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_24::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_18::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_12::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_20_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ACD_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_27::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_13::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_30::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_18_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_15::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_26::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_2::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_29::text), '^^') 
            , '||', IFNULL(TRIM(CONTEXT_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_17_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_19_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_6_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_10_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_7_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_11::text), '^^') 
            , '||', IFNULL(TRIM(CATEGORY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_14_UOM::text), '^^') 
            , '||', IFNULL(TRIM(IMPLEMENTATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_33::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_8_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_23::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_7::text), '^^') 
            , '||', IFNULL(TRIM(CHANGE_BIT_MAP::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_34::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_16_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_28::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_22::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_35::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_36::text), '^^') 
            , '||', IFNULL(TRIM(CREATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_38::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_8::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_19::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATED_BY::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_11_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_16::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_20::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_ID::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_20::text), '^^') 
            , '||', IFNULL(TRIM(VERSION_END_DATE::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_APP_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_10::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_9_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_7::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_32::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_17::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_5_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_5::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_6::text), '^^') 
            , '||', IFNULL(TRIM(REQUEST_ID::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_LOGIN::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_31::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_21::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_13::text), '^^') 
            , '||', IFNULL(TRIM(CREATION_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_3_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_13_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_15_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_14::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_15::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_3::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_19::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_8::text), '^^') 
            , '||', IFNULL(TRIM(OBJECT_VERSION_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_40::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_12_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_DATE_9::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_7::text), '^^') 
            , '||', IFNULL(TRIM(LAST_UPDATE_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_4::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_6::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_TIMESTAMP_1::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_CHAR_18::text), '^^') 
            , '||', IFNULL(TRIM(PROGRAM_NAME::text), '^^') 
            , '||', IFNULL(TRIM(ATTRIBUTE_NUMBER_8::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
