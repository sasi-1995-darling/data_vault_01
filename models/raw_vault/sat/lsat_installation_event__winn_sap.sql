---- SRC LAYER ----
WITH
SRC_ZZ             as ( SELECT * FROM {{ ref('v_psa_stg_installation_event__winn_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', -1, MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_ZZ             as ( SELECT * FROM staging.v_psa_stg_installation_event__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_ZZ as (
    SELECT
        LNK_INSTALLATION_DETAIL_HK
      , LOAD_DTS
      , MANDT
      , INSTALLRECID
      , GLREQUEST
      , LIFNR
      , VENDINVOICEID
      , VENDINVOICEDATE
      , ORDERID
      , CONTRACTORID
      , INVOICEITEMID
      , SERVICESKU
      , SERVICENAME
      , SERVICEQTY
      , INVOICEAMT
      , INSTALLDATE
      , COMPLETEDATE
      , WAERK
      , ERNAM
      , ERDAT
      , ERZET
      , VBELN
      , POSNR
      , KUNNR
      , INSTALLMATNR
      , PRODUCTINSTALLED
      , PRODUCT_POSNR
      , ABGRU
      , VBELN_VL
      , POSNR_VL
      , LFIMG
      , VRKME
      , INSTALLWADAT
      , PRODUCTWADAT
      , PROD_VBELN_VL
      , PROD_POSNR_VL
      , CONFIRMNEEDED
      , CONFIRMCOMP
      , CONFSTATUS
      , CONFIRMDATE
      , CONFIRMTIME
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_ZZ
)
---- RENAME LAYER ----

, RENAME_ZZ as (
    SELECT
        LNK_INSTALLATION_DETAIL_HK
      , LOAD_DTS
      , MANDT
      , INSTALLRECID
      , GLREQUEST
      , LIFNR
      , VENDINVOICEID
      , VENDINVOICEDATE
      , ORDERID
      , CONTRACTORID
      , INVOICEITEMID
      , SERVICESKU
      , SERVICENAME
      , SERVICEQTY
      , INVOICEAMT
      , INSTALLDATE
      , COMPLETEDATE
      , WAERK
      , ERNAM
      , ERDAT
      , ERZET
      , VBELN
      , POSNR
      , KUNNR
      , INSTALLMATNR
      , PRODUCTINSTALLED
      , PRODUCT_POSNR
      , ABGRU
      , VBELN_VL
      , POSNR_VL
      , LFIMG
      , VRKME
      , INSTALLWADAT
      , PRODUCTWADAT
      , PROD_VBELN_VL
      , PROD_POSNR_VL
      , CONFIRMNEEDED
      , CONFIRMCOMP
      , CONFSTATUS
      , CONFIRMDATE
      , CONFIRMTIME
      , GLDELFLAG
      , GLSOURCESYSTEM
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_ZZ
)
---- FILTER LAYER ----

, FILTER_ZZ as (
    SELECT *
    FROM RENAME_ZZ
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_ZZ
)

---- FINAL LAYER ----
SELECT
          LNK_INSTALLATION_DETAIL_HK
        , LOAD_DTS
        , MANDT
        , INSTALLRECID
        , GLREQUEST
        , LIFNR
        , VENDINVOICEID
        , VENDINVOICEDATE
        , ORDERID
        , CONTRACTORID
        , INVOICEITEMID
        , SERVICESKU
        , SERVICENAME
        , SERVICEQTY
        , INVOICEAMT
        , INSTALLDATE
        , COMPLETEDATE
        , WAERK
        , ERNAM
        , ERDAT
        , ERZET
        , VBELN
        , POSNR
        , KUNNR
        , INSTALLMATNR
        , PRODUCTINSTALLED
        , PRODUCT_POSNR
        , ABGRU
        , VBELN_VL
        , POSNR_VL
        , LFIMG
        , VRKME
        , INSTALLWADAT
        , PRODUCTWADAT
        , PROD_VBELN_VL
        , PROD_POSNR_VL
        , CONFIRMNEEDED
        , CONFIRMCOMP
        , CONFSTATUS
        , CONFIRMDATE
        , CONFIRMTIME
        , GLDELFLAG
        , GLSOURCESYSTEM
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.LNK_INSTALLATION_DETAIL_HK = JOIN_RESULT.LNK_INSTALLATION_DETAIL_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
qualify 1= row_number()over(partition by LNK_INSTALLATION_DETAIL_HK, HASHDIFF order by LOAD_DTS)
{% if not is_incremental() %}
union all
SELECT
MD5_BINARY(GR.VALUE) AS LNK_INSTALLATION_DETAIL_HK
,CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
,null as MANDT
,null as INSTALLRECID
,null as GLREQUEST
,null as LIFNR
,null as VENDINVOICEID
,null as VENDINVOICEDATE
,null as ORDERID
,null as CONTRACTORID
,null as INVOICEITEMID
,null as SERVICESKU
,null as SERVICENAME
,null as SERVICEQTY
,null as INVOICEAMT
,null as INSTALLDATE
,null as COMPLETEDATE
,null as WAERK
,null as ERNAM
,null as ERDAT
,null as ERZET
,null as VBELN
,null as POSNR
,null as KUNNR
,null as INSTALLMATNR
,null as PRODUCTINSTALLED
,null as PRODUCT_POSNR
,null as ABGRU
,null as VBELN_VL
,null as POSNR_VL
,null as LFIMG
,null as VRKME
,null as INSTALLWADAT
,null as PRODUCTWADAT
,null as PROD_VBELN_VL
,null as PROD_POSNR_VL
,null as CONFIRMNEEDED
,null as CONFIRMCOMP
,null as CONFSTATUS
,null as CONFIRMDATE
,null as CONFIRMTIME
,null as GLDELFLAG
,null as GLSOURCESYSTEM
,null as GLCHANGETIME
,null as PSA_LOAD_DTS
,null as PSA_RECORD_SOURCE
,null as PSA_DELETE_IND
,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASHDIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

{% endif %}