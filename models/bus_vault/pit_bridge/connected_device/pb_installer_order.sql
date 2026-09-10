WITH

---- SRC LAYER ----

SRC_PB AS (
    SELECT
        ORDER_ID,
        SHOPIFY_NUMERIC_ID,
        ORDER_DATE,
        ORDER_FIRST_NAME,
        ORDER_LAST_NAME,
        ORDER_EMAIL,
        ORDER_PHONE,
        ORDER_ADDRESS_1,
        ORDER_ADDRESS_2,
        ORDER_CITY,
        ORDER_STATE,
        ORDER_POSTCODE,
        ORDER_POSTCODE_ADD_ON,
        ORDER_STATUS,
        ORDER_TAG,
        ORDER_QUANTITY,
        RETURN_QUANTITY,
        ACTUAL_DELIVERY_DATE,
        SKU,
        VALVE_SIZE,
        LASTMODIFIED,
        IS_PAIRED,
        PAIRED_DATE,
        MOEN_INSTALL_ACTIVE_DATE,
        SERIAL_ID,
        DEVICE_ID,
        INSTALLATION_ADDRESS_LINE1,
        INSTALLATION_ADDRESS_LINE2,
        INSTALLATION_CITY,
        INSTALLATION_STATE,
        INSTALLATION_ZIP,
        ORDER_LINE_ID,
        INSTALLATION_FLAG,
        PARTNER_NUMBER,
        BKCC,
        REC_SRC
    FROM {{ ref('pb_insurance_order_device_matched') }}
    WHERE INSTALLATION_FLAG = TRUE
      AND COALESCE(ORDER_TAG, '') != 'TurbineUpgrade'
),

SRC_NOTES AS (
    SELECT
        ID,
        NOTE_ATTRIBUTES,
        _FIVETRAN_DELETED,
        PSA_DELETE_IND
    FROM {{ ref('lsat_order_customer_consumer__winn_shopify') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY LOAD_DTS DESC) = 1
),

-- Post-dedup filter: exclude records whose latest version is deleted.
-- WHERE before QUALIFY would promote stale undeleted versions instead.
SRC_NOTES_ACTIVE AS (
    SELECT ID, NOTE_ATTRIBUTES
    FROM SRC_NOTES
    WHERE COALESCE(_FIVETRAN_DELETED, FALSE) = FALSE
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
),

SRC_PARTNERS AS (
    SELECT
        _PARTNER_NUMBER AS PARTNER_NUMBER,
        BUSINESS_NAME   AS INSURANCE_PARTNER,
        _FIVETRAN_DELETED,
        PSA_DELETE_IND
    FROM {{ source('custom_fivetran_smartsheet_flo_insurance_partner', 'insurance_partner_name') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY _PARTNER_NUMBER
        ORDER BY MODIFIED_AT DESC NULLS LAST, _FIVETRAN_SYNCED DESC NULLS LAST, ID DESC
    ) = 1
),

-- Post-dedup filter: exclude records whose latest version is deleted.
SRC_PARTNERS_ACTIVE AS (
    SELECT PARTNER_NUMBER, INSURANCE_PARTNER
    FROM SRC_PARTNERS
    WHERE COALESCE(_FIVETRAN_DELETED, FALSE) = FALSE
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
),

SRC_INSTALLER AS (
    SELECT
        INSTALLER_YA_TAG,
        INSTALLER_NAME
    FROM {{ ref('ref_installer') }}
),

---- LOGIC LAYER ----

LOGIC_DEDUP AS (
    SELECT *
    FROM SRC_PB
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ORDER_ID, SKU, ORDER_LINE_ID, COALESCE(SERIAL_ID, '^^')
        ORDER BY
            CASE WHEN ORDER_TAG LIKE 'YO_%' THEN 0
                 WHEN ORDER_TAG LIKE 'YA_%' THEN 1
                 ELSE 2 END,
            LASTMODIFIED DESC
    ) = 1
),

LOGIC_YA_TAGS AS (
    SELECT
        ORDER_ID,
        ORDER_TAG AS YA_TAG
    FROM SRC_PB
    WHERE ORDER_TAG LIKE 'YA_%'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ORDER_ID ORDER BY LASTMODIFIED DESC) = 1
),

