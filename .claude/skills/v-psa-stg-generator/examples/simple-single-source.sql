-- Example: Simple single-source v_psa_stg model
-- Source: SAP ECC PO Header (single driver table, no lookups)
-- Pattern: SRC → LOGIC → JOIN (BKCC only) → FINAL

WITH
--------------------------------------------------------------------
-- SRC LAYER
--------------------------------------------------------------------
SRC_S as (
    SELECT * FROM {{ source('sap_ecc_prd', 'z_ekko') }} as SRC
),

SRC_BKCC as (
    SELECT BKCC, REC_SRC
    FROM {{ ref('ref_business_key_collision') }}
    WHERE rec_src = 'USOHNO.SAP.ECCPRD.Z_EKKO'
),

--------------------------------------------------------------------
-- LOGIC LAYER
--------------------------------------------------------------------
LOGIC_S as (
    SELECT
        -- Business Key
        CAST(EBELN AS VARCHAR) AS PO_HEADER_BK,

        -- Hash Key (raw columns + BKCC placeholder)
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(EBELN AS VARCHAR)), ''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS PO_HEADER_HK,

        -- HASHDIFF (all data columns, excludes BK + metadata)
        MD5_BINARY(UPPER(NULLIF(CONCAT(
              IFNULL(TRIM(BUKRS::text), '^^')
            , '||', IFNULL(TRIM(BSART::text), '^^')
            , '||', IFNULL(TRIM(EKGRP::text), '^^')
            , '||', IFNULL(TRIM(EKORG::text), '^^')
            , '||', IFNULL(TRIM(LIFNR::text), '^^')
            , '||', IFNULL(TRIM(WAERS::text), '^^')
            , '||', IFNULL(TRIM(WKURS::text), '^^')
            , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^'))) AS HASHDIFF,

        -- LOAD_DTS
        CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) AS LOAD_DTS,  -- Fivetran sources; use PSA_LOAD_DTS for non-Fivetran

        -- Data columns
        IFNULL(CAST(BUKRS AS VARCHAR), '') AS COMPANY_CODE,
        IFNULL(CAST(BSART AS VARCHAR), '') AS PO_DOC_TYPE,
        IFNULL(CAST(EKGRP AS VARCHAR), '') AS PURCHASING_GROUP,
        IFNULL(CAST(EKORG AS VARCHAR), '') AS PURCHASING_ORG,
        IFNULL(CAST(LIFNR AS VARCHAR), '') AS VENDOR_NUMBER,
        IFNULL(CAST(WAERS AS VARCHAR), '') AS CURRENCY_CODE,
        IFNULL(CAST(WKURS AS NUMBER(15,2)), 0) AS EXCHANGE_RATE,
        IFNULL(CONVERT_TIMEZONE('UTC', AEDAT), '1900-01-01'::TIMESTAMP) AS PO_CHANGE_DATE,
        IFNULL(CAST(PSA_DELETE_IND AS VARCHAR), '') AS PSA_DELETE_IND

    FROM SRC_S
),

--------------------------------------------------------------------
-- JOIN LAYER
--------------------------------------------------------------------
JOIN_RESULT as (
    SELECT
        LOGIC_S.*,
        SRC_BKCC.BKCC,
        SRC_BKCC.REC_SRC
    FROM LOGIC_S
    INNER JOIN SRC_BKCC ON '1' = '1'
),

--------------------------------------------------------------------
-- FINAL LAYER
--------------------------------------------------------------------
FINAL as (
    SELECT * FROM JOIN_RESULT
)

SELECT * FROM FINAL
