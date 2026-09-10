---- SRC LAYER ----
WITH
SRC_eina           as ( SELECT * FROM {{ ref('v_psa_stg_purchasing_records__winn_sap') }} as SRC 
                        {% if is_incremental() %}
                              where src.load_dts > (select dateadd('HOUR',-1,max(load_dts)) from {{ this }})
                            {% endif %}   )

/*
SRC_eina           as ( SELECT * FROM STAGING.v_psa_stg_purchasing_record__winn )
*/
---- LOGIC LAYER ----

, LOGIC_eina as (
    SELECT
        PURCHASING_RECORD_HK
      , LOAD_DTS
      , MANDT
      , INFNR
      , GLREQUEST
      , GLSOURCESYSTEM
      , MATNR
      , MATKL
      , LIFNR
      , LOEKZ
      , ERDAT
      , ERNAM
      , TXZ01
      , SORTL
      , MEINS
      , UMREZ
      , UMREN
      , IDNLF
      , VERKF
      , TELF1
      , MAHN1
      , MAHN2
      , MAHN3
      , URZNR
      , URZDT
      , URZLA
      , URZTP
      , URZZT
      , LMEIN
      , REGIO
      , VABME
      , LTSNR
      , LTSSF
      , WGLIF
      , RUECK
      , LIFAB
      , LIFBI
      , KOLIF
      , ANZPU
      , PUNEI
      , RELIF
      , MFRNR
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM SRC_eina
)
---- RENAME LAYER ----

, RENAME_eina as (
    SELECT
        PURCHASING_RECORD_HK
      , LOAD_DTS
      , MANDT
      , INFNR
      , GLREQUEST
      , GLSOURCESYSTEM
      , MATNR
      , MATKL
      , LIFNR
      , LOEKZ
      , ERDAT
      , ERNAM
      , TXZ01
      , SORTL
      , MEINS
      , UMREZ
      , UMREN
      , IDNLF
      , VERKF
      , TELF1
      , MAHN1
      , MAHN2
      , MAHN3
      , URZNR
      , URZDT
      , URZLA
      , URZTP
      , URZZT
      , LMEIN
      , REGIO
      , VABME
      , LTSNR
      , LTSSF
      , WGLIF
      , RUECK
      , LIFAB
      , LIFBI
      , KOLIF
      , ANZPU
      , PUNEI
      , RELIF
      , MFRNR
      , GLDELFLAG
      , GLCHANGETIME
      , PSA_LOAD_DTS
      , PSA_DELETE_IND
      , REC_SRC
      , BKCC
      , HASHDIFF
    FROM LOGIC_eina
)
---- FILTER LAYER ----

, FILTER_eina as (
    SELECT *
    FROM RENAME_eina
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_eina
)

---- FINAL LAYER ----
SELECT
          PURCHASING_RECORD_HK
        , LOAD_DTS
        , MANDT
        , INFNR
        , GLREQUEST
        , GLSOURCESYSTEM
        , MATNR
        , MATKL
        , LIFNR
        , LOEKZ
        , ERDAT
        , ERNAM
        , TXZ01
        , SORTL
        , MEINS
        , UMREZ
        , UMREN
        , IDNLF
        , VERKF
        , TELF1
        , MAHN1
        , MAHN2
        , MAHN3
        , URZNR
        , URZDT
        , URZLA
        , URZTP
        , URZZT
        , LMEIN
        , REGIO
        , VABME
        , LTSNR
        , LTSSF
        , WGLIF
        , RUECK
        , LIFAB
        , LIFBI
        , KOLIF
        , ANZPU
        , PUNEI
        , RELIF
        , MFRNR
        , GLDELFLAG
        , GLCHANGETIME
        , PSA_LOAD_DTS
        , PSA_DELETE_IND
        , REC_SRC
        , BKCC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PURCHASING_RECORD_HK = JOIN_RESULT.PURCHASING_RECORD_HK 
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/* The following qualifier is implemented to prevent multiple loads of touched records during the initial build, such as multiple rows per HK and hashdiff. */
qualify 1= row_number()over(partition by PURCHASING_RECORD_HK, HASHDIFF order by PSA_LOAD_DTS)

union all
SELECT
         MD5_BINARY(GR.VALUE) AS PURCHASING_RECORD_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, NULL AS MANDT
, GR.VALUE AS INFNR
, NULL AS GLREQUEST
, NULL AS GLSOURCESYSTEM
, NULL AS MATNR
, NULL AS MATKL
, NULL AS LIFNR
, NULL AS LOEKZ
, NULL AS ERDAT
, NULL AS ERNAM
, NULL AS TXZ01
, NULL AS SORTL
, NULL AS MEINS
, NULL AS UMREZ
, NULL AS UMREN
, NULL AS IDNLF
, NULL AS VERKF
, NULL AS TELF1
, NULL AS MAHN1
, NULL AS MAHN2
, NULL AS MAHN3
, NULL AS URZNR
, NULL AS URZDT
, NULL AS URZLA
, NULL AS URZTP
, NULL AS URZZT
, NULL AS LMEIN
, NULL AS REGIO
, NULL AS VABME
, NULL AS LTSNR
, NULL AS LTSSF
, NULL AS WGLIF
, NULL AS RUECK
, NULL AS LIFAB
, NULL AS LIFBI
, NULL AS KOLIF
, NULL AS ANZPU
, NULL AS PUNEI
, NULL AS RELIF
, NULL AS MFRNR
, NULL AS GLDELFLAG
, NULL AS GLCHANGETIME
, '1900-01-01'::TIMESTAMP AS PSA_LOAD_DTS
, 'N' AS PSA_DELETE_IND
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
, DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional')  AS BKCC
, ''::BINARY as HASH_DIFF
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR

    {% endif %}