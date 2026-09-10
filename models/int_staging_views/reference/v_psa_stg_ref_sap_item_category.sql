---- SRC LAYER ----
WITH
SRC_A              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_mara') }} as SRC  
                qualify 1 = row_number()over (partition by ZZBASE_MATNR,MATNR order by psa_load_dts )),
SRC_B              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_makt') }} as SRC 
                qualify 1 = row_number()over (partition by MATNR,SPRAS order by psa_load_dts )) ,
SRC_C              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zrmareat') }} as SRC
                qualify 1 = row_number()over (partition by ZZRMAREA,SPRAS order by psa_load_dts )),
SRC_D              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zrepcatgt') }} as SRC  
                qualify 1 = row_number()over (partition by ZZREPCATG order by psa_load_dts )),
SRC_E              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zptgkt') }} as SRC 
                qualify 1 = row_number()over (partition by zzptgk,SPRAS order by psa_load_dts )),
SRC_F              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zptgt') }} as SRC 
                qualify 1 = row_number()over (partition by zzptg,SPRAS order by psa_load_dts )),
SRC_G              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zpltt') }} as SRC
                qualify 1 = row_number()over (partition by zzplt,SPRAS order by psa_load_dts )),
SRC_H              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zpdtpt') }} as SRC
                qualify 1 = row_number()over (partition by zzdtp,SPRAS order by psa_load_dts )),
SRC_I              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zarcht') }} as SRC
                qualify 1 = row_number()over (partition by zzarch,SPRAS order by psa_load_dts )),
SRC_J              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zarchdett') }} as SRC
                qualify 1 = row_number()over (partition by zzarchdet,SPRAS order by psa_load_dts )),
SRC_K              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zplint') }} as SRC
                qualify 1 = row_number()over (partition by zzlin,SPRAS order by psa_load_dts )),
SRC_L              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_zbrandtab') }} as SRC
                qualify 1 = row_number()over (partition by zzbrand order by psa_load_dts )),
SRC_M              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_ausp') }} as SRC 
                qualify 1 = row_number()over (partition by objek,ATINN order by psa_load_dts )),
SRC_N              as ( SELECT * FROM {{ source('sap_ecc_prd', 'z_ausp') }} as SRC
                qualify 1 = row_number()over (partition by objek,ATINN order by psa_load_dts )),
SRC_bk             as ( SELECT * FROM {{ ref('ref_business_key_collision') }} as SRC)