LOGIC_INSTALLER AS (
    SELECT
        n.ID AS SHOPIFY_NUMERIC_ID,
        MAX(IFF(f.VALUE:name::STRING = 'installer_ya_tag', f.VALUE:value::STRING, NULL))                                     AS INSTALLER_YA_TAG,
        MAX(IFF(f.VALUE:name::STRING = 'preferred_installer', f.VALUE:value::STRING, NULL))                                   AS PREFERRED_INSTALLER,
        MAX(IFF(f.VALUE:name::STRING = 'Zigpoll: Select Your Preferred Installation Times', f.VALUE:value::STRING, NULL))     AS ZIGPOLL_INSTALL_TIMES
    FROM SRC_NOTES_ACTIVE n,
        LATERAL FLATTEN(INPUT => TRY_PARSE_JSON(n.NOTE_ATTRIBUTES), OUTER => TRUE) f
    GROUP BY n.ID
),

LOGIC_EXCLUSION_FLAGS AS (
    SELECT
        ORDER_ID,
        MAX(IFF(ORDER_TAG = 'High risk cancelled', TRUE, FALSE)) AS HAS_HIGH_RISK_TAG
    FROM SRC_PB
    GROUP BY ORDER_ID
),

---- JOIN LAYER ----

JOIN_ENRICHED AS (
    SELECT
        d.*,
        ya.YA_TAG,
        inst.INSTALLER_YA_TAG  AS NOTE_INSTALLER_YA_TAG,
        inst.PREFERRED_INSTALLER,
        inst.ZIGPOLL_INSTALL_TIMES,
        excl.HAS_HIGH_RISK_TAG,
        p.INSURANCE_PARTNER,
        iref.INSTALLER_NAME AS INSTALLER_REF_NAME
    FROM LOGIC_DEDUP d
    LEFT JOIN LOGIC_YA_TAGS ya
        ON ya.ORDER_ID = d.ORDER_ID
    LEFT JOIN LOGIC_INSTALLER inst
        ON inst.SHOPIFY_NUMERIC_ID = d.SHOPIFY_NUMERIC_ID
    LEFT JOIN LOGIC_EXCLUSION_FLAGS excl
        ON excl.ORDER_ID = d.ORDER_ID
    LEFT JOIN SRC_PARTNERS_ACTIVE p
        ON p.PARTNER_NUMBER = COALESCE(d.PARTNER_NUMBER, d.ORDER_TAG)
    LEFT JOIN SRC_INSTALLER iref
        ON iref.INSTALLER_YA_TAG = COALESCE(inst.INSTALLER_YA_TAG, ya.YA_TAG,
               IFF(d.ORDER_TAG LIKE 'YA_%', d.ORDER_TAG, NULL))
)

---- FINAL LAYER ----

