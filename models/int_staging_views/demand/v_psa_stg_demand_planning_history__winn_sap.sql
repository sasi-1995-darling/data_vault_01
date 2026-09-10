---- SRC LAYER ----
WITH
SRC_a              as ( SELECT REQUID, CALMONTH, CALQUARTER, CALWEEK, FISCPER, FISCVARNT, FISCYEAR, CALYEAR, SALES_UNIT, UNIT, BASE_UOM, DATE0, DISTR_CHAN, DIVISION, MATERIAL, PLANT, SALESORG, "/BIC/ZZAPOACCT", "/BIC/ZZAPOGRP", APO_PLVERS, "/BIC/ZZPLANPER", "/BIC/ZFQUARTER", "/BIC/ZFYEAR", "/BIC/ZMONTH", "/BIC/ZQUARTER", MAT_PLANT, "/BIC/ZACCTMATL", "/BIC/ZZMATENTR", CURRENCY, GLREQUEST, GLSOURCESYSTEM, ORDER_QTY, "/BIC/Z9ADFCST", "/BIC/ZCANNIBAL", "/BIC/ZCORRHIST", "/BIC/ZCUSTFORE", "/BIC/ZFCSTERR", "/BIC/ZFINLFCST", "/BIC/ZLYSALES1", "/BIC/ZLYSALES2", "/BIC/ZMANUCORR", "/BIC/ZMAPE", "/BIC/ZMKTCORR", "/BIC/ZPRODLIFE", "/BIC/ZPROMOPCT", "/BIC/ZPROMOQTY", "/BIC/ZSLSCORR", "/BIC/ZSNPCONS", "/BIC/ZSTATFORE", "/BIC/ZLEADIND", "/BIC/ZPOSQTY", "/BIC/ZMCORHIST", "/BIC/ZACPROR", "/BIC/ZADDPF", "/BIC/ZALTFCST", "/BIC/ZCUSTINV", "/BIC/ZDUMMY1", "/BIC/ZDUMMY2", "/BIC/ZFCSTCI", "/BIC/ZINTFCST1", "/BIC/ZINTFCST2", "/BIC/ZNWPP", "/BIC/ZPRMOFCST", "/BIC/ZUPSS", "/BIC/ZUPTDAY", "/BIC/ZYANPLAN", "/BIC/ZCANNIBLE", "/BIC/ZANALIFT", "/BIC/ZBASELN", "/BIC/ZDPDOLLAR", "/BIC/ZINTFCST", "/BIC/ZINVLD", "/BIC/ZMKTGRTH", "/BIC/ZNODOLLAR", "/BIC/ZPOSCORR", "/BIC/ZPULLAHD", "/BIC/ZSTAT1", "/BIC/ZSTAT2", "/BIC/ZSTAT4", "/BIC/ZTOPFCST", "/BIC/ZSTATFCST", "/BIC/ZTOPGRTH", "/BIC/ZTRANSDMD", "/BIC/ZEXTRA1", "/BIC/ZEXTRA2", "/BIC/ZEXTRA3", "/BIC/ZEXTRA4", "/BIC/ZMOENPROP", "/BIC/ZNEWPFCST", "/BIC/ZOUTTED", "/BIC/ZSTAT3", GLDELFLAG, GLCHANGETIME, PSA_LOAD_DTS, PSA_DELETE_IND, PSA_RECORD_SOURCE  FROM {{ source('sap_bw_prd', 'z_zapoplanm') }} as SRC  ),
SRC_bkcc           as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC  ),
SRC_mara           as ( 
                        SELECT  -- Ranking logic: prioritizing cleaner MATNRs and active statuses
                        zzfcst_base, 
                        MATNR,
                        zzproductvitality,
                        mstae,
                        ersda
                    FROM {{ source('sap_ecc_prd', 'z_mara') }}
                    QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY zzfcst_base ORDER BY GLCHANGETIME DESC, PSA_LOAD_DTS DESC))
/*
SRC_a              as ( SELECT * FROM sap_bw_prd.z_zapoplanm )
SRC_bkcc           as ( SELECT * FROM raw_vault.ref_business_key_collision )
SRC_mara           as ( SELECT * FROM sap_ecc_prd.z_mara )
*/
---- LOGIC LAYER ----

