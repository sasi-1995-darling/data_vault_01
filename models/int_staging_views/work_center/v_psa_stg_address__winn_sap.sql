---- SRC LAYER ----
WITH
SRC_a              as ( SELECT ADDRESS_ID, ADDRNUMBER, ADDRORIGIN, ADDR_GROUP, ADRC_ERR_STATUS, ADRC_UUID, BUILDING, CHCKSTATUS, CITY1, CITY2, CITYH_CODE, CITYP_CODE, CITY_CODE, CITY_CODE2, CLIENT, COUNTRY, COUNTY, COUNTY_CODE, DATE_FROM, DATE_TO, DEFLT_COMM, DELI_SERV_NUMBER, DELI_SERV_TYPE, DONT_USE_P, DONT_USE_S, EXTENSION1, EXTENSION2, FAX_EXTENS, FAX_NUMBER, FLAGCOMM10, FLAGCOMM11, FLAGCOMM12, FLAGCOMM13, FLAGCOMM2, FLAGCOMM3, FLAGCOMM4, FLAGCOMM5, FLAGCOMM6, FLAGCOMM7, FLAGCOMM8, FLAGCOMM9, FLAGGROUPS, FLOOR, GLCHANGETIME, GLDELFLAG, GLREQUEST, GLSOURCESYSTEM, HOME_CITY, HOUSE_NUM1, HOUSE_NUM2, HOUSE_NUM3, ID_CATEGORY, LANGU, LANGU_CREA, LOCATION, MC_CITY1, MC_COUNTY, MC_NAME1, MC_STREET, MC_TOWNSHIP, NAME1, NAME2, NAME3, NAME4, NAME_CO, NAME_TEXT, NATION, PCODE1_EXT, PCODE2_EXT, PCODE3_EXT, PERS_ADDR, POSTALAREA, POST_CODE1, POST_CODE2, POST_CODE3, PO_BOX, PO_BOX_CTY, PO_BOX_LOBBY, PO_BOX_LOC, PO_BOX_NUM, PO_BOX_REG, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REGIOGROUP, REGION, ROOMNUMBER, SORT1, SORT2, SORT_PHN, STREET, STREETABBR, STREETCODE, STR_SUPPL1, STR_SUPPL2, STR_SUPPL3, TAXJURCODE, TEL_EXTENS, TEL_NUMBER, TIME_ZONE, TITLE, TOWNSHIP, TOWNSHIP_CODE, TRANSPZONE, UUID_BELATED, XPCPT FROM {{ source('sap_ecc_prd', 'z_adrc') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  )

/*
SRC_a              as ( SELECT * FROM sap_ecc_prd.z_adrc )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        ADDRNUMBER                                                   as                                         ADDRESS_BK
      , CLIENT
      , ADDRNUMBER
      , DATE_FROM
      , NATION
      , GLREQUEST
      , GLSOURCESYSTEM
      , DATE_TO
      , TITLE
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , NAME_TEXT
      , NAME_CO
      , CITY1
      , CITY2
      , CITY_CODE
      , CITYP_CODE
      , HOME_CITY
      , CITYH_CODE
      , CHCKSTATUS
      , REGIOGROUP
      , POST_CODE1
      , POST_CODE2
      , POST_CODE3
      , PCODE1_EXT
      , PCODE2_EXT
      , PCODE3_EXT
      , PO_BOX
      , DONT_USE_P
      , PO_BOX_NUM
      , PO_BOX_LOC
      , CITY_CODE2
      , PO_BOX_REG
      , PO_BOX_CTY
      , POSTALAREA
      , TRANSPZONE
      , STREET
      , DONT_USE_S
      , STREETCODE
      , STREETABBR
      , HOUSE_NUM1
      , HOUSE_NUM2
      , HOUSE_NUM3
      , STR_SUPPL1
      , STR_SUPPL2
      , STR_SUPPL3
      , LOCATION
      , BUILDING
      , FLOOR
      , ROOMNUMBER
      , COUNTRY
      , LANGU
      , REGION
      , ADDR_GROUP
      , FLAGGROUPS
      , PERS_ADDR
      , SORT1
      , SORT2
      , SORT_PHN
      , DEFLT_COMM
      , TEL_NUMBER
      , TEL_EXTENS
      , FAX_NUMBER
      , FAX_EXTENS
      , FLAGCOMM2
      , FLAGCOMM3
      , FLAGCOMM4
      , FLAGCOMM5
      , FLAGCOMM6
      , FLAGCOMM7
      , FLAGCOMM8
      , FLAGCOMM9
      , FLAGCOMM10
      , FLAGCOMM11
      , FLAGCOMM12
      , FLAGCOMM13
      , ADDRORIGIN
      , MC_NAME1
      , MC_CITY1
      , MC_STREET
      , EXTENSION1
      , EXTENSION2
      , TIME_ZONE
      , TAXJURCODE
      , ADDRESS_ID
      , LANGU_CREA
      , ADRC_UUID
      , UUID_BELATED
      , ID_CATEGORY
      , ADRC_ERR_STATUS
      , PO_BOX_LOBBY
      , DELI_SERV_TYPE
      , DELI_SERV_NUMBER
      , COUNTY_CODE
      , COUNTY
      , TOWNSHIP_CODE
      , TOWNSHIP
      , MC_COUNTY
      , MC_TOWNSHIP
      , XPCPT
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE('UTC', TO_TIMESTAMP(
            SUBSTR(GLCHANGETIME, 1, 8) || ' ' ||
            SUBSTR(GLCHANGETIME, 9, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 11, 2) || ':' ||
            SUBSTR(GLCHANGETIME, 13, 2) || '.' ||
            REGEXP_REPLACE(SUBSTR(GLCHANGETIME, 16), '^\\.', ''),
            'YYYYMMDD HH24:MI:SS.FF9'
            ))
        )                                                            as                                           LOAD_DTS
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
        ADDRESS_BK
      , CLIENT
      , ADDRNUMBER
      , DATE_FROM
      , NATION
      , GLREQUEST
      , GLSOURCESYSTEM
      , DATE_TO
      , TITLE
      , NAME1
      , NAME2
      , NAME3
      , NAME4
      , NAME_TEXT
      , NAME_CO
      , CITY1
      , CITY2
      , CITY_CODE
      , CITYP_CODE
      , HOME_CITY
      , CITYH_CODE
      , CHCKSTATUS
      , REGIOGROUP
      , POST_CODE1
      , POST_CODE2
      , POST_CODE3
      , PCODE1_EXT
      , PCODE2_EXT
      , PCODE3_EXT
      , PO_BOX
      , DONT_USE_P
      , PO_BOX_NUM
      , PO_BOX_LOC
      , CITY_CODE2
      , PO_BOX_REG
      , PO_BOX_CTY
      , POSTALAREA
      , TRANSPZONE
      , STREET
      , DONT_USE_S
      , STREETCODE
      , STREETABBR
      , HOUSE_NUM1
      , HOUSE_NUM2
      , HOUSE_NUM3
      , STR_SUPPL1
      , STR_SUPPL2
      , STR_SUPPL3
      , LOCATION
      , BUILDING
      , FLOOR
      , ROOMNUMBER
      , COUNTRY
      , LANGU
      , REGION
      , ADDR_GROUP
      , FLAGGROUPS
      , PERS_ADDR
      , SORT1
      , SORT2
      , SORT_PHN
      , DEFLT_COMM
      , TEL_NUMBER
      , TEL_EXTENS
      , FAX_NUMBER
      , FAX_EXTENS
      , FLAGCOMM2
      , FLAGCOMM3
      , FLAGCOMM4
      , FLAGCOMM5
      , FLAGCOMM6
      , FLAGCOMM7
      , FLAGCOMM8
      , FLAGCOMM9
      , FLAGCOMM10
      , FLAGCOMM11
      , FLAGCOMM12
      , FLAGCOMM13
      , ADDRORIGIN
      , MC_NAME1
      , MC_CITY1
      , MC_STREET
      , EXTENSION1
      , EXTENSION2
      , TIME_ZONE
      , TAXJURCODE
      , ADDRESS_ID
      , LANGU_CREA
      , ADRC_UUID
      , UUID_BELATED
      , ID_CATEGORY
      , ADRC_ERR_STATUS
      , PO_BOX_LOBBY
      , DELI_SERV_TYPE
      , DELI_SERV_NUMBER
      , COUNTY_CODE
      , COUNTY
      , TOWNSHIP_CODE
      , TOWNSHIP
      , MC_COUNTY
      , MC_TOWNSHIP
      , XPCPT
      , GLDELFLAG
      , GLCHANGETIME
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
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_ADRC'
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
          ADDRESS_BK
        , CLIENT
        , ADDRNUMBER
        , DATE_FROM
        , NATION
        , GLREQUEST
        , GLSOURCESYSTEM
        , DATE_TO
        , TITLE
        , NAME1
        , NAME2
        , NAME3
        , NAME4
        , NAME_TEXT
        , NAME_CO
        , CITY1
        , CITY2
        , CITY_CODE
        , CITYP_CODE
        , HOME_CITY
        , CITYH_CODE
        , CHCKSTATUS
        , REGIOGROUP
        , POST_CODE1
        , POST_CODE2
        , POST_CODE3
        , PCODE1_EXT
        , PCODE2_EXT
        , PCODE3_EXT
        , PO_BOX
        , DONT_USE_P
        , PO_BOX_NUM
        , PO_BOX_LOC
        , CITY_CODE2
        , PO_BOX_REG
        , PO_BOX_CTY
        , POSTALAREA
        , TRANSPZONE
        , STREET
        , DONT_USE_S
        , STREETCODE
        , STREETABBR
        , HOUSE_NUM1
        , HOUSE_NUM2
        , HOUSE_NUM3
        , STR_SUPPL1
        , STR_SUPPL2
        , STR_SUPPL3
        , LOCATION
        , BUILDING
        , FLOOR
        , ROOMNUMBER
        , COUNTRY
        , LANGU
        , REGION
        , ADDR_GROUP
        , FLAGGROUPS
        , PERS_ADDR
        , SORT1
        , SORT2
        , SORT_PHN
        , DEFLT_COMM
        , TEL_NUMBER
        , TEL_EXTENS
        , FAX_NUMBER
        , FAX_EXTENS
        , FLAGCOMM2
        , FLAGCOMM3
        , FLAGCOMM4
        , FLAGCOMM5
        , FLAGCOMM6
        , FLAGCOMM7
        , FLAGCOMM8
        , FLAGCOMM9
        , FLAGCOMM10
        , FLAGCOMM11
        , FLAGCOMM12
        , FLAGCOMM13
        , ADDRORIGIN
        , MC_NAME1
        , MC_CITY1
        , MC_STREET
        , EXTENSION1
        , EXTENSION2
        , TIME_ZONE
        , TAXJURCODE
        , ADDRESS_ID
        , LANGU_CREA
        , ADRC_UUID
        , UUID_BELATED
        , ID_CATEGORY
        , ADRC_ERR_STATUS
        , PO_BOX_LOBBY
        , DELI_SERV_TYPE
        , DELI_SERV_NUMBER
        , COUNTY_CODE
        , COUNTY
        , TOWNSHIP_CODE
        , TOWNSHIP
        , MC_COUNTY
        , MC_TOWNSHIP
        , XPCPT
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ADDRNUMBER as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ADDRESS_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(CLIENT::text), '^^') 
            , '||', IFNULL(TRIM(DATE_FROM::text), '^^') 
            , '||', IFNULL(TRIM(NATION::text), '^^') 
            , '||', IFNULL(TRIM(DATE_TO::text), '^^') 
            , '||', IFNULL(TRIM(TITLE::text), '^^') 
            , '||', IFNULL(TRIM(NAME1::text), '^^') 
            , '||', IFNULL(TRIM(NAME2::text), '^^') 
            , '||', IFNULL(TRIM(NAME3::text), '^^') 
            , '||', IFNULL(TRIM(NAME4::text), '^^') 
            , '||', IFNULL(TRIM(NAME_TEXT::text), '^^') 
            , '||', IFNULL(TRIM(NAME_CO::text), '^^') 
            , '||', IFNULL(TRIM(CITY1::text), '^^') 
            , '||', IFNULL(TRIM(CITY2::text), '^^') 
            , '||', IFNULL(TRIM(CITY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CITYP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(HOME_CITY::text), '^^') 
            , '||', IFNULL(TRIM(CITYH_CODE::text), '^^') 
            , '||', IFNULL(TRIM(CHCKSTATUS::text), '^^') 
            , '||', IFNULL(TRIM(REGIOGROUP::text), '^^') 
            , '||', IFNULL(TRIM(POST_CODE1::text), '^^') 
            , '||', IFNULL(TRIM(POST_CODE2::text), '^^') 
            , '||', IFNULL(TRIM(POST_CODE3::text), '^^') 
            , '||', IFNULL(TRIM(PCODE1_EXT::text), '^^') 
            , '||', IFNULL(TRIM(PCODE2_EXT::text), '^^') 
            , '||', IFNULL(TRIM(PCODE3_EXT::text), '^^') 
            , '||', IFNULL(TRIM(PO_BOX::text), '^^') 
            , '||', IFNULL(TRIM(DONT_USE_P::text), '^^') 
            , '||', IFNULL(TRIM(PO_BOX_NUM::text), '^^') 
            , '||', IFNULL(TRIM(PO_BOX_LOC::text), '^^') 
            , '||', IFNULL(TRIM(CITY_CODE2::text), '^^') 
            , '||', IFNULL(TRIM(PO_BOX_REG::text), '^^') 
            , '||', IFNULL(TRIM(PO_BOX_CTY::text), '^^') 
            , '||', IFNULL(TRIM(POSTALAREA::text), '^^') 
            , '||', IFNULL(TRIM(TRANSPZONE::text), '^^') 
            , '||', IFNULL(TRIM(STREET::text), '^^') 
            , '||', IFNULL(TRIM(DONT_USE_S::text), '^^') 
            , '||', IFNULL(TRIM(STREETCODE::text), '^^') 
            , '||', IFNULL(TRIM(STREETABBR::text), '^^') 
            , '||', IFNULL(TRIM(HOUSE_NUM1::text), '^^') 
            , '||', IFNULL(TRIM(HOUSE_NUM2::text), '^^') 
            , '||', IFNULL(TRIM(HOUSE_NUM3::text), '^^') 
            , '||', IFNULL(TRIM(STR_SUPPL1::text), '^^') 
            , '||', IFNULL(TRIM(STR_SUPPL2::text), '^^') 
            , '||', IFNULL(TRIM(STR_SUPPL3::text), '^^') 
            , '||', IFNULL(TRIM(LOCATION::text), '^^') 
            , '||', IFNULL(TRIM(BUILDING::text), '^^') 
            , '||', IFNULL(TRIM(FLOOR::text), '^^') 
            , '||', IFNULL(TRIM(ROOMNUMBER::text), '^^') 
            , '||', IFNULL(TRIM(COUNTRY::text), '^^') 
            , '||', IFNULL(TRIM(LANGU::text), '^^') 
            , '||', IFNULL(TRIM(REGION::text), '^^') 
            , '||', IFNULL(TRIM(ADDR_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(FLAGGROUPS::text), '^^') 
            , '||', IFNULL(TRIM(PERS_ADDR::text), '^^') 
            , '||', IFNULL(TRIM(SORT1::text), '^^') 
            , '||', IFNULL(TRIM(SORT2::text), '^^') 
            , '||', IFNULL(TRIM(SORT_PHN::text), '^^') 
            , '||', IFNULL(TRIM(DEFLT_COMM::text), '^^') 
            , '||', IFNULL(TRIM(TEL_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(TEL_EXTENS::text), '^^') 
            , '||', IFNULL(TRIM(FAX_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(FAX_EXTENS::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM2::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM3::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM4::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM5::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM6::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM7::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM8::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM9::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM10::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM11::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM12::text), '^^') 
            , '||', IFNULL(TRIM(FLAGCOMM13::text), '^^') 
            , '||', IFNULL(TRIM(ADDRORIGIN::text), '^^') 
            , '||', IFNULL(TRIM(MC_NAME1::text), '^^') 
            , '||', IFNULL(TRIM(MC_CITY1::text), '^^') 
            , '||', IFNULL(TRIM(MC_STREET::text), '^^') 
            , '||', IFNULL(TRIM(EXTENSION1::text), '^^') 
            , '||', IFNULL(TRIM(EXTENSION2::text), '^^') 
            , '||', IFNULL(TRIM(TIME_ZONE::text), '^^') 
            , '||', IFNULL(TRIM(TAXJURCODE::text), '^^') 
            , '||', IFNULL(TRIM(ADDRESS_ID::text), '^^') 
            , '||', IFNULL(TRIM(LANGU_CREA::text), '^^') 
            , '||', IFNULL(TRIM(ADRC_UUID::text), '^^') 
            , '||', IFNULL(TRIM(UUID_BELATED::text), '^^') 
            , '||', IFNULL(TRIM(ID_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(ADRC_ERR_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(PO_BOX_LOBBY::text), '^^') 
            , '||', IFNULL(TRIM(DELI_SERV_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(DELI_SERV_NUMBER::text), '^^') 
            , '||', IFNULL(TRIM(COUNTY_CODE::text), '^^') 
            , '||', IFNULL(TRIM(COUNTY::text), '^^') 
            , '||', IFNULL(TRIM(TOWNSHIP_CODE::text), '^^') 
            , '||', IFNULL(TRIM(TOWNSHIP::text), '^^') 
            , '||', IFNULL(TRIM(MC_COUNTY::text), '^^') 
            , '||', IFNULL(TRIM(MC_TOWNSHIP::text), '^^') 
            , '||', IFNULL(TRIM(XPCPT::text), '^^') 
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