SELECT
    j.ORDER_ID,
    j.SHOPIFY_NUMERIC_ID,
    j.ORDER_DATE,
    j.ORDER_FIRST_NAME,
    j.ORDER_LAST_NAME,
    j.ORDER_EMAIL,
    j.ORDER_PHONE,
    j.ORDER_ADDRESS_1,
    j.ORDER_ADDRESS_2,
    j.ORDER_CITY,
    j.ORDER_STATE,
    j.ORDER_POSTCODE,
    j.ORDER_POSTCODE_ADD_ON,
    j.ORDER_STATUS,
    -- Intentional: ORDER_TAG is remapped to insurance partner business name (e.g., 'FARMERS GROUP INC')
    -- to match the existing DT share contract. The raw Shopify tag (YA_*/YO_*) is not exposed externally.
    j.INSURANCE_PARTNER                                                          AS ORDER_TAG,
    j.ORDER_QUANTITY,
    j.RETURN_QUANTITY,
    j.ACTUAL_DELIVERY_DATE,
    j.SKU,
    j.VALVE_SIZE,
    j.LASTMODIFIED                                                               AS ORDER_STATUS_MODIFIED,
    GREATEST_IGNORE_NULLS(j.LASTMODIFIED, j.MOEN_INSTALL_ACTIVE_DATE,
                          j.PAIRED_DATE)                                         AS LASTMODIFIED,
    j.IS_PAIRED,
    j.PAIRED_DATE,
    j.MOEN_INSTALL_ACTIVE_DATE,
    j.SERIAL_ID,
    j.DEVICE_ID,
    j.INSTALLATION_ADDRESS_LINE1,
    j.INSTALLATION_ADDRESS_LINE2,
    j.INSTALLATION_CITY,
    j.INSTALLATION_STATE,
    j.INSTALLATION_ZIP,
    COALESCE(NULLIF(j.PREFERRED_INSTALLER, ''), j.INSTALLER_REF_NAME)           AS INSTALLER_NAME,
    COALESCE(
        j.NOTE_INSTALLER_YA_TAG,
        j.YA_TAG,
        IFF(j.ORDER_TAG LIKE 'YA_%', j.ORDER_TAG, NULL)
    )                                                                            AS INSTALLER_YA_TAG,
    NULLIF(NULLIF(TRIM(
        COALESCE(REGEXP_SUBSTR(j.ZIGPOLL_INSTALL_TIMES, 'Preferred Date: 1: ([^,]*)', 1, 1, 'e', 1), '') || ' ' ||
        COALESCE(REGEXP_SUBSTR(j.ZIGPOLL_INSTALL_TIMES, 'Preferred Time: 1: ([^,]*)', 1, 1, 'e', 1), '')
    ), 'Not Submitted Not Submitted'), '')                                       AS INSTALL_PREFERRED_DATE_TIME1,
    NULLIF(NULLIF(TRIM(
        COALESCE(REGEXP_SUBSTR(j.ZIGPOLL_INSTALL_TIMES, 'Preferred Date: 2: ([^,]*)', 1, 1, 'e', 1), '') || ' ' ||
        COALESCE(REGEXP_SUBSTR(j.ZIGPOLL_INSTALL_TIMES, 'Preferred Time: 2: ([^,]*)', 1, 1, 'e', 1), '')
    ), 'Not Submitted Not Submitted'), '')                                       AS INSTALL_PREFERRED_DATE_TIME2,
    NULLIF(NULLIF(TRIM(
        COALESCE(REGEXP_SUBSTR(j.ZIGPOLL_INSTALL_TIMES, 'Preferred Date: 3: ([^,]*)', 1, 1, 'e', 1), '') || ' ' ||
        COALESCE(REGEXP_SUBSTR(j.ZIGPOLL_INSTALL_TIMES, 'Preferred Time: 3: ([^,]*)', 1, 1, 'e', 1), '')
    ), 'Not Submitted Not Submitted'), '')                                       AS INSTALL_PREFERRED_DATE_TIME3,
    CASE
        WHEN j.ZIGPOLL_INSTALL_TIMES ILIKE '%I prefer to be contacted later by the installer to request times%'
            THEN 'Y'
        ELSE 'N'
    END                                                                          AS INSTALL_CAN_BE_CONTACTED_FLAG,
    j.ORDER_LINE_ID,
    j.INSTALLATION_FLAG,
    j.HAS_HIGH_RISK_TAG,
    COALESCE(j.SERIAL_ID, '^^')                                                 AS GRAIN_KEY,
    j.BKCC,
    j.REC_SRC,
    CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP)                                   AS PB_LOAD_DTS
FROM JOIN_ENRICHED j