, LOGIC_a as (
    SELECT
        REQUID, 
        CALMONTH, 
        CALQUARTER, 
        CALWEEK, 
        FISCPER, 
        FISCVARNT, 
        FISCYEAR, 
        CALYEAR, 
        SALES_UNIT, 
        UNIT, 
        BASE_UOM, 
        coalesce(nullif(trim(BASE_UOM), ''), '-1')  as UOM_BK,
        DATE0, 
        DISTR_CHAN,
        coalesce(nullif(trim(DISTR_CHAN), ''), '-1')  as DISTRIBUTION_CHANNEL_BK,  
        DIVISION,
        coalesce(nullif(trim(DIVISION), ''), '-1')  as DIVISION_BK  , 
        MATERIAL, 
        PLANT, 
        coalesce(nullif(trim(PLANT), ''), '-1')  as PLANT_BK,
        SALESORG, 
        coalesce(nullif(trim(SALESORG), ''), '-1')  as SALES_ORGANIZATION_BK, 
        "/BIC/ZZAPOACCT" AS BIC_ZZAPOACCT, 
        "/BIC/ZZAPOGRP" AS BIC_ZZAPOGRP, 
        APO_PLVERS, 
        coalesce(nullif(TO_CHAR(TRY_TO_DATE("/BIC/ZZPLANPER", 'MONYY'), 'YYYYMM'), ''), '-1') as FORECASTING_PLAN_PERIOD_BK,
        coalesce(nullif(trim("/BIC/ZZAPOACCT"), ''), '-1') as FORECAST_CUSTOMER_GROUP_BK,
        coalesce(nullif(TO_CHAR(TRY_TO_DATE("/BIC/ZZPLANPER", 'MONYY'), 'YYYYMM'), ''), '-1') as PLANNING_PERIOD,
        "/BIC/ZZPLANPER" AS BIC_ZZPLANPER, 
        "/BIC/ZFQUARTER" AS BIC_ZFQUARTER, 
        "/BIC/ZFYEAR" AS BIC_ZFYEAR, 
        "/BIC/ZMONTH" AS BIC_ZMONTH, 
        "/BIC/ZQUARTER" AS BIC_ZQUARTER, 
        MAT_PLANT, 
        "/BIC/ZACCTMATL" AS BIC_ZACCTMATL, 
        "/BIC/ZZMATENTR" AS BIC_ZZMATENTR, 
        CURRENCY, 
        GLREQUEST, 
        GLSOURCESYSTEM, 
        ORDER_QTY, 
        "/BIC/Z9ADFCST" AS BIC_Z9ADFCST, 
        "/BIC/ZCANNIBAL" AS BIC_ZCANNIBAL, 
        "/BIC/ZCORRHIST" AS BIC_ZCORRHIST, 
        "/BIC/ZCUSTFORE" AS BIC_ZCUSTFORE, 
        "/BIC/ZFCSTERR" AS BIC_ZFCSTERR, 
        "/BIC/ZFINLFCST" AS BIC_ZFINLFCST, 
        "/BIC/ZLYSALES1" AS BIC_ZLYSALES1, 
        "/BIC/ZLYSALES2" AS BIC_ZLYSALES2, 
        "/BIC/ZMANUCORR" AS BIC_ZMANUCORR, 
        "/BIC/ZMAPE" AS BIC_ZMAPE, 
        "/BIC/ZMKTCORR" AS BIC_ZMKTCORR, 
        "/BIC/ZPRODLIFE" AS BIC_ZPRODLIFE, 
        "/BIC/ZPROMOPCT" AS BIC_ZPROMOPCT, 
        "/BIC/ZPROMOQTY" AS BIC_ZPROMOQTY, 
        "/BIC/ZSLSCORR" AS BIC_ZSLSCORR, 
        "/BIC/ZSNPCONS" AS BIC_ZSNPCONS, 
        "/BIC/ZSTATFORE" AS BIC_ZSTATFORE, 
        "/BIC/ZLEADIND" AS BIC_ZLEADIND, 
        "/BIC/ZPOSQTY" AS BIC_ZPOSQTY, 
        "/BIC/ZMCORHIST" AS BIC_ZMCORHIST, 
        "/BIC/ZACPROR" AS BIC_ZACPROR, 
        "/BIC/ZADDPF" AS BIC_ZADDPF, 
        "/BIC/ZALTFCST" AS BIC_ZALTFCST, 
        "/BIC/ZCUSTINV" AS BIC_ZCUSTINV, 
        "/BIC/ZDUMMY1" AS BIC_ZDUMMY1, 
        "/BIC/ZDUMMY2" AS BIC_ZDUMMY2, 
        "/BIC/ZFCSTCI" AS BIC_ZFCSTCI, 
        "/BIC/ZINTFCST1" AS BIC_ZINTFCST1, 
        "/BIC/ZINTFCST2" AS BIC_ZINTFCST2, 
        "/BIC/ZNWPP" AS BIC_ZNWPP, 
        "/BIC/ZPRMOFCST" AS BIC_ZPRMOFCST, 
        "/BIC/ZUPSS" AS BIC_ZUPSS, 
        "/BIC/ZUPTDAY" AS BIC_ZUPTDAY, 
        "/BIC/ZYANPLAN" AS BIC_ZYANPLAN, 
        "/BIC/ZCANNIBLE" AS BIC_ZCANNIBLE, 
        "/BIC/ZANALIFT" AS BIC_ZANALIFT, 
        "/BIC/ZBASELN" AS BIC_ZBASELN, 
        "/BIC/ZDPDOLLAR" AS BIC_ZDPDOLLAR, 
        "/BIC/ZINTFCST" AS BIC_ZINTFCST, 
        "/BIC/ZINVLD" AS BIC_ZINVLD, 
        "/BIC/ZMKTGRTH" AS BIC_ZMKTGRTH, 
        "/BIC/ZNODOLLAR" AS BIC_ZNODOLLAR, 
        "/BIC/ZPOSCORR" AS BIC_ZPOSCORR, 
        "/BIC/ZPULLAHD" AS BIC_ZPULLAHD, 
        "/BIC/ZSTAT1" AS BIC_ZSTAT1, 
        "/BIC/ZSTAT2" AS BIC_ZSTAT2, 
        "/BIC/ZSTAT4" AS BIC_ZSTAT4, 
        "/BIC/ZTOPFCST" AS BIC_ZTOPFCST, 
        "/BIC/ZSTATFCST" AS BIC_ZSTATFCST, 
        "/BIC/ZTOPGRTH" AS BIC_ZTOPGRTH, 
        "/BIC/ZTRANSDMD" AS BIC_ZTRANSDMD, 
        "/BIC/ZEXTRA1" AS BIC_ZEXTRA1, 
        "/BIC/ZEXTRA2" AS BIC_ZEXTRA2, 
        "/BIC/ZEXTRA3" AS BIC_ZEXTRA3, 
        "/BIC/ZEXTRA4" AS BIC_ZEXTRA4, 
        "/BIC/ZMOENPROP" AS BIC_ZMOENPROP, 
        "/BIC/ZNEWPFCST" AS BIC_ZNEWPFCST, 
        "/BIC/ZOUTTED" AS BIC_ZOUTTED, 
        "/BIC/ZSTAT3" AS BIC_ZSTAT3, 
        GLDELFLAG, 
        GLCHANGETIME,
        PSA_LOAD_DTS,
        PSA_DELETE_IND,
        PSA_RECORD_SOURCE,
        IFF(
            PSA_DELETE_IND = 'Y',
            PSA_LOAD_DTS,
            CONVERT_TIMEZONE(
            'UTC',
            TO_TIMESTAMP_NTZ(
            SUBSTR(GLCHANGETIME, 1, 14) || '.' || SUBSTR(GLCHANGETIME, 16),
            'YYYYMMDDHH24MISS.FF9'
            )
            )
        )                                                            as                                           LOAD_DTS
    FROM SRC_a
)

