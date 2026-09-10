with cte_sat_brand__ref_file as (

    select * from {{ ref('sat_brand__ref_file') }}
    
)

, cte_sat_brand__ref_file__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_brand__ref_file'
        ,hk_field='brand_hk') }}
)

select
hb.brand_hk
, coalesce (sb.system_brand,'') as system_brand
, coalesce (sb.business_unit,'') as business_unit
, coalesce (sb.brand,'') as brand
, coalesce (sb.sub_brand,sb.brand) as sub_brand
, sb.competitor  as competitor_ind
 from  {{ ref('hub_brand') }} hb
 left join cte_sat_brand__ref_file__latest sb
 on hb.brand_hk = sb.brand_hk