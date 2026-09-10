WITH lsat_zip_county__snfl_usps AS (
    SELECT *
    FROM {{ ref('lsat_zip_county__snfl_usps') }}
    QUALIFY (ROW_NUMBER() OVER (PARTITION BY LNK_ZIP_COUNTY_HK ORDER BY LOAD_DTS DESC)) = 1
),
sat_county__snfl_usps as (
    select *
    FROM {{ ref('sat_county__snfl_usps') }}
    QUALIFY (ROW_NUMBER() OVER (PARTITION BY COUNTY_HK ORDER BY LOAD_DTS DESC)) = 1
),
pb_zip_county as (
SELECT
    zcounty.ZIP_HK,
    zcounty.COUNTY_HK,
    lszcounty.ZIP AS ZIP,
    lszcounty.COUNTY AS COUNTY,
    lszcounty.USPS_ZIP_PREF_CITY AS USPS_ZIP_PREF_CITY,
    lszcounty.USPS_ZIP_PREF_STATE AS USPS_ZIP_PREF_STATE,
    lszcounty.RES_RATIO AS RES_RATIO,
    lszcounty.BUS_RATIO AS BUS_RATIO,
    lszcounty.OTH_RATIO AS OTH_RATIO,
    lszcounty.TOT_RATIO AS TOT_RATIO,
    scounty.ANSICODE as ANSICODE,
    scounty.NAME as COUNTY_NAME,
    scounty.POP10 as COUNTY_POPULATION_2010,
    scounty.HU10 as COUNTY_HOUSING_UNITS_2010,
    scounty.ALAND as COUNTY_LAND_AREA_SQMT,
    scounty.AWATER as COUNTY_WATER_AREA_SQMT,
    scounty.ALAND_SQMI as COUNTY_LAND_AREA_SQMI,
    scounty.AWATER_SQMI as COUNTY_WATER_AREA_SQMI,
    scounty.INTPTLAT as COUNTY_LATITUDE,
    scounty.INTPTLONG as COUNTY_LONGITUDE
FROM 
    {{ ref('lnk_zipcode_county') }} zcounty
    LEFT JOIN lsat_zip_county__snfl_usps lszcounty ON lszcounty.LNK_ZIP_COUNTY_HK = zcounty.LNK_ZIP_COUNTY_HK
    left join sat_county__snfl_usps scounty on scounty.COUNTY_HK = zcounty.COUNTY_HK
)
select * from pb_zip_county
