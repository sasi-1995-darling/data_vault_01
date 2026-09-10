WITH
hub AS (
    SELECT DEVICE_HK, DEVICE_BK, BKCC, REC_SRC
    FROM {{ ref('hub_device_v2') }}
    WHERE BKCC NOT LIKE 'GHOST%'
),
lid AS (
    SELECT DEVICE_HK, PAIRED_DEVICE_HK
    FROM {{ ref('lnk_icd_device') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY DEVICE_HK ORDER BY LOAD_DTS DESC) = 1
),
dev AS (
    SELECT PAIRED_DEVICE_HK, LOCATION_ID
    FROM {{ ref('sat_paired_device__flo_dynamodb') }}
    WHERE COALESCE(_FIVETRAN_DELETED, FALSE) = FALSE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY PAIRED_DEVICE_HK ORDER BY LOAD_DTS DESC) = 1
),
inv AS (
    SELECT DEVICE_HK, SERIAL_NUMBER
    FROM {{ ref('sat_device_inventory__flo_public') }}
    WHERE SERIAL_NUMBER IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY DEVICE_HK ORDER BY LOAD_DTS DESC) = 1
),
ulr AS (
    SELECT DEVICE_LOCATION_HK, FLO_USER_HK
    FROM {{ ref('lnk_user_location_role') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY DEVICE_LOCATION_HK ORDER BY LOAD_DTS DESC) = 1
),
usr_email AS (
    SELECT FLO_USER_HK, EMAIL
    FROM {{ ref('sat_flo_user_details__flo_dynamodb') }}
    WHERE COALESCE(_FIVETRAN_DELETED, FALSE) = FALSE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY FLO_USER_HK ORDER BY LOAD_DTS DESC) = 1
),
usr_phone AS (
    SELECT FLO_USER_HK, PHONE_MOBILE
    FROM {{ ref('sat_flo_user_profile__flo_dynamodb') }}
    WHERE COALESCE(_FIVETRAN_DELETED, FALSE) = FALSE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY FLO_USER_HK ORDER BY LOAD_DTS DESC) = 1
),
usr_name AS (
    SELECT FLO_USER_HK, FIRSTNAME, LASTNAME
    FROM {{ ref('sat_flo_user_profile__flo_dynamodb') }}
    WHERE COALESCE(_FIVETRAN_DELETED, FALSE) = FALSE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY FLO_USER_HK ORDER BY LOAD_DTS DESC) = 1
),
loc AS (
    SELECT DEVICE_LOCATION_HK, ADDRESS, CITY, STATE, POSTALCODE
    FROM {{ ref('sat_device_location_details__flo_dynamodb') }}
    WHERE COALESCE(_FIVETRAN_DELETED, FALSE) = FALSE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY DEVICE_LOCATION_HK ORDER BY LOAD_DTS DESC) = 1
),
online_dates AS (
    SELECT DEVICE_HK, MAX(AGGREGATE_DATE) AS LAST_ONLINE_DATE
    FROM {{ ref('sat_device_telemetry__flo_daily') }}
    WHERE AVG_PRESSURE > 5
    GROUP BY DEVICE_HK
),
water_usage AS (
    SELECT DISTINCT DEVICE_HK
    FROM {{ ref('sat_device_telemetry__flo_daily') }}
    WHERE AVG_PRESSURE > 5 AND RECORDS > 10000 AND AGGREGATE_DATE > CURRENT_DATE - 30
),
install_dates AS (
    -- + LNK_ICD_DEVICE to get DEVICE_HK for the join.
    SELECT lid2.DEVICE_HK, MAX(ev.CREATED_AT)::DATE AS MOEN_INSTALL_ACTIVE_DATE
    FROM {{ ref('sat_paired_device_event__flo_dynamodb') }} ev
    JOIN {{ ref('hub_paired_device') }} hpd
      ON hpd.PAIRED_DEVICE_BK = ev.ICD_ID
    JOIN {{ ref('lnk_icd_device') }} lid2
      ON lid2.PAIRED_DEVICE_HK = hpd.PAIRED_DEVICE_HK
    WHERE COALESCE(ev._FIVETRAN_DELETED, FALSE) = FALSE
      AND ev.EVENT = 2
    GROUP BY lid2.DEVICE_HK
),
paired_dates AS (
    SELECT lid2.DEVICE_HK, MIN(ev.CREATED_AT)::DATE AS PAIRED_DATE
    FROM {{ ref('sat_paired_device_event__flo_dynamodb') }} ev
    JOIN {{ ref('hub_paired_device') }} hpd
      ON hpd.PAIRED_DEVICE_BK = ev.ICD_ID
    JOIN {{ ref('lnk_icd_device') }} lid2
      ON lid2.PAIRED_DEVICE_HK = hpd.PAIRED_DEVICE_HK
    WHERE COALESCE(ev._FIVETRAN_DELETED, FALSE) = FALSE
      AND ev.EVENT = 1
    GROUP BY lid2.DEVICE_HK
)

