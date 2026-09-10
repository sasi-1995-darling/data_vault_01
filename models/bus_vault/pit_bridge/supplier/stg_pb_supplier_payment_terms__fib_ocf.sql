{{
    config(
        materialized='ephemeral'
    )
}}

with
lnk_supplier_site_payment_term as (
    select
        supplier_hk,
        payment_term_hk,
        supplier_site_hk,
        lnk_supplier_site_payment_term_hk,
        load_dts
    from {{ ref('lnk_supplier_site_payment_term') }}
      /* Deduplicate to one record per (supplier_hk, supplier_site_hk, load_date) to prevent
       same-day duplicate start_date__yyyymmdd values that cause SUPPLIER_PAYMENT_TERM_HK collisions.
       Keeps the latest intraday load_dts per partition. */
    qualify row_number() over (
        partition by supplier_hk, supplier_site_hk, to_date(to_char(load_dts, 'YYYYMMDD'), 'YYYYMMDD')
        order by load_dts desc
    ) = 1
)

, hub_supplier as (
    select
        supplier_hk,
        supplier_bk,
        bkcc,
        rec_src
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Jumping_River'
)

, hub_supplier_site as (
    select
        supplier_site_hk,
        supplier_site_bk
    from {{ ref('hub_supplier_site_v2') }}
    where bkcc = 'Jumping_River'
)

, hub_payment_term as (
    select
        payment_term_hk,
        payment_term_bk
    from {{ ref('hub_payment_term') }}
    where bkcc = 'Jumping_River'
)

, msat_payment_term_text_fib as (
    select
        payment_term_hk,
        term_id,
        language,
        name,
        description
    from {{ ref('msat_payment_term_text__fib_ocf') }}
    qualify row_number() over (partition by payment_term_hk, language order by load_dts desc) = 1
)

, msat_payment_term_lines_fib as (
    select
        payment_term_hk,
        term_id,
        sequence_num,
        due_days,
        due_months_forward,
        discount_percent,
        discount_percent_2,
        discount_percent_3,
        discount_days,
        discount_months_forward,
        discount_months_forward_2,
        discount_months_forward_3
    from {{ ref('msat_payment_term_lines__fib_ocf') }}
    qualify row_number() over (partition by payment_term_hk order by load_dts desc) = 1
)

, sat_supplier_site_fib as (
    select
        supplier_site_hk,
        vendor_id,
        vendor_site_id,
        payment_currency_code,
        _fivetran_deleted
    from {{ ref('sat_supplier_site__fib_ocf') }}
    qualify row_number() over (partition by supplier_site_hk order by load_dts desc) = 1
)

select
      lnk_supplier_site_payment_term.supplier_hk
    , lnk_supplier_site_payment_term.payment_term_hk
    , lnk_supplier_site_payment_term.supplier_site_hk
    , hub_supplier.supplier_bk
    , hub_supplier_site.supplier_site_bk
    , hub_payment_term.payment_term_bk
    , coalesce( to_char(load_dts, 'YYYYMMDD')::INTEGER, '19000101')::integer                  as start_date__yyyymmdd
    , coalesce(
        nvl(
            to_char(
                lead(to_date(to_char(load_dts, 'YYYYMMDD'), 'YYYYMMDD') - 1)
                    over (partition by lnk_supplier_site_payment_term.supplier_hk, lnk_supplier_site_payment_term.supplier_site_hk
                          order by lnk_supplier_site_payment_term.load_dts)
            , 'YYYYMMDD')
        , '20991231')
      , '20991231')::integer                                                                          as end_date__yyyymmdd
    , msat_payment_term_text_fib.term_id::text                                                                    as payment_term_code
    , msat_payment_term_text_fib.name                                                                       as payment_term_desc
    , msat_payment_term_lines_fib.due_days::integer                                                         as due_days
    , msat_payment_term_lines_fib.due_months_forward::integer                                               as due_months_forward
    , coalesce(msat_payment_term_lines_fib.due_days, msat_payment_term_lines_fib.due_months_forward * 30)   as payment_term_due_days
    , coalesce(msat_payment_term_lines_fib.discount_days, 
             coalesce(msat_payment_term_lines_fib.discount_months_forward, msat_payment_term_lines_fib.discount_months_forward_2, msat_payment_term_lines_fib.discount_months_forward_3, 0) * 30) 
                                                                                                            as discount_days
    , coalesce(msat_payment_term_lines_fib.discount_percent, msat_payment_term_lines_fib.discount_percent_2, msat_payment_term_lines_fib.discount_percent_3, 0)
                                                                                                            as discount_percent
    , sat_supplier_site_fib.payment_currency_code   as currency_code
    , IFF(sat_supplier_site_fib._FIVETRAN_DELETED = 'TRUE', 'Y', 'N')                                   as is_deleted 
    , hub_supplier.bkcc                            as bkcc
    , hub_supplier.rec_src                         as rec_src
     /* To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
    , case
        when hub_supplier.supplier_bk = '0'  then '0'
        when hub_supplier.supplier_bk = '-1' then '-1'
        when hub_supplier.supplier_bk = '-2' then '-2'
        else concat_ws('||', hub_supplier.supplier_bk, hub_supplier_site.supplier_site_bk, hub_supplier.bkcc)
      end                                                                        as drvd_supplier_payment_term_durable_bk
    /* This is an SCD Type 2 dimension.This Hash key is a Stable Key to tie all versions to the same Supplier Payment Term business entity key, it does not change over time*/
        , md5_binary(upper(concat_ws('||',
        coalesce(nullif(trim(cast(drvd_supplier_payment_term_durable_bk as varchar)), ''), '^^')
    )))                                                                           as supplier_payment_term_durable_hk
    /* To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
    , case
        when hub_supplier.supplier_bk = '0'  then '0'
        when hub_supplier.supplier_bk = '-1' then '-1'
        when hub_supplier.supplier_bk = '-2' then '-2'
        else concat_ws('||', hub_supplier.supplier_bk, hub_supplier_site.supplier_site_bk, start_date__yyyymmdd, hub_supplier.bkcc)
      end                                                                        as drvd_supplier_payment_term_bk
    
    /* This is an SCD Type 2 dimension. The hash key is generated using start_date__yyyymmdd to uniquely identify and track each version. */
    
    , md5_binary(upper(concat_ws('||',
        coalesce(nullif(trim(cast(drvd_supplier_payment_term_bk as varchar)), ''), '^^')
    )))                                                                          as supplier_payment_term_hk                                                        
from lnk_supplier_site_payment_term
    left join hub_supplier
        on hub_supplier.supplier_hk = lnk_supplier_site_payment_term.supplier_hk
    left join hub_supplier_site
        on hub_supplier_site.supplier_site_hk = lnk_supplier_site_payment_term.supplier_site_hk
    left join hub_payment_term
        on hub_payment_term.payment_term_hk = lnk_supplier_site_payment_term.payment_term_hk
    left join msat_payment_term_text_fib
        on msat_payment_term_text_fib.payment_term_hk = lnk_supplier_site_payment_term.payment_term_hk
        and msat_payment_term_text_fib.language = 'US'
    left join msat_payment_term_lines_fib
        on msat_payment_term_lines_fib.payment_term_hk = lnk_supplier_site_payment_term.payment_term_hk
    left join sat_supplier_site_fib
        on sat_supplier_site_fib.supplier_site_hk = lnk_supplier_site_payment_term.supplier_site_hk
 where bkcc = 'Jumping_River'
 