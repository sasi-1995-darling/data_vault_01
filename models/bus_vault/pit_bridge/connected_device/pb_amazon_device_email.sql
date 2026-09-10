{#-
    pb_amazon_device_email
    ──────────────────────
    Identifies Flo device owners whose devices were sold through Amazon
    by tracing the SAP sales-order-to-delivery-to-serial chain where the
    sold-to customer (KNA1.NAME1) contains 'AMAZON', then resolving the
    serial number to a MAC_ID via the equipment/location-assignment chain,
    and finally mapping to the user email via pit_flo_device.

    SAP chain:
      sat_customer (NAME1 LIKE '%AMAZON%')
        → sat_order_header (KUNNR)
        → lsat_delivery_line_detail (VGBEL)
        → lsat_handling_unit_content (VBELN/POSNR)
        → lsat_serial_number_assignment (VENUM/VEPOS)
        → lsat_object_list_detail (OBKNR → SERNR)
        → sat_equipment (SERGE = SERNR → EQUIPMENT_HK)
        → lnk_equipment_location_assignment (EQUIPMENT_HK → LOCATION_ASSIGNMENT_HK)
        → lnk_location_assignment_detail (LOCATION_ASSIGNMENT_HK)
        → lsat_location_assignment_detail (EQFNR = MAC_ID)
        → pit_flo_device (DEVICE_ID → EMAIL)
-#}

---- SRC LAYER ----
---- Pattern: *_latest CTE picks the absolute latest row via QUALIFY with no pre-filtering.
----          Named CTE then applies deletion and business filters to that latest row only.
WITH
cust_latest AS (
    SELECT MANDT, KUNNR, NAME1, GLDELFLAG, PSA_DELETE_IND
    FROM {{ ref('sat_customer__winn_sap') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY CUSTOMER_HK ORDER BY LOAD_DTS DESC) = 1
),

cust AS (
    SELECT MANDT, KUNNR
    FROM cust_latest
    WHERE NAME1 ILIKE '%AMAZON%'
      AND COALESCE(GLDELFLAG, '') <> 'X'
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
),

oh_latest AS (
    SELECT MANDT, VBELN, KUNNR, GLDELFLAG, PSA_DELETE_IND
    FROM {{ ref('sat_order_header__winn_sap') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ORDER_HEADER_HK ORDER BY LOAD_DTS DESC) = 1
),

oh AS (
    SELECT MANDT, VBELN, KUNNR
    FROM oh_latest
    WHERE COALESCE(GLDELFLAG, '') <> 'X'
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
      AND KUNNR IS NOT NULL
),

dl_latest AS (
    SELECT MANDT, VBELN, POSNR, VGBEL, VGPOS, GLDELFLAG, PSA_DELETE_IND
    FROM {{ ref('lsat_delivery_line_detail__winn_sap') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY DELIVERY_LINE_DETAIL_LHK ORDER BY LOAD_DTS DESC) = 1
),

dl AS (
    SELECT MANDT, VBELN, POSNR, VGBEL, VGPOS
    FROM dl_latest
    WHERE COALESCE(GLDELFLAG, '') <> 'X'
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
      AND VGBEL IS NOT NULL
),

huc_latest AS (
    SELECT MANDT, VENUM, VEPOS, VBELN, POSNR, GLDELFLAG, PSA_DELETE_IND
    FROM {{ ref('lsat_handling_unit_content__winn_sap') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY LNK_HANDLING_UNIT_CONTENT_HK ORDER BY LOAD_DTS DESC) = 1
),

huc AS (
    SELECT MANDT, VENUM, VEPOS, VBELN, POSNR
    FROM huc_latest
    WHERE COALESCE(GLDELFLAG, '') <> 'X'
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
),

sa_latest AS (
    SELECT MANDT, OBKNR, VENUM, VEPOS, GLDELFLAG, PSA_DELETE_IND
    FROM {{ ref('lsat_serial_number_assignment__winn_sap') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY LNK_SERIAL_NUMBER_HU_ASSIGNMENT_HK ORDER BY LOAD_DTS DESC) = 1
),

sa AS (
    SELECT MANDT, OBKNR, VENUM, VEPOS
    FROM sa_latest
    WHERE COALESCE(GLDELFLAG, '') <> 'X'
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
),

ol_latest AS (
    SELECT MANDT, OBKNR, SERNR, TASER, GLDELFLAG, PSA_DELETE_IND
    FROM {{ ref('lsat_object_list_detail__winn_sap') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY LNK_OBJECT_LIST_DETAIL_HK ORDER BY LOAD_DTS DESC) = 1
),

ol AS (
    SELECT MANDT, OBKNR, UPPER(SERNR) AS SERNR
    FROM ol_latest
    WHERE COALESCE(GLDELFLAG, '') <> 'X'
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
      AND TASER = 'SER06'
      AND SERNR IS NOT NULL
),

equi_latest AS (
    SELECT EQUIPMENT_HK, SERGE, GLDELFLAG, PSA_DELETE_IND
    FROM {{ ref('sat_equipment__winn_sap') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY EQUIPMENT_HK ORDER BY LOAD_DTS DESC) = 1
),

equi AS (
    SELECT EQUIPMENT_HK, UPPER(SERGE) AS SERGE
    FROM equi_latest
    WHERE COALESCE(GLDELFLAG, '') <> 'X'
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
      AND SERGE IS NOT NULL
),

equz AS (
    SELECT EQUIPMENT_HK, LOCATION_ASSIGNMENT_HK
    FROM {{ ref('lnk_equipment_location_assignment') }}
),

iloa_lnk AS (
    SELECT LOCATION_ASSIGNMENT_HK, LNK_LOCATION_ASSIGNMENT_DETAIL_HK
    FROM {{ ref('lnk_location_assignment_detail') }}
),

iloa_latest AS (
    SELECT LNK_LOCATION_ASSIGNMENT_DETAIL_HK, EQFNR, GLDELFLAG, PSA_DELETE_IND
    FROM {{ ref('lsat_location_assignment_detail__winn_sap') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY LNK_LOCATION_ASSIGNMENT_DETAIL_HK ORDER BY LOAD_DTS DESC) = 1
),

iloa AS (
    SELECT LNK_LOCATION_ASSIGNMENT_DETAIL_HK, LOWER(EQFNR) AS DEVICE_ID
    FROM iloa_latest
    WHERE COALESCE(GLDELFLAG, '') <> 'X'
      AND COALESCE(PSA_DELETE_IND, 'N') = 'N'
      AND EQFNR IS NOT NULL
),

pfd AS (
    SELECT DEVICE_ID, EMAIL
    FROM {{ ref('pit_flo_device') }}
    WHERE EMAIL IS NOT NULL
),

---- LOGIC LAYER ----
amazon_orders AS (
    SELECT oh.MANDT, oh.VBELN
    FROM oh
    INNER JOIN cust
       ON oh.KUNNR = cust.KUNNR
      AND oh.MANDT = cust.MANDT
),

amazon_serials AS (
    SELECT ol.SERNR AS SERIAL_NUMBER
    FROM amazon_orders ao
    INNER JOIN dl
       ON dl.VGBEL = ao.VBELN
      AND dl.MANDT = ao.MANDT
    INNER JOIN huc
       ON huc.VBELN = dl.VBELN
      AND huc.POSNR = dl.POSNR
      AND huc.MANDT = dl.MANDT
    INNER JOIN sa
       ON sa.VENUM = huc.VENUM
      AND sa.VEPOS = huc.VEPOS
      AND sa.MANDT = huc.MANDT
    INNER JOIN ol
       ON ol.OBKNR = sa.OBKNR
      AND ol.MANDT = sa.MANDT
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ol.SERNR ORDER BY ol.SERNR) = 1
),

amazon_mac_ids AS (
    SELECT iloa.DEVICE_ID
    FROM amazon_serials aser
    INNER JOIN equi
       ON equi.SERGE = aser.SERIAL_NUMBER
    INNER JOIN equz
       ON equz.EQUIPMENT_HK = equi.EQUIPMENT_HK
    INNER JOIN iloa_lnk
       ON iloa_lnk.LOCATION_ASSIGNMENT_HK = equz.LOCATION_ASSIGNMENT_HK
    INNER JOIN iloa
       ON iloa.LNK_LOCATION_ASSIGNMENT_DETAIL_HK = iloa_lnk.LNK_LOCATION_ASSIGNMENT_DETAIL_HK
    QUALIFY ROW_NUMBER() OVER (PARTITION BY iloa.DEVICE_ID ORDER BY iloa.DEVICE_ID) = 1
),

amazon_emails AS (
    SELECT UPPER(pfd.EMAIL) AS EMAIL
    FROM amazon_mac_ids amac
    INNER JOIN pfd
       ON LOWER(pfd.DEVICE_ID) = amac.DEVICE_ID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY UPPER(pfd.EMAIL) ORDER BY UPPER(pfd.EMAIL)) = 1
),

---- FINAL LAYER ----
final AS (
    SELECT
        SEQ8()                                     AS SEQ_ID,
        CURRENT_DATE                               AS SNAPSHOTDATE,
        CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP) AS PB_LOAD_DTS,
        EMAIL
    FROM amazon_emails
)

SELECT * FROM final
