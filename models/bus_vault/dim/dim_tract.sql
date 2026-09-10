SELECT
    TRACT_HK,
    TRACT,
    ZIP,
    RES_RATIO,
    BUS_RATIO,
    OTH_RATIO,
    TOT_RATIO
FROM 
    {{ ref('pb_zip_tract') }}