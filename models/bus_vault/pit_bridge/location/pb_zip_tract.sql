WITH lsat_zip_tract__snfl_usps AS (
    SELECT *
    FROM {{ ref('lsat_zip_tract__snfl_usps') }}
    QUALIFY (ROW_NUMBER() OVER (PARTITION BY LNK_ZIP_TRACT_HK ORDER BY LOAD_DTS DESC)) = 1
),
pb_zip_tract as (
SELECT
    ztract.TRACT_HK,
    lsztract.TRACT AS TRACT,
    lsztract.ZIP AS ZIP,
    lsztract.USPS_ZIP_PREF_CITY as USPS_ZIP_PREF_CITY,
    lsztract.USPS_ZIP_PREF_STATE as USPS_ZIP_PREF_STATE,
    lsztract.RES_RATIO as RES_RATIO,
    lsztract.BUS_RATIO as BUS_RATIO,
    lsztract.OTH_RATIO as OTH_RATIO,
    lsztract.TOT_RATIO as TOT_RATIO
FROM 
    {{ ref('lnk_zipcode_tract') }} ztract
    LEFT JOIN lsat_zip_tract__snfl_usps lsztract ON lsztract.LNK_ZIP_TRACT_HK = ztract.LNK_ZIP_TRACT_HK
)
select * from pb_zip_tract