WITH lsat_zip_cbsa__snfl_usps AS (
    SELECT *
    FROM {{ ref('lsat_zip_cbsa__snfl_usps') }}
    QUALIFY (ROW_NUMBER() OVER (PARTITION BY LNK_ZIP_CBSA_HK ORDER BY LOAD_DTS DESC)) = 1
),
sat_cbsa__snfl_usps as (
    select *
    FROM {{ ref('sat_cbsa__snfl_usps') }}
    QUALIFY (ROW_NUMBER() OVER (PARTITION BY CBSA_HK ORDER BY LOAD_DTS DESC)) = 1
),
pb_zip_cbsa as (
SELECT
    zcbsa.ZIP_HK,
    zcbsa.CBSA_HK,
    scbsa.METRO_DIVISION_CODE AS METRO_DIVISION_CODE,
    scbsa.CBSA_CODE AS CBSA_CODE,
    scbsa.CSA_CODE AS CSA_CODE,
    scbsa.CBSA_TITLE AS CBSA_TITLE,
    scbsa.METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA AS METROPOLITAN_MICROPOLITAN_STATISTICAL_AREA,
    scbsa.COUNTY_COUNTY_EQUIVALENT AS COUNTY_COUNTY_EQUIVALENT,
    scbsa.STATE_NAME AS STATE_NAME,
    scbsa.FIPS_STATE_CODE AS FIPS_STATE_CODE,
    scbsa.FIPS_COUNTY_CODE AS FIPS_COUNTY_CODE,
    scbsa.FIPS_STATE_CODE || scbsa.FIPS_COUNTY_CODE as COUNTY,
    scbsa.CENTRAL_OUTLYING_COUNTY as CENTRAL_OUTLYING_COUNTY,
    lszcbsa.ZIP as ZIP,
    lszcbsa.USPS_ZIP_PREF_CITY as USPS_ZIP_PREF_CITY,
    lszcbsa.USPS_ZIP_PREF_STATE as USPS_ZIP_PREF_STATE,
    lszcbsa.RES_RATIO as RES_RATIO,
    lszcbsa.BUS_RATIO as BUS_RATIO,
    lszcbsa.OTH_RATIO as OTH_RATIO,
    lszcbsa.TOT_RATIO as TOT_RATIO
FROM 
    {{ ref('lnk_zipcode_cbsa') }} zcbsa
    LEFT JOIN lsat_zip_cbsa__snfl_usps lszcbsa ON lszcbsa.LNK_ZIP_CBSA_HK = zcbsa.LNK_ZIP_CBSA_HK
    left join sat_cbsa__snfl_usps scbsa on scbsa.cbsa_HK = zcbsa.cbsa_HK
)
select * from pb_zip_cbsa