with 
cte_hub_store as (
    select *,
        case 
            when rec_src in('US.EXCEL.STOCK_MARKET.TSM_LOWES_US',
                            'US.API.LOWES_VPP.SALES_INVENTORY_MASTERLOCK',
                            'US.API.LOWES_VPP.SALES_INVENTORY',
                            'US.API.LOWES_VPP.SALES_INVENTORY_MOEN',
                            'US.EXCEL.LOWES_US.LOCATION',
                            'US.API.LOWES_VPP.SALES_INVENTORY_THERMATRU',
                            'US.API.LOWES_VPP.SALES_INVENTORY_LARSON',
                            'US.API.LOWES_VPP.STOCKED_STORES_ALL', --added API rec_src now included in hub 2025-09-26
                            'US.API_FT.LOWES_VPP.SALES_INVENTORY_MASTERLOCK',
                            'US.API_FT.LOWES_VPP.SALES_INVENTORY_MOEN',
                            'US.API_FT.LOWES_VPP.SALES_INVENTORY_THERMATRU',
                            'US.EXCEL.LOWES_US.LOCATION'
                            ) then 'LOWES' 
            when rec_src in('US.HIVE.ASKUITY.HD_ASKUITY_POS',
                            'US.HIVE.ASKUITY.HD_ASKUITY_MASTER_STOREATTRIBUTES',
                            'US.HIVE.ASKUITY.HD_ASKUITY_MASTER_POG_WEEKLY',
                            'US.HIVE.ASKUITY_FT.VENDOR_DRILL_DC_INV_DATA_WITH_STORE_US',
                            'US.HIVE.ASKUITY_FT.VENDOR_DRILL_STORE_ATTR_DATA_US') then 'HOME DEPOT' 
            when rec_src in('US.EXCEL.MENARDS.SALES_AND_INVENTORY',
                            'US.EXCEL.MENARDS.LOCATION_LOOKUP',
                            'US.EXCEL.MENARDS.MENARDS_STORE_HISTORY',
                            'US.EXCEL.MENARDS.MOEN_SALES_AND_INVENTORY_HISTORY', 
                            'US.EXCEL.MENARDS.SALES_AND_INVENTORY_LARSON',
                            'US.EXCEL.MENARDS.MOEN_SALES_AND_INVENTORY_WEEKLY') then 'MENARDS' 
            when rec_src in ('US.API.AMAZON_VC.SALES') then 'AMAZON'
            when rec_src in ('US.EXCEL.FERGUSON.MOEN_M_3_A_NEW_CFG',        --added ferguson pos rec_src to bring ferguson store data in 2025-08-27
                            'FBIN.SILVER.FERGUSON.FERGUSON_MOEN_GROSS_PRICE_NEW_STRUCTURE',
                            'US.EXCEL.FERGUSON.MOEN_M_3_A_NEW',
                            'US.EXCEL.FERGUSON.FF_FERGUSON_BRANCH_INDEX') then 'FERGUSON'
            else 'N/A' end as reporting_customer  from {{ ref('hub_store') }}
)
,
cte_sat_store__homedepot as (
    select
        *
        , 'HOME DEPOT' as reporting_customer
    from {{ ref('sat_store__homedepot') }}
)
,
cte_sat_store__homedepot__latest as (
    select * from cte_sat_store__homedepot
    qualify row_number() over (partition by store_hk order by load_dts desc) = 1
)

, cte_sat_store__lowes as (

    select
        *
        , 'LOWES' as reporting_customer
    from {{ ref('sat_store__lowes') }}
)

, cte_sat_store__lowes__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_store__lowes'
        ,hk_field='store_hk') }}
)


, cte_sat_store__menards_ll as (

    select
        *
        , 'MENARDS' as reporting_customer
    from {{ ref('sat_store_location_lookup__menards') }}
)

, cte_sat_store__menards_ll__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_store__menards_ll'
        ,hk_field='store_hk') }}
),


cte_sat_store_history__menards as (

    select * 
           , 'MENARDS'  as reporting_customer
    from {{ ref('sat_store_history__menards') }}

),

cte_sat_store_history__menards_latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_store_history__menards'
        ,hk_field='store_hk') }}
),

cte_sat_store__ferguson as ( --added to call in ferguson store satellite data
    select
        store_hk
        , branch_name
        , address_1
        , city
        , state
        , branch_zip_code
        , load_dts
        , rec_src
        , 'FERGUSON' as reporting_customer
    from {{ ref('sat_store__ferguson') }}
),

cte_sat_store__ferguson_latest as (
 {{ generate_cte_satellite_latest('cte_sat_store__ferguson','store_hk') }}
),

menards_union as (
  select 
    store_hk,
    store_::varchar as store_bk,
    '' as store_name,
    address_1,
    city,
    state,
    postal_cd,
    bkcc,
    rec_src ,
    reporting_customer
from cte_sat_store__menards_ll__latest 
union
select 
    store_hk,
    replace(replace(store_no, chr(0), ''), '"', '') as store_bk,
    replace(replace(location_name, chr(0), ''), '"', '') as store_name,
    replace(replace(address_1, chr(0), ''), '"', '') address_1,
    replace(replace(city, chr(0), ''), '"', '') city,
    replace(replace(state, chr(0), ''), '"', '') state,
    replace(replace(postal_cd, chr(0), ''), '"', '') postal_cd,
    bkcc,
    rec_src,
    reporting_customer
from  cte_sat_store_history__menards_latest  
),

joins as (
select
    current_timestamp as snapshot_dts
    , h.store_hk as store_key
    , replace(replace(h.store_bk, chr(0), ''), '"', '') as store_id
    , h.store_hk
    , coalesce(sl.location_desc, hl.d_store_name,mll.store_name, fl.branch_name,'N/A') as store_name
    , coalesce(sl.delivery_address, hl.d_store_address,mll.address_1, fl.address_1,'N/A') as address1
    , coalesce(sl.delivery_city, hl.d_city,mll.city, fl.city,'N/A') as city
    , coalesce(sl.delivery_state, hl.state_territory_code,mll.state, fl.state,'N/A') as state
    , coalesce(sl.delivery_code, hl.d_postal_code,mll.postal_cd, fl.branch_zip_code,'N/A') as postal_code
    , h.reporting_customer
	, coalesce(sl.bkcc, hl.bkcc, mll.bkcc, h.bkcc) as bkcc
	, coalesce(sl.rec_src, hl.rec_src,h.rec_src,mll.rec_src, fl.rec_src) as derv_rec_src
from cte_hub_store as h
    left join cte_sat_store__lowes__latest as sl
        on h.store_hk = sl.store_hk
    left join cte_sat_store__homedepot__latest as hl
        on h.store_hk = hl.store_hk
    left join menards_union as mll
        on h.store_hk=mll.store_hk
    left join cte_sat_store__ferguson_latest as fl      
        on h.store_hk = fl.store_hk
    where h.store_bk is not null and store_id not in('Location','Total','')
    qualify row_number() over(partition by store_id,h.reporting_customer order by derv_rec_src)=1
)

select 
    row_number() over (order by 1) as seq_id,
    snapshot_dts,
    store_key,
    store_id,
    store_hk,
    store_name,
    address1,
    city,
    state,
    postal_code,
    reporting_customer ,
    bkcc,
    derv_rec_src as rec_src
from joins