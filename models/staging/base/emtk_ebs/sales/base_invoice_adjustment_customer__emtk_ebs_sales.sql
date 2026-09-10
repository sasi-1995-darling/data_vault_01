/*
    LINK: Invoice adjustment customer
*/

with
cte_hz_cust_accounts as (
    select
        account_number -- BK
        , cust_account_id

    from {{ source('emtk_ebs_sales__ar', 'hz_cust_accounts') }}
    where _fivetran_deleted = false
)

, cte_ra_cust_trx_types_all as (
    select
        type -- Filter
        , cust_trx_type_id
        , org_id

    from {{ source('emtk_ebs_sales__ar', 'ra_cust_trx_types_all') }}
    where _fivetran_deleted = false
)

, cte_ra_customer_trx_all as (
    select
        trx_number -- BK
        , org_id -- BK
        , interface_header_attribute2 -- filter
        , cust_trx_type_id --filter       
        , bill_to_customer_id --join
        , bill_to_site_use_id -- join
        , trx_date -- tie-breaker
        , creation_date -- effective
        , _fivetran_synced -- load_dts
        , coalesce(interface_header_attribute1, '-1') as interface_header_attribute1 -- BK
    from {{ source('emtk_ebs_sales__ar', 'ra_customer_trx_all') }}
    where _fivetran_deleted = false
)

, cte_ar_hz_locations as (
    select location_id

    from {{ source('emtk_ebs_sales__ar', 'hz_locations') }}
    where _fivetran_deleted = false
)

, cte_ar_hz_party_sites as (
    select
        party_site_id -- join
        , location_id

    from {{ source('emtk_ebs_sales__ar', 'hz_party_sites') }}
    where _fivetran_deleted = false
)

, cte_hz_cust_acct_sites_all as (
    select
        cust_acct_site_id -- join
        , party_site_id -- join
    from {{ source('emtk_ebs_sales__ar', 'hz_cust_acct_sites_all') }}
    where _fivetran_deleted = false
)

, cte_hz_cust_site_uses_all as (
    select
        location
        , site_use_id
        , cust_acct_site_id
    from {{ source('emtk_ebs_sales__ar', 'hz_cust_site_uses_all') }}
    where _fivetran_deleted = false
)

, cte_final as (
    select
        rcta.org_id -- 101,'EMTEK', 181, 'SCHAUB' 
        , rcta.trx_number -- invoice_no
        , rcta.interface_header_attribute1 -- "order_num" 
        , rcta.trx_date -- tie-breaker
        , rcta.creation_date
        , rcta._fivetran_synced
        , hcaa.account_number -- customer
        , hl.location_id as bill_location_id -- bill-to location

    from cte_ra_customer_trx_all as rcta
        inner join cte_ra_cust_trx_types_all as rctta
            on rcta.cust_trx_type_id = rctta.cust_trx_type_id
                and rcta.org_id = rctta.org_id
        inner join cte_hz_cust_accounts as hcaa
            on rcta.bill_to_customer_id = hcaa.cust_account_id -- customer
        /* bill_to joins */
        inner join cte_hz_cust_site_uses_all as hcsu
            on rcta.bill_to_site_use_id = hcsu.site_use_id -- bill-to location
        inner join cte_hz_cust_acct_sites_all as hcas
            on hcsu.cust_acct_site_id = hcas.cust_acct_site_id
        inner join cte_ar_hz_party_sites as hps
            on hcas.party_site_id = hps.party_site_id
        inner join cte_ar_hz_locations as hl
            on hps.location_id = hl.location_id -- bill-to location

    where rctta.type in ('CM', 'DM') -- ONLY credit AND memo types 
        and (
            length(rcta.interface_header_attribute2) > 3 -- filter out Schaub conversion records from 2019
            or rcta.interface_header_attribute2 is null
        )
)

select * from cte_final
