---- SRC LAYER ----
WITH
SRC_SRC            as ( SELECT * FROM {{ source('tt_e21prd_e21trubis', 'invitem') }} as SRC 
                        /* grain_valid=False: 7546440 duplicate BK+LOAD_DTS rows detected */
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY ITEM_NO::VARCHAR, LOCATION, _FIVETRAN_SYNCED ORDER BY _FIVETRAN_SYNCED DESC) = 1 ),
SRC_ref_bkcc       as ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} as SRC 
                        WHERE rec_src = 'USOHMA.ORCL.E21PRD.INVITEM' )

/*
SRC_SRC            as ( SELECT * FROM tt_e21prd_e21trubis.invitem )
SRC_ref_bkcc       as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, LOGIC_SRC as (
    SELECT
        ITEM_NO
      , COALESCE(NULLIF(TRIM(LOCATION), ''), '-1')                   as                                           PLANT_BK
      , PART_TYPE
      , ITEM_INVT_AMT
      , ITEM_MATL_AMT
      , ITEM_TERMS
      , ITEM_COGS_ACCT
      , ITEM_CART_ACCT
      , ITEM_CSAL_AMT
      , CONSOL_NUMB
      , ITEM_INTEL_ACCT
      , ITEM_CCRT_ACCT
      , VEND_CODE1
      , PART_ATTRIBUTE1
      , ITEM_PSDISC_TY
      , VEND_CODE2
      , ITEM_DISCOUNT_TY
      , PART_ATTRIBUTE3
      , PART_ATTRIBUTE2
      , PART_ATTRIBUTE5
      , PART_ATTRIBUTE4
      , DIVISION_CODE
      , VEND_CODE3
      , PART_ATTRIBUTE6
      , LCHFLD2
      , LCHFLD1
      , ITEM_COM_RATE
      , VOL_DISC_TY
      , ITEM_INTXI_ACCT
      , ITEM_INTIN_AMT
      , LOT
      , ITEM_SHIPDATE
      , ITEM_SALES_ACCT
      , INVOICE_NUMB
      , ITEM_ALOW1_AMT
      , ITEM_ALOW1
      , ITEM_ALOW2
      , LOCATION
      , ITEM_INTXO_AMT
      , PACK_CHARGE
      , ITEM_COGS_AMT
      , ITEM_MATL_ACCT
      , PART_CODE
      , ITEM_XCUR_CONV
      , ITEM_COST
      , ITEM_TAX_ACCT
      , ITEM_CART_AMT
      , ITEM_INVT_ACCT
      , ITEM_INTIN_ACCT
      , ITEM_DISCOUNT
      , ITEM_NTPRICE
      , ITEM_IVAR_AMT
      , ITEM_COMMIS
      , ITEM_FRT_ACCT
      , VOL_DISC_AMT
      , EXT_PRICE
      , XCUR_CONV
      , ITEM_IVAR_ACCT
      , ITEM_AR_ACCT
      , ORD_ITEM
      , BCUR_CONV
      , ITEM_BCUR_CONV
      , ITEM_PRICEID
      , ITEM_XCUR_UOM
      , ITEM_CCRT_AMT
      , VEND_QTY2
      , DTFLD1
      , NUMFLD1
      , ITEM_LIST_PRICE
      , VEND_QTY3
      , ITEM_ALOW2T
      , NUMFLD2
      , VEND_QTY1
      , NUMFLD3
      , DTFLD2
      , UOM_CONV
      , INV_PRT_FLAG
      , ITEM_INTXI_AMT
      , ITEM_STAT_ACCT
      , ITEM_FRT_AMT
      , ALOW2_ACRU_ACCT
      , QTY
      , XCUR_UOM
      , ITEM_CSAL_ACCT
      , ORDER_DISC_TY
      , REL_NUMB
      , ITEM_INTEL_AMT
      , ITEM_PSDISC_AMT
      , PART_DESC
      , ITEM_ALOW1T
      , ITEM_BCUR_UOM
      , ITEM_INTSA_AMT
      , ITEM_ALOW2_AMT
      , ITEM_WGT
      , ITEM_INTXO_ACCT
      , ITEM_REP
      , SCHFLD1
      , ALOW1_ACRU_ACCT
      , SCHFLD3
      , ITEM_GWGT
      , SCHFLD2
      , ITEM_ALOW1_ACCT
      , ITEM_AR_AMT
      , ITEM_PPV
      , ORDER_NUMB
      , BIN_NO
      , ITEM_STATUS
      , ITEM_TAX_AMT
      , BCUR_UOM
      , ITEM_MSG
      , INV_PRT_DATE
      , ITEM_STAT_AMT
      , SALE_TYPE
      , COST_CTR
      , ITEM_ALOW2_ACCT
      , ITEM_INTSA_ACCT
      , ITEM_DISCOUNT_AMT
      , ORDER_DISC_AMT
      , UOM
      , ITEM_SALES_AMT
      , SHIP_QTY
      , MSTR_INV_NUMB
      , ITEM_INTII_ACCT
      , ITEM_INTII_AMT
      , ITEM_PRICE
      , _FIVETRAN_ID
      , _FIVETRAN_DELETED
      , _FIVETRAN_SYNCED
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
    FROM SRC_SRC
)

, LOGIC_ref_bkcc as (
    SELECT
        BKCC
      , REC_SRC
    FROM SRC_ref_bkcc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM LOGIC_SRC
    INNER JOIN LOGIC_ref_bkcc
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT
          ITEM_NO::VARCHAR                                             as ITEM_BK
        , ITEM_NO
        , PLANT_BK
        , PART_TYPE
        , ITEM_INVT_AMT
        , ITEM_MATL_AMT
        , ITEM_TERMS
        , ITEM_COGS_ACCT
        , ITEM_CART_ACCT
        , ITEM_CSAL_AMT
        , CONSOL_NUMB
        , ITEM_INTEL_ACCT
        , ITEM_CCRT_ACCT
        , VEND_CODE1
        , PART_ATTRIBUTE1
        , ITEM_PSDISC_TY
        , VEND_CODE2
        , ITEM_DISCOUNT_TY
        , PART_ATTRIBUTE3
        , PART_ATTRIBUTE2
        , PART_ATTRIBUTE5
        , PART_ATTRIBUTE4
        , DIVISION_CODE
        , VEND_CODE3
        , PART_ATTRIBUTE6
        , LCHFLD2
        , LCHFLD1
        , ITEM_COM_RATE
        , VOL_DISC_TY
        , ITEM_INTXI_ACCT
        , ITEM_INTIN_AMT
        , LOT
        , ITEM_SHIPDATE
        , ITEM_SALES_ACCT
        , INVOICE_NUMB
        , ITEM_ALOW1_AMT
        , ITEM_ALOW1
        , ITEM_ALOW2
        , LOCATION
        , ITEM_INTXO_AMT
        , PACK_CHARGE
        , ITEM_COGS_AMT
        , ITEM_MATL_ACCT
        , PART_CODE
        , ITEM_XCUR_CONV
        , ITEM_COST
        , ITEM_TAX_ACCT
        , ITEM_CART_AMT
        , ITEM_INVT_ACCT
        , ITEM_INTIN_ACCT
        , ITEM_DISCOUNT
        , ITEM_NTPRICE
        , ITEM_IVAR_AMT
        , ITEM_COMMIS
        , ITEM_FRT_ACCT
        , VOL_DISC_AMT
        , EXT_PRICE
        , XCUR_CONV
        , ITEM_IVAR_ACCT
        , ITEM_AR_ACCT
        , ORD_ITEM
        , BCUR_CONV
        , ITEM_BCUR_CONV
        , ITEM_PRICEID
        , ITEM_XCUR_UOM
        , ITEM_CCRT_AMT
        , VEND_QTY2
        , DTFLD1
        , NUMFLD1
        , ITEM_LIST_PRICE
        , VEND_QTY3
        , ITEM_ALOW2T
        , NUMFLD2
        , VEND_QTY1
        , NUMFLD3
        , DTFLD2
        , UOM_CONV
        , INV_PRT_FLAG
        , ITEM_INTXI_AMT
        , ITEM_STAT_ACCT
        , ITEM_FRT_AMT
        , ALOW2_ACRU_ACCT
        , QTY
        , XCUR_UOM
        , ITEM_CSAL_ACCT
        , ORDER_DISC_TY
        , REL_NUMB
        , ITEM_INTEL_AMT
        , ITEM_PSDISC_AMT
        , PART_DESC
        , ITEM_ALOW1T
        , ITEM_BCUR_UOM
        , ITEM_INTSA_AMT
        , ITEM_ALOW2_AMT
        , ITEM_WGT
        , ITEM_INTXO_ACCT
        , ITEM_REP
        , SCHFLD1
        , ALOW1_ACRU_ACCT
        , SCHFLD3
        , ITEM_GWGT
        , SCHFLD2
        , ITEM_ALOW1_ACCT
        , ITEM_AR_AMT
        , ITEM_PPV
        , ORDER_NUMB
        , BIN_NO
        , ITEM_STATUS
        , ITEM_TAX_AMT
        , BCUR_UOM
        , ITEM_MSG
        , INV_PRT_DATE
        , ITEM_STAT_AMT
        , SALE_TYPE
        , COST_CTR
        , ITEM_ALOW2_ACCT
        , ITEM_INTSA_ACCT
        , ITEM_DISCOUNT_AMT
        , ORDER_DISC_AMT
        , UOM
        , ITEM_SALES_AMT
        , SHIP_QTY
        , MSTR_INV_NUMB
        , ITEM_INTII_ACCT
        , ITEM_INTII_AMT
        , ITEM_PRICE
        , _FIVETRAN_ID
        , _FIVETRAN_DELETED
        , _FIVETRAN_SYNCED
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , BKCC
        , REC_SRC
        , LOAD_DTS
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_NO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(ITEM_NO as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(LOCATION as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_ITEM_HK
        , MD5_BINARY(UPPER(CONCAT_WS('||',
          COALESCE(NULLIF(TRIM(CAST(LOCATION as VARCHAR)),''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(BKCC as VARCHAR)),''), '^^')
        ))) as PLANT_HK
        , MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(PART_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INVT_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_MATL_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_TERMS::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_COGS_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CART_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CSAL_AMT::text), '^^') 
            , '||', IFNULL(TRIM(CONSOL_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTEL_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CCRT_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(VEND_CODE1::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE1::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_PSDISC_TY::text), '^^') 
            , '||', IFNULL(TRIM(VEND_CODE2::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DISCOUNT_TY::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE3::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE2::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE5::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE4::text), '^^') 
            , '||', IFNULL(TRIM(DIVISION_CODE::text), '^^') 
            , '||', IFNULL(TRIM(VEND_CODE3::text), '^^') 
            , '||', IFNULL(TRIM(PART_ATTRIBUTE6::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD2::text), '^^') 
            , '||', IFNULL(TRIM(LCHFLD1::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_COM_RATE::text), '^^') 
            , '||', IFNULL(TRIM(VOL_DISC_TY::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTXI_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTIN_AMT::text), '^^') 
            , '||', IFNULL(TRIM(LOT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_SHIPDATE::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_SALES_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(INVOICE_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ALOW1_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ALOW1::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ALOW2::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTXO_AMT::text), '^^') 
            , '||', IFNULL(TRIM(PACK_CHARGE::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_COGS_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_MATL_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(PART_CODE::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_XCUR_CONV::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_COST::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_TAX_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CART_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INVT_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTIN_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DISCOUNT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_NTPRICE::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_IVAR_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_COMMIS::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FRT_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(VOL_DISC_AMT::text), '^^') 
            , '||', IFNULL(TRIM(EXT_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(XCUR_CONV::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_IVAR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_AR_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ORD_ITEM::text), '^^') 
            , '||', IFNULL(TRIM(BCUR_CONV::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_BCUR_CONV::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_PRICEID::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_XCUR_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CCRT_AMT::text), '^^') 
            , '||', IFNULL(TRIM(VEND_QTY2::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD1::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD1::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_LIST_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(VEND_QTY3::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ALOW2T::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD2::text), '^^') 
            , '||', IFNULL(TRIM(VEND_QTY1::text), '^^') 
            , '||', IFNULL(TRIM(NUMFLD3::text), '^^') 
            , '||', IFNULL(TRIM(DTFLD2::text), '^^') 
            , '||', IFNULL(TRIM(UOM_CONV::text), '^^') 
            , '||', IFNULL(TRIM(INV_PRT_FLAG::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTXI_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_STAT_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_FRT_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ALOW2_ACRU_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(QTY::text), '^^') 
            , '||', IFNULL(TRIM(XCUR_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_CSAL_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_DISC_TY::text), '^^') 
            , '||', IFNULL(TRIM(REL_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTEL_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_PSDISC_AMT::text), '^^') 
            , '||', IFNULL(TRIM(PART_DESC::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ALOW1T::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_BCUR_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTSA_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ALOW2_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_WGT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTXO_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_REP::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD1::text), '^^') 
            , '||', IFNULL(TRIM(ALOW1_ACRU_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD3::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_GWGT::text), '^^') 
            , '||', IFNULL(TRIM(SCHFLD2::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ALOW1_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_AR_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_PPV::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(BIN_NO::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_STATUS::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_TAX_AMT::text), '^^') 
            , '||', IFNULL(TRIM(BCUR_UOM::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_MSG::text), '^^') 
            , '||', IFNULL(TRIM(INV_PRT_DATE::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_STAT_AMT::text), '^^') 
            , '||', IFNULL(TRIM(SALE_TYPE::text), '^^') 
            , '||', IFNULL(TRIM(COST_CTR::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_ALOW2_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTSA_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_DISCOUNT_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ORDER_DISC_AMT::text), '^^') 
            , '||', IFNULL(TRIM(UOM::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_SALES_AMT::text), '^^') 
            , '||', IFNULL(TRIM(SHIP_QTY::text), '^^') 
            , '||', IFNULL(TRIM(MSTR_INV_NUMB::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTII_ACCT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_INTII_AMT::text), '^^') 
            , '||', IFNULL(TRIM(ITEM_PRICE::text), '^^') 
            , '||', IFNULL(TRIM(_FIVETRAN_DELETED::text), '^^') 
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^') 
        ), '^^||^^')))  as HASHDIFF
FROM JOIN_RESULT