SELECT
    ROW_NUMBER() OVER (ORDER BY 1)             AS SEQ_ID,
    CURRENT_DATE                               AS SNAPSHOTDATE,
    CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP) AS PIT_LOAD_DTS,
    hub.DEVICE_BK                              AS DEVICE_ID,
    hub.BKCC                                   AS BKCC,
    hub.REC_SRC                                AS REC_SRC,
    inv.SERIAL_NUMBER,
    fu.FLO_USER_BK                             AS USER_ID,
    un.FIRSTNAME, un.LASTNAME, ue.EMAIL, uph.PHONE_MOBILE,
    l.ADDRESS, l.CITY, l.STATE, l.POSTALCODE,
    id.MOEN_INSTALL_ACTIVE_DATE,
    pd.PAIRED_DATE,
    pd.PAIRED_DATE IS NOT NULL                 AS IS_PAIRED,
    od.LAST_ONLINE_DATE,
    wu.DEVICE_HK IS NOT NULL                   AS WATER_USAGE_LAST_MONTH
FROM hub
LEFT JOIN lid
  ON lid.DEVICE_HK = hub.DEVICE_HK
LEFT JOIN dev
  ON dev.PAIRED_DEVICE_HK = lid.PAIRED_DEVICE_HK
LEFT JOIN inv
  ON inv.DEVICE_HK = hub.DEVICE_HK
LEFT JOIN {{ ref('hub_device_location') }} dl
  ON dl.DEVICE_LOCATION_BK = dev.LOCATION_ID
LEFT JOIN ulr
  ON ulr.DEVICE_LOCATION_HK = dl.DEVICE_LOCATION_HK
LEFT JOIN {{ ref('hub_flo_user') }} fu
  ON fu.FLO_USER_HK = ulr.FLO_USER_HK
LEFT JOIN usr_email ue
  ON ue.FLO_USER_HK = ulr.FLO_USER_HK
LEFT JOIN usr_phone uph
  ON uph.FLO_USER_HK = ulr.FLO_USER_HK
LEFT JOIN usr_name un
  ON un.FLO_USER_HK = ulr.FLO_USER_HK
LEFT JOIN loc l
  ON l.DEVICE_LOCATION_HK = dl.DEVICE_LOCATION_HK
LEFT JOIN online_dates od
  ON od.DEVICE_HK = hub.DEVICE_HK
LEFT JOIN water_usage wu
  ON wu.DEVICE_HK = hub.DEVICE_HK
LEFT JOIN install_dates id
  ON id.DEVICE_HK = hub.DEVICE_HK
LEFT JOIN paired_dates pd
  ON pd.DEVICE_HK = hub.DEVICE_HK
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY hub.DEVICE_BK
    ORDER BY pd.PAIRED_DATE              DESC NULLS LAST,
             id.MOEN_INSTALL_ACTIVE_DATE DESC NULLS LAST,
             od.LAST_ONLINE_DATE         DESC NULLS LAST,
             fu.FLO_USER_BK              ASC  NULLS LAST
) = 1