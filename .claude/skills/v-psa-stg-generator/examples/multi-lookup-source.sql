-- Example: Multi-lookup v_psa_stg model
-- Source: OCF AP Invoice Lines (driver table + terms lookup + vendor lookup)
-- Pattern: SRC → LOGIC → JOIN (LEFT JOINs + BKCC) → FINAL

WITH
--------------------------------------------------------------------
-- SRC LAYER
--------------------------------------------------------------------
SRC_S as (
    SELECT * FROM {{ source('ocf_prd', 'ap_invoice_lines_all') }} as SRC
),

SRC_R as (
    -- Terms lookup: get payment terms description
    SELECT TERM_ID, NAME AS TERMS_NAME
    FROM {{ source('ocf_prd', 'ap_terms') }} as SRC
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY TERM_ID ORDER BY PSA_LOAD_DTS DESC)) = 1
),

SRC_T as (
    -- Vendor lookup: get vendor name and segment
    SELECT VENDOR_ID, VENDOR_NAME, SEGMENT1 AS VENDOR_NUMBER
    FROM {{ source('ocf_prd', 'po_vendors') }} as SRC
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY VENDOR_ID ORDER BY PSA_LOAD_DTS DESC)) = 1
),

SRC_BKCC as (
    SELECT BKCC, REC_SRC
    FROM {{ ref('ref_business_key_collision') }}
    WHERE rec_src = 'USWIOC.ORCL.OCFPRD.AP_INVOICE_LINES_ALL'
),

--------------------------------------------------------------------
-- LOGIC LAYER
--------------------------------------------------------------------
LOGIC_S as (
    SELECT
        -- Business Keys
        CAST(INVOICE_ID AS VARCHAR) || '-' || CAST(LINE_NUMBER AS VARCHAR) AS INVOICE_LINE_BK,
        CAST(INVOICE_ID AS VARCHAR) AS INVOICE_BK,

        -- Hash Keys (raw source columns + BKCC)
        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(INVOICE_ID AS VARCHAR)), ''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(LINE_NUMBER AS VARCHAR)), ''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS INVOICE_LINE_HK,

        MD5_BINARY(UPPER(CONCAT_WS('||',
            COALESCE(NULLIF(TRIM(CAST(INVOICE_ID AS VARCHAR)), ''), '^^')
          , COALESCE(NULLIF(TRIM(CAST(BKCC AS VARCHAR)), ''), '^^')
        ))) AS INVOICE_HK,

        -- Link HK — composed from the participating HUB HK VALUES, not raw columns
        -- (DV 2.1, #1907), with NO BKCC (each hub HK embeds its own). A SELECT cannot
        -- reference a sibling alias, so the generator computes the hub HKs in a HASH_STG
        -- CTE and builds the link in FINAL:
        --   MD5_BINARY(UPPER(CONCAT_WS('||', TO_VARCHAR(INVOICE_LINE_HK), TO_VARCHAR(VENDOR_HK))))
        -- Declared via the auto multi-table path or
        -- --hk "LNK_INVOICE_LINE_VENDOR_HK:@INVOICE_LINE_HK,@VENDOR_HK".
        -- (Legacy raw-column composition byte-collided with the line hub HK — TRAP-01 —
        --  and is superseded; hub-HK values share no raw components.)

        -- HASHDIFF (data columns only)
        MD5_BINARY(UPPER(NULLIF(CONCAT(
                   IFNULL(TRIM(AMOUNT::text), '^^')
                 , '||', IFNULL(TRIM(DESCRIPTION::text), '^^')
                 , '||', IFNULL(TRIM(LINE_TYPE_LOOKUP_CODE::text), '^^')
                 , '||', IFNULL(TRIM(QUANTITY_INVOICED::text), '^^')
                 , '||', IFNULL(TRIM(UNIT_PRICE::text), '^^')
                 , '||', IFNULL(TRIM(PSA_DELETE_IND::text), '^^')
        ), '^^||^^'))) AS HASHDIFF,

        -- LOAD_DTS
        CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED) AS LOAD_DTS,  -- Fivetran sources; use PSA_LOAD_DTS for non-Fivetran

        -- Data columns
        IFNULL(CAST(AMOUNT AS NUMBER(15,2)), 0) AS INVOICE_AMOUNT,
        IFNULL(CAST(DESCRIPTION AS VARCHAR), '') AS LINE_DESCRIPTION,
        IFNULL(CAST(LINE_TYPE_LOOKUP_CODE AS VARCHAR), '') AS LINE_TYPE,
        IFNULL(CAST(QUANTITY_INVOICED AS NUMBER(15,4)), 0) AS QUANTITY_INVOICED,
        IFNULL(CAST(UNIT_PRICE AS NUMBER(15,4)), 0) AS UNIT_PRICE,
        IFNULL(CONVERT_TIMEZONE('UTC', CREATION_DATE), '1900-01-01'::TIMESTAMP) AS CREATION_DATE,

        -- Join keys for lookup tables
        VENDOR_ID,
        TERMS_ID,
        IFNULL(CAST(PSA_DELETE_IND AS VARCHAR), '') AS PSA_DELETE_IND

    FROM SRC_S
),

--------------------------------------------------------------------
-- JOIN LAYER
--------------------------------------------------------------------
JOIN_RESULT as (
    SELECT
        LOGIC_S.*,
        SRC_R.TERMS_NAME AS PAYMENT_TERMS_NAME,
        SRC_T.VENDOR_NAME,
        SRC_T.VENDOR_NUMBER,
        SRC_BKCC.BKCC,
        SRC_BKCC.REC_SRC
    FROM LOGIC_S
    LEFT JOIN SRC_R ON LOGIC_S.TERMS_ID = SRC_R.TERM_ID
    LEFT JOIN SRC_T ON LOGIC_S.VENDOR_ID = SRC_T.VENDOR_ID
    INNER JOIN SRC_BKCC ON '1' = '1'
),

--------------------------------------------------------------------
-- FINAL LAYER
--------------------------------------------------------------------
FINAL as (
    SELECT * FROM JOIN_RESULT
)

SELECT * FROM FINAL
