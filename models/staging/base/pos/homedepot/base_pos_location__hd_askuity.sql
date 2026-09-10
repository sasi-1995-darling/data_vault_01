with location as (
    select
        to_char(d_store_nbr) as location_id,
        d_store_name as location_name,
        d_city as location_city,
        state_territory_code as location_state,
        d_postal_code as location_zip,
        d_lob as location_type,
        trim(substring(d_buying_office, position('-' IN d_buying_office) + 1)) AS byo_name,
        try_cast(trim(substring(d_buying_office, 1, position('-' IN d_buying_office) - 1)) AS float) AS byo_nbr,
        d_buying_office AS buying_office,
        d_country AS country,
        d_district AS district,
        trim(substring(d_district, position('-' IN d_district) + 1)) AS district_name,
        try_cast(trim(substring(d_district, 1, position('-' IN d_district) - 1)) AS varchar) AS district_nbr,
        d_division AS division,
        trim(substring(d_division, position('-' IN d_division) + 1)) AS division_name,
        try_cast(trim(substring(d_division, 1, position('-' IN d_division) - 1)) AS varchar) AS division_nbr,
        d_latitude AS latitude,
        d_longitude AS longitude,
        d_market AS market,
        trim(substring(d_market, position('-' IN d_market) + 1)) AS market_name,
        try_cast(trim(substring(d_market, 1, position('-' IN d_market) - 1)) AS varchar) AS market_nbr,
        d_region AS region,
        trim(substring(d_region, position('-' IN d_region) + 1)) AS region_name,
        try_cast(trim(substring(d_region, 1, position('-' IN d_region) - 1)) AS varchar) AS region_nbr,
        d_store AS store,
        d_store_address AS store_address,
        run_date
    from {{ source('homedepot_pos_askuity', 'hd_askuity_master_storeattributes') }}
)

select distinct
    location_id,
    first_value(location_name) OVER (PARTITION BY location_id ORDER BY run_date desc NULLS LAST) AS location_name,
    first_value(location_city) OVER (PARTITION BY location_id ORDER BY run_date desc NULLS LAST) AS location_city,
    first_value(location_state) OVER (PARTITION BY location_id ORDER BY run_date desc NULLS LAST) AS location_state,
    first_value(location_zip) OVER (PARTITION BY location_id ORDER BY run_date desc NULLS LAST) AS location_zip,
    first_value(location_type) OVER (PARTITION BY location_id ORDER BY run_date desc NULLS LAST) AS location_type,
    'HD_ASKUITY' as rec_src
from location