, LOGIC_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM SRC_bkcc
)



, LOGIC_mara as (
    SELECT
        zzfcst_base
       ,coalesce(nullif(trim(MATNR), ''), '-1') as MATNR
    FROM SRC_mara 
    qualify 1 = row_number() over (
                            partition by zzfcst_base 
                            order by 
                                CASE WHEN MATNR LIKE '%-%' THEN 2 ELSE 1 END, 
                                CASE WHEN mstae IN ('Z8', 'ZP', 'Z7','Z6','ZN','05','Z1','Z2','Z3','Z5') THEN 2 ELSE 1 END,
                                CASE WHEN zzproductvitality in ('NOTN','NP') THEN 2 ELSE 1 END, 
                                ersda desc
                        )  -- Only take the top-ranked record per zzfcst_base
)
---- RENAME LAYER ----

, RENAME_a as (
    SELECT
       REQUID
        , CALMONTH
        , CALQUARTER
        , CALWEEK
        , FISCPER
        , FISCVARNT
        , FISCYEAR
        , CALYEAR
        , SALES_UNIT
        , UNIT
        , BASE_UOM
        , UOM_BK
        , DATE0
        , DISTR_CHAN
        , DISTRIBUTION_CHANNEL_BK
        , DIVISION
        , DIVISION_BK
        , MATERIAL
        , PLANT
        , PLANT_BK
        , SALESORG
        , SALES_ORGANIZATION_BK
        , BIC_ZZAPOACCT
        , BIC_ZZAPOGRP
        , APO_PLVERS
        , FORECASTING_PLAN_PERIOD_BK
        , FORECAST_CUSTOMER_GROUP_BK
        , PLANNING_PERIOD
        , BIC_ZZPLANPER
        , BIC_ZFQUARTER
        , BIC_ZFYEAR
        , BIC_ZMONTH
        , BIC_ZQUARTER
        , MAT_PLANT
        , BIC_ZACCTMATL
        , BIC_ZZMATENTR
        , CURRENCY
        , GLREQUEST
        , GLSOURCESYSTEM
        , ORDER_QTY
        , BIC_Z9ADFCST
        , BIC_ZCANNIBAL
        , BIC_ZCORRHIST
        , BIC_ZCUSTFORE
        , BIC_ZFCSTERR
        , BIC_ZFINLFCST
        , BIC_ZLYSALES1
        , BIC_ZLYSALES2
        , BIC_ZMANUCORR
        , BIC_ZMAPE
        , BIC_ZMKTCORR
        , BIC_ZPRODLIFE
        , BIC_ZPROMOPCT
        , BIC_ZPROMOQTY
        , BIC_ZSLSCORR
        , BIC_ZSNPCONS
        , BIC_ZSTATFORE
        , BIC_ZLEADIND
        , BIC_ZPOSQTY
        , BIC_ZMCORHIST
        , BIC_ZACPROR
        , BIC_ZADDPF
        , BIC_ZALTFCST
        , BIC_ZCUSTINV
        , BIC_ZDUMMY1
        , BIC_ZDUMMY2
        , BIC_ZFCSTCI
        , BIC_ZINTFCST1
        , BIC_ZINTFCST2
        , BIC_ZNWPP
        , BIC_ZPRMOFCST
        , BIC_ZUPSS
        , BIC_ZUPTDAY
        , BIC_ZYANPLAN
        , BIC_ZCANNIBLE
        , BIC_ZANALIFT
        , BIC_ZBASELN
        , BIC_ZDPDOLLAR
        , BIC_ZINTFCST
        , BIC_ZINVLD
        , BIC_ZMKTGRTH
        , BIC_ZNODOLLAR
        , BIC_ZPOSCORR
        , BIC_ZPULLAHD
        , BIC_ZSTAT1
        , BIC_ZSTAT2
        , BIC_ZSTAT4
        , BIC_ZTOPFCST
        , BIC_ZSTATFCST
        , BIC_ZTOPGRTH
        , BIC_ZTRANSDMD
        , BIC_ZEXTRA1
        , BIC_ZEXTRA2
        , BIC_ZEXTRA3
        , BIC_ZEXTRA4
        , BIC_ZMOENPROP
        , BIC_ZNEWPFCST
        , BIC_ZOUTTED
        , BIC_ZSTAT3
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , PSA_RECORD_SOURCE
        , LOAD_DTS
    FROM LOGIC_a
)



