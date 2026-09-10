{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_shipment_inputs__moen_sap as (select * from {{ ref('sat_shipment_inputs__moen_sap') }})

, cte_sat_shipment_inputs__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_sat_shipment_inputs__moen_sap','shipment_inputs_hk') }}
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
    hship.shipment_inputs_hk
    , hitm.item_bk as item_id
    , scust.customer_desc as customer
    , hcus.customer_bk as customer_id
    , scust.customer_account_number as key_account_number
    , scust.customer_account_name
    , sship.sales_org
    , sship.channel
    , (sship.ordered_units - sship.outted_units) as ordered_units
    , sship.order_date
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
    , (sship.gross_input_dollars - sship.outted_dollars) as order_dollars
    , sship.gross_input_dollars
    , sship.type_of_sale as shipment_type
    , sship.currency
    , sship.sap_load_date
    , rim.brand as source
from {{ ref('hub_shipment_inputs_sap') }} as hship
    inner join cte_sat_shipment_inputs__moen_sap_latest as sship
        on hship.shipment_inputs_hk = sship.shipment_inputs_hk
    inner join {{ ref('link_item_cust_shipment_inputs') }} as lnkip
        on hship.shipment_inputs_hk = lnkip.shipment_inputs_hk
    inner join {{ ref('hub_item') }} as hitm
        on lnkip.item_hk = hitm.item_hk
    inner join {{ ref('hub_customer') }} as hcus
        on lnkip.customer_hk = hcus.customer_hk
    left join cte_sat_cust_sales_area__moen_sap_latest as scust
        on lnkip.cust_sales_area_hk = scust.cust_sales_area_hk
    left join cte_sat_location__moen_sap_latest as sloc
        on scust.address_number_hk = sloc.address_number_hk
            and Trim(sloc.nation) = '' and sloc.language = 'E'
    left join {{ ref('ref_item_master') }} as rim
        on lnkip.item_hk = rim.item_hk
where ((
    scust.sales_org = 'USFS' and sship.type_of_sale in ('ACT', 'SAL')
    and sship.rejection_id in ('', '90', ' ')
) or scust.sales_org in ('AMCS', 'USIT', 'MXFS', 'CANS', 'MCNA', 'RIBS')
or (scust.sales_org = 'ROHS' and sship.sap_load_date >= '2023-07-02'
))
union all
select
    hshp.copa_sales_hk as shipment_inputs_hk
    , hi.item_bk as item_id
    , scust.customer_desc as customer
    , To_char(hc.customer_bk) as customer_id
    , scust.customer_account_number as key_account_number
    , scust.customer_account_name
    , slhs.sapcode as sales_org
    , scust.dist_channel as channel
    , slhs.qty as ordered_units
    , slhs.order_date
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
    , slhs.sales as order_dollars
    , null as gross_input_dollars
    , null as shipment_type
    , null as currency
    , slhs.order_date as sap_load_date
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
            and Trim(sloc.nation) = ''
            and sloc.language = 'E'
    left join {{ ref('hub_item') }} as hi
        on lics.item_hk = hi.item_hk
    left join {{ ref('ref_item_master') }} as rim
        on hi.item_hk = rim.item_hk
where slhs.order_date < '2023-07-02'
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