/*
SRC_A              as ( SELECT * FROM sap_ecc_prd.z_mara )
, SRC_B              as ( SELECT * FROM sap_ecc_prd.z_makt )
, SRC_C              as ( SELECT * FROM sap_ecc_prd.z_zrmareat )
, SRC_D              as ( SELECT * FROM sap_ecc_prd.z_zrepcatgt )
, SRC_E              as ( SELECT * FROM sap_ecc_prd.z_zptgkt )
, SRC_F              as ( SELECT * FROM sap_ecc_prd.z_zptgt )
, SRC_G              as ( SELECT * FROM sap_ecc_prd.z_zpltt )
, SRC_H              as ( SELECT * FROM sap_ecc_prd.z_zpdtpt )
, SRC_I              as ( SELECT * FROM sap_ecc_prd.z_zarcht )
, SRC_J              as ( SELECT * FROM sap_ecc_prd.z_zarchdett )
, SRC_K              as ( SELECT * FROM sap_ecc_prd.z_zplint )
, SRC_L              as ( SELECT * FROM sap_ecc_prd.z_zbrandtab )
, SRC_M              as ( SELECT * FROM sap_ecc_prd.z_ausp )
, SRC_N              as ( SELECT * FROM sap_ecc_prd.z_ausp )
, SRC_bk             as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_A as (
    SELECT
        ZZFCST_BASE                                                  as                                  FORECAST_MATERIAL
      , ZZBASE_MATNR                                                 as                                       MATERIAL_KEY
      , MATNR
      , ZZRMAREA
      , ZZREPCATG
      , ZZPTGK
      , ZZPTG
      , ZZPLT
      , ZZDTP
      , ZZARCH
      , ZZARCHDET
      , ZZLIN
      , ZZBRAND
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
    FROM SRC_A
)

, LOGIC_B as (
    SELECT
        MATNR
      , MAKTX                                                        as                                        DESCRIPTION
      , SPRAS
    FROM SRC_B
)

, LOGIC_C as (
    SELECT
        ZZRMAREA
      , TXT30                                                        as                                               AREA
      , SPRAS
    FROM SRC_C
)

, LOGIC_D as (
    SELECT
        ZZREPCATG
      , ZZREPCATGD                                                   as                                 REPORTING_CATEGORY
    FROM SRC_D
)

, LOGIC_E as (
    SELECT
        ZZPTGK
      , TXT30                                                        as                                      PRODUCT_GROUP
      , SPRAS
    FROM SRC_E
)

, LOGIC_F as (
    SELECT
        ZZPTG
      , TXT30                                                        as                                   PRICE_TYPE_GROUP
      , SPRAS
    FROM SRC_F
)

, LOGIC_G as (
    SELECT
        ZZPLT
      , TXT30                                                        as                                           PLATFORM
      , SPRAS
    FROM SRC_G
)

, LOGIC_H as (
    SELECT
        ZZDTP
      , TXT30                                                        as                                       PRODUCT_TYPE
      , SPRAS
    FROM SRC_H
)

, LOGIC_I as (
    SELECT
        ZZARCH
      , TXT30                                                        as                                       ARCHITECTURE
      , SPRAS
    FROM SRC_I
)

, LOGIC_J as (
    SELECT
        ZZARCHDET
      , TXT30                                                        as                                ARCHITECTURE_DETAIL
      , SPRAS
    FROM SRC_J
)

, LOGIC_K as (
    SELECT
        ZZLIN
      , TXT30                                                        as                                       PRODUCT_LINE
      , SPRAS
    FROM SRC_K
)

, LOGIC_L as (
    SELECT
        ZZBRAND
      , ZZBRANDD                                                     as                                         MARA_BRAND
    FROM SRC_L
)

, LOGIC_M as (
    SELECT
        OBJEK
      , ATWRT                                                        as                                          GPG_BRAND
      , ATINN
    FROM SRC_M
)

, LOGIC_N as (
    SELECT
        OBJEK
      , ATWRT                                                        as                           PRIMARY_CONTENT_MATERIAL
      , ATINN
    FROM SRC_N
)

, LOGIC_bk as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bk
)
---- RENAME LAYER ----

, RENAME_A as (
    SELECT
        FORECAST_MATERIAL
      , MATERIAL_KEY
      , MATNR
      , ZZRMAREA
      , ZZREPCATG
      , ZZPTGK
      , ZZPTG
      , ZZPLT
      , ZZDTP   
      , ZZARCH
      , ZZARCHDET
      , ZZLIN
      , ZZBRAND
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
    FROM LOGIC_A
)

, RENAME_B as (
    SELECT
        MATNR
      , DESCRIPTION
      , SPRAS
    FROM LOGIC_B
)

, RENAME_C as (
    SELECT
        ZZRMAREA
      , AREA
      , SPRAS
    FROM LOGIC_C
)

, RENAME_D as (
    SELECT
        ZZREPCATG
      , REPORTING_CATEGORY
    FROM LOGIC_D
)

, RENAME_E as (
    SELECT
        ZZPTGK
      , PRODUCT_GROUP
      , SPRAS
    FROM LOGIC_E
)

, RENAME_F as (
    SELECT
        ZZPTG
      , PRICE_TYPE_GROUP
      , SPRAS
    FROM LOGIC_F
)

, RENAME_G as (
    SELECT
        ZZPLT
      , PLATFORM
      , SPRAS
    FROM LOGIC_G
)

, RENAME_H as (
    SELECT
        ZZDTP   
      , PRODUCT_TYPE
      , SPRAS
    FROM LOGIC_H
)

, RENAME_I as (
    SELECT
        ZZARCH
      , ARCHITECTURE
      , SPRAS
    FROM LOGIC_I
)

, RENAME_J as (
    SELECT
        ZZARCHDET
      , ARCHITECTURE_DETAIL
      , SPRAS
    FROM LOGIC_J
)

, RENAME_K as (
    SELECT
        ZZLIN
      , PRODUCT_LINE
      , SPRAS
    FROM LOGIC_K
)

, RENAME_L as (
    SELECT
        ZZBRAND
      , MARA_BRAND
    FROM LOGIC_L
)

, RENAME_M as (
    SELECT
        OBJEK
      , GPG_BRAND
      , ATINN
    FROM LOGIC_M
)

, RENAME_N as (
    SELECT
        OBJEK
      , PRIMARY_CONTENT_MATERIAL
      , ATINN
    FROM LOGIC_N
)

, RENAME_bk as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bk
)
---- FILTER LAYER ----

, FILTER_A as (
    SELECT *
    FROM RENAME_A
)

, FILTER_B as (
    SELECT *
    FROM RENAME_B
    WHERE RENAME_B.SPRAS = 'E' 
)

, FILTER_C as (
    SELECT *
    FROM RENAME_C
    WHERE RENAME_C.SPRAS ='E'
)

, FILTER_D as (
    SELECT *
    FROM RENAME_D
)

, FILTER_E as (
    SELECT *
    FROM RENAME_E
    WHERE RENAME_E.SPRAS ='E'
)

, FILTER_F as (
    SELECT *
    FROM RENAME_F
    WHERE RENAME_F.SPRAS ='E'
)

, FILTER_G as (
    SELECT *
    FROM RENAME_G
    WHERE RENAME_G.SPRAS='E'
)

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE RENAME_H.SPRAS='E'
)

, FILTER_I as (
    SELECT *
    FROM RENAME_I
    WHERE RENAME_I.SPRAS='E'
)

, FILTER_J as (
    SELECT *
    FROM RENAME_J
    WHERE RENAME_J.SPRAS='E'
)

, FILTER_K as (
    SELECT *
    FROM RENAME_K
    WHERE RENAME_K.SPRAS='E'
)

, FILTER_L as (
    SELECT *
    FROM RENAME_L
)

, FILTER_M as (
    SELECT *
    FROM RENAME_M
    WHERE RENAME_M.ATINN= '0000001647'
)

, FILTER_N as (
    SELECT *
    FROM RENAME_N
    WHERE RENAME_N.ATINN= '0000001647'
)

, FILTER_bk as (
    SELECT *
    FROM RENAME_bk
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_MARA'
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_A
    LEFT JOIN FILTER_B
        ON FILTER_A.MATNR = FILTER_B.MATNR
    LEFT JOIN FILTER_C
        ON FILTER_A.ZZRMAREA = FILTER_C.ZZRMAREA
    LEFT JOIN FILTER_D
        ON FILTER_A.ZZREPCATG = FILTER_D.ZZREPCATG
    LEFT JOIN FILTER_E
        ON FILTER_A.ZZPTGK = FILTER_E.ZZPTGK
    LEFT JOIN FILTER_F
        ON FILTER_A.ZZPTG = FILTER_F.ZZPTG
    LEFT JOIN FILTER_G
        ON FILTER_A.ZZPLT = FILTER_G.ZZPLT
    LEFT JOIN FILTER_H
        ON FILTER_A.ZZDTP = FILTER_H.ZZDTP
    LEFT JOIN FILTER_I
        ON FILTER_A.ZZARCH = FILTER_I.ZZARCH
    LEFT JOIN FILTER_J
        ON FILTER_A.ZZARCHDET = FILTER_J.ZZARCHDET
    LEFT JOIN FILTER_K
        ON FILTER_A.ZZLIN = FILTER_K.ZZLIN
    LEFT JOIN FILTER_L
        ON FILTER_A.ZZBRAND = FILTER_L.ZZBRAND
    LEFT JOIN FILTER_M
        ON FILTER_A.MATNR = FILTER_M.OBJEK
    LEFT JOIN FILTER_N
        ON FILTER_A.MATNR = FILTER_N.OBJEK
    INNER JOIN FILTER_bk
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          FORECAST_MATERIAL
        , MATERIAL_KEY
        , DESCRIPTION
        , AREA
        , REPORTING_CATEGORY
        , PRODUCT_GROUP
        , PRICE_TYPE_GROUP
        , PLATFORM
        , PRODUCT_TYPE
        , ARCHITECTURE
        , ARCHITECTURE_DETAIL
        , PRODUCT_LINE
        , MARA_BRAND
        , GPG_BRAND
        , PRIMARY_CONTENT_MATERIAL
        , REC_SRC
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
)) as LOAD_DTS
        , BKCC
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(FORECAST_MATERIAL::text), '^^') 
            , '||', IFNULL(TRIM(MATERIAL_KEY::text), '^^') 
            , '||', IFNULL(TRIM(DESCRIPTION::text), '^^') 
            , '||', IFNULL(TRIM(AREA::text), '^^') 
            , '||', IFNULL(TRIM(REPORTING_CATEGORY::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(PRICE_TYPE_GROUP::text), '^^') 
            , '||', IFNULL(TRIM(PLATFORM::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ARCHITECTURE::text), '^^') 
            , '||', IFNULL(TRIM(ARCHITECTURE_DETAIL::text), '^^') 
            , '||', IFNULL(TRIM(PRODUCT_LINE::text), '^^') 
            , '||', IFNULL(TRIM(MARA_BRAND::text), '^^') 
            , '||', IFNULL(TRIM(GPG_BRAND::text), '^^') 
            , '||', IFNULL(TRIM(PRIMARY_CONTENT_MATERIAL::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