, RENAME_bkcc as (
    SELECT
        REC_SRC
      , BKCC
    FROM LOGIC_bkcc
)

, RENAME_mara as (
    SELECT
        zzfcst_base
       ,MATNR
    FROM LOGIC_mara
)
---- FILTER LAYER ----

, FILTER_a as (
    SELECT *
    FROM RENAME_a
)

, FILTER_bkcc as (
    SELECT *
    FROM RENAME_bkcc
    WHERE rec_src = 'USOHNO.SAP_BW.Z_ZAPOPLANM'
)


, FILTER_mara as (
    SELECT *
    FROM RENAME_mara
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_a
    INNER JOIN FILTER_bkcc
        ON '1' = '1'
    INNER JOIN FILTER_mara -- join required to pull the item detail frim the mara table
        ON FILTER_a.MATERIAL = FILTER_mara.zzfcst_base
)

---- FINAL LAYER ----
SELECT
        REQUID, 
        CALMONTH, 
        CALQUARTER, 
        CALWEEK, 
        FISCPER, 
        FISCVARNT, 
        FISCYEAR, 
        CALYEAR, 
        SALES_UNIT, 
        UNIT, 
        BASE_UOM, 
        DATE0, 
        DISTR_CHAN, 
        DIVISION, 
        MATERIAL,
        MATNR as ITEM_BK, 
        PLANT, 
        SALESORG, 
        BIC_ZZAPOACCT, 
        BIC_ZZAPOGRP, 
        APO_PLVERS, 
        FORECASTING_PLAN_PERIOD_BK,
        FORECAST_CUSTOMER_GROUP_BK,
        PLANNING_PERIOD,
        BIC_ZZPLANPER, 
        BIC_ZFQUARTER, 
        BIC_ZFYEAR, 
        BIC_ZMONTH, 
        BIC_ZQUARTER, 
        MAT_PLANT,  
        BIC_ZACCTMATL, 
        BIC_ZZMATENTR, 
        CURRENCY, 
        GLREQUEST, 
        GLSOURCESYSTEM, 
        ORDER_QTY, 
        BIC_Z9ADFCST, 
        BIC_ZCANNIBAL, 
        BIC_ZCORRHIST, 
        BIC_ZCUSTFORE, 
        BIC_ZFCSTERR, 
        BIC_ZFINLFCST, 
        BIC_ZLYSALES1, 
        BIC_ZLYSALES2, 
        BIC_ZMANUCORR, 
        BIC_ZMAPE, 
        BIC_ZMKTCORR, 
        BIC_ZPRODLIFE, 
        BIC_ZPROMOPCT, 
        BIC_ZPROMOQTY, 
        BIC_ZSLSCORR, 
        BIC_ZSNPCONS, 
        BIC_ZSTATFORE, 
        BIC_ZLEADIND, 
        BIC_ZPOSQTY, 
        BIC_ZMCORHIST, 
        BIC_ZACPROR, 
        BIC_ZADDPF, 
        BIC_ZALTFCST, 
        BIC_ZCUSTINV, 
        BIC_ZDUMMY1, 
        BIC_ZDUMMY2, 
        BIC_ZFCSTCI, 
        BIC_ZINTFCST1, 
        BIC_ZINTFCST2, 
        BIC_ZNWPP, 
        BIC_ZPRMOFCST, 
        BIC_ZUPSS, 
        BIC_ZUPTDAY, 
        BIC_ZYANPLAN, 
        BIC_ZCANNIBLE, 
        BIC_ZANALIFT, 
        BIC_ZBASELN, 
        BIC_ZDPDOLLAR, 
        BIC_ZINTFCST, 
        BIC_ZINVLD, 
        BIC_ZMKTGRTH, 
        BIC_ZNODOLLAR, 
        BIC_ZPOSCORR, 
        BIC_ZPULLAHD, 
        BIC_ZSTAT1, 
        BIC_ZSTAT2, 
        BIC_ZSTAT4, 
        BIC_ZTOPFCST, 
        BIC_ZSTATFCST, 
        BIC_ZTOPGRTH, 
        BIC_ZTRANSDMD, 
        BIC_ZEXTRA1, 
        BIC_ZEXTRA2, 
        BIC_ZEXTRA3, 
        BIC_ZEXTRA4, 
        BIC_ZMOENPROP, 
        BIC_ZNEWPFCST, 
        BIC_ZOUTTED, 
        BIC_ZSTAT3, 
        GLDELFLAG, 
        GLCHANGETIME,
        PSA_LOAD_DTS,
        PSA_DELETE_IND,
        PSA_RECORD_SOURCE
        , LOAD_DTS
        , REC_SRC
        , BKCC
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
          COALESCE(NULLIF(TRIM(CAST( BIC_ZZAPOACCT as VARCHAR)),''), '-1')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as FORECAST_CUSTOMER_GROUP_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(PLANT_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(UOM_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DISTRIBUTION_CHANNEL_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(SALES_ORGANIZATION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(DIVISION_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FORECASTING_PLAN_PERIOD_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(FORECAST_CUSTOMER_GROUP_BK as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as DEMAND_PLAN_LHK
        , DISTRIBUTION_CHANNEL_BK
        , SALES_ORGANIZATION_BK
        , DIVISION_BK
        , PLANT_BK
        , UOM_BK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              '||', IFNULL(TRIM(REQUID::text), '^^')
            , '||', IFNULL(TRIM(CALMONTH::text), '^^')
            , '||', IFNULL(TRIM(CALQUARTER::text), '^^')
            , '||', IFNULL(TRIM(FISCPER::text), '^^')
            , '||', IFNULL(TRIM(FISCVARNT::text), '^^')
            , '||', IFNULL(TRIM(FISCYEAR::text), '^^')
            , '||', IFNULL(TRIM(CALYEAR::text), '^^')
            , '||', IFNULL(TRIM(SALES_UNIT::text), '^^')
            , '||', IFNULL(TRIM(UNIT::text), '^^')
            , '||', IFNULL(TRIM(BASE_UOM::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZZAPOGRP::text), '^^')
            , '||', IFNULL(TRIM(APO_PLVERS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFQUARTER::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFYEAR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZMONTH::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZQUARTER::text), '^^')
            , '||', IFNULL(TRIM(MAT_PLANT::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZACCTMATL::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZZMATENTR::text), '^^')
            , '||', IFNULL(TRIM(CURRENCY::text), '^^')
            , '||', IFNULL(TRIM(GLREQUEST::text), '^^')
            , '||', IFNULL(TRIM(GLSOURCESYSTEM::text), '^^')
            , '||', IFNULL(TRIM(ORDER_QTY::text), '^^')
            , '||', IFNULL(TRIM(BIC_Z9ADFCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCANNIBAL::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCORRHIST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCUSTFORE::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCSTERR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFINLFCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZLYSALES1::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZLYSALES2::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZMANUCORR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZMAPE::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZMKTCORR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPRODLIFE::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPROMOPCT::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPROMOQTY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZSLSCORR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZSNPCONS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZSTATFORE::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZLEADIND::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPOSQTY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZMCORHIST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZACPROR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZADDPF::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZALTFCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCUSTINV::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZDUMMY1::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZDUMMY2::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZFCSTCI::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZINTFCST1::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZINTFCST2::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZNWPP::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPRMOFCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZUPSS::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZUPTDAY::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZYANPLAN::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZCANNIBLE::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZANALIFT::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZBASELN::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZDPDOLLAR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZINTFCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZINVLD::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZMKTGRTH::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZNODOLLAR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPOSCORR::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZPULLAHD::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZSTAT1::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZSTAT2::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZSTAT4::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZTOPFCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZSTATFCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZTOPGRTH::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZTRANSDMD::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZEXTRA1::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZEXTRA2::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZEXTRA3::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZEXTRA4::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZMOENPROP::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZNEWPFCST::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZOUTTED::text), '^^')
            , '||', IFNULL(TRIM(BIC_ZSTAT3::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^'))) AS HASHDIFF
FROM JOIN_RESULT