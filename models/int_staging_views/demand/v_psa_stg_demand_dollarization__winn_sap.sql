---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('sap_bw_prd', 'z_zfcdadso') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC
                        WHERE rec_src = 'USOHNO.SAP_BW.Z_ZFCDADSO' ),
SRC_mara           as ( 
                        SELECT  -- Ranking logic: prioritizing cleaner MATNRs and active statuses
                        zzfcst_base, 
                        MATNR,
                        row_number() over (
                            partition by zzfcst_base 
                            order by 
                                CASE WHEN MATNR LIKE '%-%' THEN 2 ELSE 1 END, 
                                CASE WHEN mstae IN ('Z8', 'ZP', 'Z7','Z6','ZN','05','Z1','Z2','Z3','Z5') THEN 2 ELSE 1 END,
                                CASE WHEN zzproductvitality in ('NOTN','NP') THEN 2 ELSE 1 END, 
                                ersda desc
                        ) as rn
                    FROM {{ source('sap_ecc_prd', 'z_mara') }})

/*
SRC_SRC            as ( SELECT * FROM sap_bw_prd.ZFCDADSO )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_mara           as ( SELECT * FROM sap_ecc_prd.z_mara )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        FISCPER
      , FISCPER3
      , SALESORG
      , coalesce(nullif(trim(SALESORG), ''), '-1')                                           as SALES_ORGANIZATION_BK
      , DISTR_CHAN
      , coalesce(nullif(trim(DISTR_CHAN), ''), '-1')                                         as DISTRIBUTION_CHANNEL_BK
      , DIVISION
      , coalesce(nullif(trim(DIVISION), ''), '-1')                                           as DIVISION_BK
      , PLANT
      , coalesce(nullif(trim(PLANT), ''), '-1')                                              as PLANT_BK
      , MATERIAL
      , MAT_PLANT
      , "/BIC/ZZAPOACCT"                                                                     as BIC_ZZAPOACCT
      , coalesce(nullif(trim("/BIC/ZZAPOACCT"), ''), '-1')                                   as FORECAST_CUSTOMER_GROUP_BK
      , "/BIC/ZZPLANPER"                                                                     as BIC_ZZPLANPER
      , coalesce(nullif(TO_CHAR(TRY_TO_DATE("/BIC/ZZPLANPER", 'MONYY'), 'YYYYMM'), ''), '-1') as FORECASTING_PLAN_PERIOD_BK
      , "/BIC/ZACCTMATL"                                                                     as BIC_ZACCTMATL
      , "/BIC/ZFQUARTER"                                                                     as BIC_ZFQUARTER
      , "/BIC/ZQUARTER"                                                                      as BIC_ZQUARTER
      , "/BIC/WWRSN"                                                                         as BIC_WWRSN
      , DEALTYPE
      , "/BIC/ZRATE_VR"                                                                      as BIC_ZRATE_VR
      , GLREQUEST
      , FISCVARNT
      , FISCYEAR
      , BASE_UOM
      , coalesce(nullif(trim(BASE_UOM), ''), '-1')                                           as UOM_BK
      , CURRENCY
      , "/BIC/ZWFBILLED"                                                                     as BIC_ZWFBILLED
      , "/BIC/ZWFNOCHRG"                                                                     as BIC_ZWFNOCHRG
      , "/BIC/ZWFGRSOID"                                                                     as BIC_ZWFGRSOID
      , "/BIC/ZFCBILLED"                                                                     as BIC_ZFCBILLED
      , "/BIC/ZFCLISTCY"                                                                     as BIC_ZFCLISTCY
      , "/BIC/ZFCLISTPY"                                                                     as BIC_ZFCLISTPY
      , "/BIC/ZFCNOCHRG"                                                                     as BIC_ZFCNOCHRG
      , "/BIC/ZFCINDGRS"                                                                     as BIC_ZFCINDGRS
      , "/BIC/ZFCIGSPY"                                                                      as BIC_ZFCIGSPY
      , "/BIC/ZFCGRSFRT"                                                                     as BIC_ZFCGRSFRT
      , "/BIC/ZFCGRSFPY"                                                                     as BIC_ZFCGRSFPY
      , "/BIC/ZFCPRCDIS"                                                                     as BIC_ZFCPRCDIS
      , "/BIC/ZFCPRCDPY"                                                                     as BIC_ZFCPRCDPY
      , "/BIC/ZFCGRSOID"                                                                     as BIC_ZFCGRSOID
      , "/BIC/ZCHGRSOID"                                                                     as BIC_ZCHGRSOID
      , "/BIC/ZPRCLOSDL"                                                                     as BIC_ZPRCLOSDL
      , "/BIC/ZFCSTOID"                                                                      as BIC_ZFCSTOID
      , "/BIC/ZFCFRT"                                                                        as BIC_ZFCFRT
      , "/BIC/ZFCRETALW"                                                                     as BIC_ZFCRETALW
      , "/BIC/ZFCCSHDIS"                                                                     as BIC_ZFCCSHDIS
      , "/BIC/ZFCVRBCUS"                                                                     as BIC_ZFCVRBCUS
      , "/BIC/ZFCVRBFLT"                                                                     as BIC_ZFCVRBFLT
      , "/BIC/ZFCVRBTLD"                                                                     as BIC_ZFCVRBTLD
      , "/BIC/ZFCVRBCSH"                                                                     as BIC_ZFCVRBCSH
      , "/BIC/ZFCVRBPAR"                                                                     as BIC_ZFCVRBPAR
      , "/BIC/ZFCVRBPLM"                                                                     as BIC_ZFCVRBPLM
      , "/BIC/ZFCVRBSHW"                                                                     as BIC_ZFCVRBSHW
      , "/BIC/ZFCVRBOTH"                                                                     as BIC_ZFCVRBOTH
      , "/BIC/ZFCFIXBSF"                                                                     as BIC_ZFCFIXBSF
      , "/BIC/ZFCFIXNSF"                                                                     as BIC_ZFCFIXNSF
      , "/BIC/ZFCFIXPRP"                                                                     as BIC_ZFCFIXPRP
      , "/BIC/ZFCFIXCCF"                                                                     as BIC_ZFCFIXCCF
      , "/BIC/ZFCFIXCCA"                                                                     as BIC_ZFCFIXCCA
      , "/BIC/ZFCFIXCPP"                                                                     as BIC_ZFCFIXCPP
      , "/BIC/ZOTHREBF"                                                                      as BIC_ZOTHREBF
      , "/BIC/ZFCSTDCST"                                                                     as BIC_ZFCSTDCST
      , "/BIC/ZFCCURCST"                                                                     as BIC_ZFCCURCST
      , "/BIC/ZMSCOS"                                                                        as BIC_ZMSCOS
      , "/BIC/ZDFSCOS"                                                                       as BIC_ZDFSCOS
      , "/BIC/ZFOSCOS"                                                                       as BIC_ZFOSCOS
      , "/BIC/ZVOSCOS"                                                                       as BIC_ZVOSCOS
      , "/BIC/ZNOCHRGDI"                                                                     as BIC_ZNOCHRGDI
      , "/BIC/ZFRTDISC"                                                                      as BIC_ZFRTDISC
      , "/BIC/ZOIDDISC"                                                                      as BIC_ZOIDDISC
      , "/BIC/ZRETSDISC"                                                                     as BIC_ZRETSDISC
      , "/BIC/ZCSHDISC"                                                                      as BIC_ZCSHDISC
      , "/BIC/ZCUSREBV"                                                                      as BIC_ZCUSREBV
      , "/BIC/ZCUSREFTV"                                                                     as BIC_ZCUSREFTV
      , "/BIC/ZTRKLDRBV"                                                                     as BIC_ZTRKLDRBV
      , "/BIC/ZCUSCDRBV"                                                                     as BIC_ZCUSCDRBV
      , "/BIC/ZCUSPRRBV"                                                                     as BIC_ZCUSPRRBV
      , "/BIC/ZPLUREBV"                                                                      as BIC_ZPLUREBV
      , "/BIC/ZSHOWREBV"                                                                     as BIC_ZSHOWREBV
      , "/BIC/ZOTHREBV"                                                                      as BIC_ZOTHREBV
      , "/BIC/ZFCPRCCY"                                                                      as BIC_ZFCPRCCY
      , "/BIC/ZFCPRCPY"                                                                      as BIC_ZFCPRCPY
      , "/BIC/ZPRCFCTR"                                                                      as BIC_ZPRCFCTR
      , "/BIC/ZCJADISC"                                                                      as BIC_ZCJADISC
      , "/BIC/ZCJADISPY"                                                                     as BIC_ZCJADISPY
      , "/BIC/ZPRDADJDI"                                                                     as BIC_ZPRDADJDI
      , "/BIC/ZCSTADJDI"                                                                     as BIC_ZCSTADJDI
      , "/BIC/ZPRCINCRT"                                                                     as BIC_ZPRCINCRT
      , "/BIC/ZPRCDECRT"                                                                     as BIC_ZPRCDECRT
      , "/BIC/ZCOUNTER"                                                                      as BIC_ZCOUNTER
      , RECORDMODE
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , PSA_RECORD_SOURCE
      , IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE(
                'UTC',
                TO_TIMESTAMP_NTZ(
                    SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16),
                    'YYYYMMDDHH24MISS.FF9'
                )
            )
        )                                                                                    as LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_bkcc
)

, LOGIC_mara as (
    SELECT
        zzfcst_base,
        coalesce(nullif(trim(MATNR), ''), '-1') as MATNR
    FROM SRC_mara
    WHERE rn = 1  -- Only take the top-ranked record per zzfcst_base
)

---- JOIN LAYER ----

, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_bkcc
        ON '1' = '1'
    INNER JOIN LOGIC_mara  -- join required to resolve ITEM from MATERIAL
        ON LOGIC_SRC.MATERIAL = LOGIC_mara.zzfcst_base
)

---- FINAL LAYER ----
SELECT
          FISCPER
        , FISCPER3
        , SALESORG
        , DISTR_CHAN
        , DIVISION
        , MATERIAL
        , MATNR                                                          as ITEM_BK
        , PLANT
        , MAT_PLANT
        , BIC_ZZAPOACCT
        , BIC_ZZPLANPER
        , BIC_ZACCTMATL
        , BIC_ZFQUARTER
        , BIC_ZQUARTER
        , BIC_WWRSN
        , DEALTYPE
        , BIC_ZRATE_VR
        , GLREQUEST
        , FISCVARNT
        , FISCYEAR
        , BASE_UOM
        , CURRENCY
        , BIC_ZWFBILLED
        , BIC_ZWFNOCHRG
        , BIC_ZWFGRSOID
        , BIC_ZFCBILLED
        , BIC_ZFCLISTCY
        , BIC_ZFCLISTPY
        , BIC_ZFCNOCHRG
        , BIC_ZFCINDGRS
        , BIC_ZFCIGSPY
        , BIC_ZFCGRSFRT
        , BIC_ZFCGRSFPY
        , BIC_ZFCPRCDIS
        , BIC_ZFCPRCDPY
        , BIC_ZFCGRSOID
        , BIC_ZCHGRSOID
        , BIC_ZPRCLOSDL
        , BIC_ZFCSTOID
        , BIC_ZFCFRT
        , BIC_ZFCRETALW
        , BIC_ZFCCSHDIS
        , BIC_ZFCVRBCUS
        , BIC_ZFCVRBFLT
        , BIC_ZFCVRBTLD
        , BIC_ZFCVRBCSH
        , BIC_ZFCVRBPAR
        , BIC_ZFCVRBPLM
        , BIC_ZFCVRBSHW
        , BIC_ZFCVRBOTH
        , BIC_ZFCFIXBSF
        , BIC_ZFCFIXNSF
        , BIC_ZFCFIXPRP
        , BIC_ZFCFIXCCF
        , BIC_ZFCFIXCCA
        , BIC_ZFCFIXCPP
        , BIC_ZOTHREBF
        , BIC_ZFCSTDCST
        , BIC_ZFCCURCST
        , BIC_ZMSCOS
        , BIC_ZDFSCOS
        , BIC_ZFOSCOS
        , BIC_ZVOSCOS
        , BIC_ZNOCHRGDI
        , BIC_ZFRTDISC
        , BIC_ZOIDDISC
        , BIC_ZRETSDISC
        , BIC_ZCSHDISC
        , BIC_ZCUSREBV
        , BIC_ZCUSREFTV
        , BIC_ZTRKLDRBV
        , BIC_ZCUSCDRBV
        , BIC_ZCUSPRRBV
        , BIC_ZPLUREBV
        , BIC_ZSHOWREBV
        , BIC_ZOTHREBV
        , BIC_ZFCPRCCY
        , BIC_ZFCPRCPY
        , BIC_ZPRCFCTR
        , BIC_ZCJADISC
        , BIC_ZCJADISPY
        , BIC_ZPRDADJDI
        , BIC_ZCSTADJDI
        , BIC_ZPRCINCRT
        , BIC_ZPRCDECRT
        , BIC_ZCOUNTER
        , RECORDMODE
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , DISTRIBUTION_CHANNEL_BK
        , SALES_ORGANIZATION_BK
        , DIVISION_BK
        , PLANT_BK
        , UOM_BK
        , FORECASTING_PLAN_PERIOD_BK
        , FORECAST_CUSTOMER_GROUP_BK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(PLANT as VARCHAR)),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(SALESORG as VARCHAR)),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as SALES_ORGANIZATION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DIVISION as VARCHAR)),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DIVISION_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(DISTR_CHAN as VARCHAR)),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DISTRIBUTION_CHANNEL_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BASE_UOM as VARCHAR)),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as UOM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(TO_CHAR(TRY_TO_DATE(BIC_ZZPLANPER, 'MONYY'), 'YYYYMM') as VARCHAR)),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FORECASTING_PLAN_PERIOD_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(BIC_ZZAPOACCT as VARCHAR)),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FORECAST_CUSTOMER_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(MATNR as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FORECASTING_PLAN_PERIOD_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FORECAST_CUSTOMER_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEMAND_PLAN_LHK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(FISCPER::text), '^^')
            , '||', IFNULL(TRIM(FISCPER3::text), '^^')
            , '||', IFNULL(TRIM(MAT_PLANT::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZACCTMATL::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFQUARTER::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZQUARTER::text), '^^')
            , '||', IFNULL(TRIM(BIC_WWRSN::text), '^^')
            , '||', IFNULL(TRIM(DEALTYPE::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZRATE_VR::text), '^^')
            , '||', IFNULL(TRIM(FISCVARNT::text), '^^')
            , '||', IFNULL(TRIM(FISCYEAR::text), '^^')
            , '||', IFNULL(TRIM(BASE_UOM::text), '^^')
            , '||', IFNULL(TRIM(CURRENCY::text), '^^')
            , '||', IFNULL(TRIM(RECORDMODE::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZWFBILLED::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZWFNOCHRG::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZWFGRSOID::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCBILLED::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCLISTCY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCLISTPY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCNOCHRG::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCINDGRS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCIGSPY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCGRSFRT::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCGRSFPY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCPRCDIS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCPRCDPY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCGRSOID::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCHGRSOID::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPRCLOSDL::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCSTOID::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCFRT::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCRETALW::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCCSHDIS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCVRBCUS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCVRBFLT::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCVRBTLD::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCVRBCSH::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCVRBPAR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCVRBPLM::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCVRBSHW::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCVRBOTH::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCFIXBSF::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCFIXNSF::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCFIXPRP::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCFIXCCF::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCFIXCCA::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCFIXCPP::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZOTHREBF::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCSTDCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCCURCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZMSCOS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZDFSCOS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFOSCOS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZVOSCOS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZNOCHRGDI::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFRTDISC::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZOIDDISC::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZRETSDISC::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCSHDISC::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCUSREBV::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCUSREFTV::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZTRKLDRBV::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCUSCDRBV::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCUSPRRBV::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPLUREBV::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZSHOWREBV::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZOTHREBV::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCPRCCY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCPRCPY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPRCFCTR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCJADISC::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCJADISPY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPRDADJDI::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCSTADJDI::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPRCINCRT::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPRCDECRT::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCOUNTER::text), '^^')
            , '||', IFNULL(TRIM(GLDELFLAG::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^'))) AS HASHDIFF
FROM JOIN_RESULT