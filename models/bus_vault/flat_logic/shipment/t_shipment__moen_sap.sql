{{
    config(
        materialized='table'
    )
}}

with cte_sat_shipment__moen_sap as (select * from {{ ref('sat_shipment__moen_sap') }})

, cte_sat_shipment__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_sat_shipment__moen_sap','copa_sales_hk') }}
)

, cte_sat_cust_sales_area__moen_sap as (select * from {{ ref('sat_cust_sales_area__moen_sap') }})

, cte_sat_cust_sales_area__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_sat_cust_sales_area__moen_sap','cust_sales_area_hk') }}
)

, cte_sat_location__moen_sap as (select * from {{ ref('sat_location__moen_sap') }})

, cte_sat_location__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_sat_location__moen_sap','address_number_hk') }}
)

, cte_sat_legacy_hofr_us_sales__hofr_ecl as (select * from {{ ref('sat_legacy_hofr_us_sales__hofr_ecl') }})

, cte_sat_legacy_hofr_us_sales__hofr_ecl_latest as (
    {{ generate_cte_satellite_latest('cte_sat_legacy_hofr_us_sales__hofr_ecl','copa_sales_hk') }}
)

select
    hshp.copa_sales_hk as shipment_hk
    , hi.item_bk as item_id
    , scust.customer_desc as customer
    , to_char(hc.customer_bk) as customer_id
    , scust.customer_account_number as key_account_number
    , scust.customer_account_name
    , sshp.sales_org
    , sshp.channel
    , vsls.shipped_qty as invoiced_qty
    , vsls.return_qty
    , sshp.date_posted
    , sloc.zipcode as location
    , sloc.address1 as address_1
    , null as address_2
    , null as address_3
    , null as address_4
    , null as province
    , sloc.country
    , sloc.city
    , sloc.state
    , sloc.zipcode as zip_code
    , vsls.gross_sales_before_incentives as revenue_dollars
    , xref_cp.consumer_price * vsls.shipped_qty as consumer_dollars
    , vsls.actual_returns as actual_return_dollars
    , sshp.type_of_sale as shipment_type
    , rim.brand as source
from {{ ref('hub_shipment_sap') }} as hshp
    inner join cte_sat_shipment__moen_sap_latest as sshp
        on hshp.copa_sales_hk = sshp.copa_sales_hk
    left join {{ ref('link_item_cust_shipment') }} as lics
        on hshp.copa_sales_hk = lics.copa_sales_hk
    left join {{ ref('v_shipment_sales__moen_sap') }} as vsls
        on hshp.copa_sales_hk = vsls.shipment_hk
    left join {{ ref('hub_customer') }} as hc
        on lics.customer_hk = hc.customer_hk
    left join cte_sat_cust_sales_area__moen_sap_latest as scust
        on lics.cust_sales_area_hk = scust.cust_sales_area_hk
    left join cte_sat_location__moen_sap_latest as sloc
        on scust.address_number_hk = sloc.address_number_hk
            and trim(sloc.nation) = ''
            and sloc.language = 'E'
    left join {{ ref('hub_item') }} as hi
        on lics.item_hk = hi.item_hk
    left join {{ ref('ref_item_master') }} as rim
        on hi.item_hk = rim.item_hk
    left join {{ ref('t_shipment_consumer_price_hd_moen') }} as xref_cp
        on hi.item_bk = xref_cp.item_id and sshp.date_posted = xref_cp.date_posted
where (sshp.sales_org = 'ROHS' and sshp.date_posted >= '2023-07-02') or (sshp.date_posted >= '2019-01-01' and sshp.sales_org <> 'ROHS')
union all
select
    hshp.copa_sales_hk as shipment_hk
    , hi.item_bk as item_id
    , scust.customer_desc as customer
    , to_char(hc.customer_bk) as customer_id
    , scust.customer_account_number as key_account_number
    , scust.customer_account_name
    , slhs.sapcode as sales_org
    , scust.dist_channel as channel
    , slhs.qty as invoiced_qty
    , 0 as return_qty
    , try_to_date(slhs.date, 'YYYYMMDD') as date_posted
    , sloc.zipcode as location
    , sloc.address1 as address_1
    , null as address_2
    , null as address_3
    , null as address_4
    , null as province
    , sloc.country
    , sloc.city
    , sloc.state
    , sloc.zipcode as zip_code
    , slhs.sales as revenue_dollars
    , 0 as actual_returns_dollars
    , xref_cp.consumer_price * slhs.qty as consumer_dollars
    , null as shipment_type
    , rim.brand as source
from {{ ref('hub_shipment_sap') }} as hshp
    inner join cte_sat_legacy_hofr_us_sales__hofr_ecl_latest as slhs
        on hshp.copa_sales_hk = slhs.copa_sales_hk
    left join {{ ref('link_item_cust_shipment') }} as lics
        on hshp.copa_sales_hk = lics.copa_sales_hk
    left join {{ ref('hub_customer') }} as hc
        on lics.customer_hk = hc.customer_hk
    left join cte_sat_cust_sales_area__moen_sap_latest as scust
        on lics.cust_sales_area_hk = scust.cust_sales_area_hk
    left join cte_sat_location__moen_sap_latest as sloc
        on scust.address_number_hk = sloc.address_number_hk
            and trim(sloc.nation) = ''
            and sloc.language = 'E'
    left join {{ ref('hub_item') }} as hi
        on lics.item_hk = hi.item_hk
    left join {{ ref('ref_item_master') }} as rim
        on hi.item_hk = rim.item_hk
    left join {{ ref('t_shipment_consumer_price_hd_moen') }} as xref_cp
        on hi.item_bk = xref_cp.item_id and try_to_date(slhs.date, 'YYYYMMDD') = xref_cp.date_posted
where try_to_date(slhs.date, 'YYYYMMDD') < '2023-07-02'
    and hc.customer_bk not in (
        '0000011814'
        , '0000000059'
        , '0000019769'
        , '0000012795'
        , '0000007477'
        , '0000011111'
        , '0000011585'
        , '0000011614'
        , '0000006210'
        , '0000005011'
        , '0000007909'
        , '0000001016'
        , '0000012417'
        , '0000011174'
        , '0000020498'
        , '0000001351'
        , '0000006981'
        , '0000007024'
        , '0000016458'
        , '0000019765'
        , '0000000287'
        , '0000019912'
        , '0000000726'
    )
