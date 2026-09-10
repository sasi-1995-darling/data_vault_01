---- SRC LAYER ----
WITH
SRC_CEC            as ( SELECT * FROM {{ ref('v_psa_stg_cost_estimate_component__moen_sap') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_CEC            as ( SELECT * FROM STAGING.v_psa_stg_cost_estimate_component__moen_sap )
*/
---- LOGIC LAYER ----

, LOGIC_CEC as (
    SELECT
        MANDT
      , BZOBJ
      , KALNR
      , KALKA
      , KADKY
      , TVERS
      , BWVAR
      , KKZMA
      , PATNR
      , KEART
      , LOSFX
      , KKZST
      , KKZMM
      , LOAD_DTS
      , MATNR
      , ITEM_BK
      , ITEM_HK
      , WERKS
      , PLANT_BK
      , PLANT_HK
      , POPER
      , BDATJ
      , KLVAR
      , DIPA
      , KST001
      , KST002
      , KST003
      , KST004
      , KST005
      , KST006
      , KST007
      , KST008
      , KST009
      , KST010
      , KST011
      , KST012
      , KST013
      , KST014
      , KST015
      , KST016
      , KST017
      , KST018
      , KST019
      , KST020
      , KST021
      , KST022
      , KST023
      , KST024
      , KST025
      , KST026
      , KST027
      , KST028
      , KST029
      , KST030
      , KST031
      , KST032
      , KST033
      , KST034
      , KST035
      , KST036
      , KST037
      , KST038
      , KST039
      , KST040
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , REC_SRC
      , BKCC
      , PRODUCT_COST_ESTIMATE_HK
      , HASHDIFF
    FROM SRC_CEC
)
---- RENAME LAYER ----

, RENAME_CEC as (
    SELECT
        MANDT
      , BZOBJ
      , KALNR
      , KALKA
      , KADKY
      , TVERS
      , BWVAR
      , KKZMA
      , PATNR
      , KEART
      , LOSFX
      , KKZST
      , KKZMM
      , LOAD_DTS
      , MATNR
      , ITEM_BK
      , ITEM_HK
      , WERKS
      , PLANT_BK
      , PLANT_HK
      , POPER
      , BDATJ
      , KLVAR
      , DIPA
      , KST001
      , KST002
      , KST003
      , KST004
      , KST005
      , KST006
      , KST007
      , KST008
      , KST009
      , KST010
      , KST011
      , KST012
      , KST013
      , KST014
      , KST015
      , KST016
      , KST017
      , KST018
      , KST019
      , KST020
      , KST021
      , KST022
      , KST023
      , KST024
      , KST025
      , KST026
      , KST027
      , KST028
      , KST029
      , KST030
      , KST031
      , KST032
      , KST033
      , KST034
      , KST035
      , KST036
      , KST037
      , KST038
      , KST039
      , KST040
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , PSA_LOAD_DTS
      , REC_SRC
      , BKCC
      , PRODUCT_COST_ESTIMATE_HK
      , HASHDIFF
    FROM LOGIC_CEC
)
---- FILTER LAYER ----

, FILTER_CEC as (
    SELECT *
    FROM RENAME_CEC
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_CEC
)

---- FINAL LAYER ----
SELECT
          MANDT
        , BZOBJ
        , KALNR
        , KALKA
        , KADKY
        , TVERS
        , BWVAR
        , KKZMA
        , PATNR
        , KEART
        , LOSFX
        , KKZST
        , KKZMM
        , LOAD_DTS
        , MATNR
        , ITEM_BK
        , ITEM_HK
        , WERKS
        , PLANT_BK
        , PLANT_HK
        , POPER
        , BDATJ
        , KLVAR
        , DIPA
        , KST001
        , KST002
        , KST003
        , KST004
        , KST005
        , KST006
        , KST007
        , KST008
        , KST009
        , KST010
        , KST011
        , KST012
        , KST013
        , KST014
        , KST015
        , KST016
        , KST017
        , KST018
        , KST019
        , KST020
        , KST021
        , KST022
        , KST023
        , KST024
        , KST025
        , KST026
        , KST027
        , KST028
        , KST029
        , KST030
        , KST031
        , KST032
        , KST033
        , KST034
        , KST035
        , KST036
        , KST037
        , KST038
        , KST039
        , KST040
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , PSA_LOAD_DTS
        , REC_SRC
        , BKCC
        , PRODUCT_COST_ESTIMATE_HK
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.MANDT = JOIN_RESULT.MANDT 
	AND existing.BZOBJ=JOIN_RESULT.BZOBJ
	AND existing.KALNR=JOIN_RESULT.KALNR
	AND existing.KALKA=JOIN_RESULT.KALKA	
	AND existing.KADKY=JOIN_RESULT.KADKY
	AND existing.TVERS=JOIN_RESULT.TVERS
	AND existing.BWVAR=JOIN_RESULT.BWVAR	
	AND existing.KKZMA=JOIN_RESULT.KKZMA
	AND existing.PATNR=JOIN_RESULT.PATNR
	AND existing.KEART=JOIN_RESULT.KEART
	AND existing.LOSFX=JOIN_RESULT.LOSFX
	AND existing.KKZST=JOIN_RESULT.KKZST
	AND existing.KKZMM=JOIN_RESULT.KKZMM	
	AND existing.LOAD_DTS=JOIN_RESULT.LOAD_DTS	
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF	)
{% endif %}



{% if not is_incremental() %}
qualify 1=row_number() over(partition by MANDT,BZOBJ,KALNR,KALKA,KADKY,TVERS,BWVAR,KKZMA,PATNR,KEART,LOSFX,KKZST,KKZMM, hashdiff order by LOAD_DTS desc)
{% endif %}

{% if not is_incremental() %}
UNION ALL
SELECT
GR.VALUE AS MANDT,
GR.VALUE AS BZOBJ,
GR.VALUE AS KALNR,
GR.VALUE AS KALKA,
GR.VALUE AS KADKY,
GR.VALUE AS TVERS,
GR.VALUE AS BWVAR,
GR.VALUE AS KKZMA,
GR.VALUE AS PATNR,
GR.VALUE AS KEART,
GR.VALUE AS LOSFX,
GR.VALUE AS KKZST,
GR.VALUE AS KKZMM,
CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP_LTZ) AS LOAD_DTS,
NULL AS MATNR,
GR.VALUE AS ITEM_BK,
MD5_BINARY(GR.VALUE) AS ITEM_HK,
NULL AS WERKS,
GR.VALUE AS PLANT_BK,
MD5_BINARY(GR.VALUE) AS PLANT_HK,
NULL AS POPER,
NULL AS BDATJ,
NULL AS KLVAR,
NULL AS DIPA,
NULL AS KST001,
NULL AS KST002,
NULL AS KST003,
NULL AS KST004,
NULL AS KST005,
NULL AS KST006,
NULL AS KST007,
NULL AS KST008,
NULL AS KST009,
NULL AS KST010,
NULL AS KST011,
NULL AS KST012,
NULL AS KST013,
NULL AS KST014,
NULL AS KST015,
NULL AS KST016,
NULL AS KST017,
NULL AS KST018,
NULL AS KST019,
NULL AS KST020,
NULL AS KST021,
NULL AS KST022,
NULL AS KST023,
NULL AS KST024,
NULL AS KST025,
NULL AS KST026,
NULL AS KST027,
NULL AS KST028,
NULL AS KST029,
NULL AS KST030,
NULL AS KST031,
NULL AS KST032,
NULL AS KST033,
NULL AS KST034,
NULL AS KST035,
NULL AS KST036,
NULL AS KST037,
NULL AS KST038,
NULL AS KST039,
NULL AS KST040,
NULL AS PSA_RECORD_SOURCE,
NULL AS PSA_DELETE_IND,
NULL AS PSA_LOAD_DTS,
'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC,
DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC,
MD5_BINARY(GR.VALUE) AS PRODUCT_COST_ESTIMATE_HK,
MD5_BINARY(GR.VALUE) AS HASHDIFF
FROM
        TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}