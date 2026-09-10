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
      /* In DV2, the satellite (msat_supplier_site) drives the SCD2 grain via effdt.
       The link is used only to resolve the supplier_hk relationship.
       Dedup to one row per supplier_site_hk (latest load) to prevent fan-out. */
    qualify row_number() over (
        partition by supplier_site_hk
        order by load_dts desc
    ) = 1
)

, hub_supplier_site as (
    select
        supplier_site_hk,
        supplier_site_bk
    from {{ ref('hub_supplier_site_v2') }}
    where bkcc = 'Swimming_Ocean' 
)

,msat_supplier_site as (
    select
        supplier_site_hk,
        vendor_id,
        vndr_loc,
        setid,
        effdt,
        eff_status,
        currency_cd,
        pymnt_terms_cd,
        psa_delete_ind
    from {{ ref('msat_supplier_site__lrsn_psft') }}
    where nullif(pymnt_terms_cd, '') is not null
      and pymnt_terms_cd != ' '
    qualify row_number() over (partition by supplier_site_hk, effdt order by load_dts desc) = 1
)

, hub_supplier as (
    select
        supplier_hk,
        supplier_bk,
        bkcc,
        rec_src
    from {{ ref('hub_supplier_v2') }}
    where bkcc = 'Swimming_Ocean'
)

, msat_payment_term_header as (
    select
        payment_term_hk,
        pymnt_terms_cd,
        setid,
        descr
    from {{ ref('msat_payment_term_header__lrsn_psft') }}
    qualify row_number() over (partition by pymnt_terms_cd, setid order by load_dts desc) = 1
)

, msat_payment_term_net as (
    select
        payment_term_hk,
        pymnt_terms_cd,
        setid,
        effdt,
        net_trms_seq_nbr,
        net_trms_time_id,
        dsc_trms_avail_flg
    from {{ ref('msat_payment_term_net__lrsn_psft') }}
    qualify row_number() over (partition by payment_term_hk, effdt, net_trms_seq_nbr order by load_dts desc) = 1
)

, msat_payment_term_net_final as (
    select
        payment_term_hk,
        setid,
        net_trms_time_id
    from msat_payment_term_net
    qualify row_number() over (partition by payment_term_hk order by net_trms_seq_nbr desc) = 1
)

, msat_payment_term_discount as (
    select
        payment_term_hk,
        pymnt_terms_cd,
        setid,
        effdt,
        net_trms_seq_nbr,
        dscnt_trms_seq_nbr,
        dscnt_trms_time_id,
        terms_adjust_days,
        dscnt_trms_percent
    from {{ ref('msat_payment_term_discount__lrsn_psft') }}
    qualify row_number() over (partition by payment_term_hk, effdt, net_trms_seq_nbr, dscnt_trms_seq_nbr order by load_dts desc) = 1
)

, msat_payment_term_discount_final as (
    select
        payment_term_hk,
        setid,
        dscnt_trms_time_id,
        dscnt_trms_percent
    from msat_payment_term_discount
    qualify row_number() over (partition by payment_term_hk order by dscnt_trms_seq_nbr asc) = 1
)

, ref_payment_term_time as (
    select
        setid,
        pay_trms_time_id,
        tmg_day_incr_val
    from {{ ref('ref_payment_term_time__lrsn_psft') }}
    qualify row_number() over (partition by setid, pay_trms_time_id order by load_dts desc) = 1
)

select
      l.supplier_hk
    , l.payment_term_hk
    , l.supplier_site_hk
    , hub_supplier.supplier_bk
    , hss.supplier_site_bk                                                                     as supplier_site_bk
    , msat_supplier_site.pymnt_terms_cd                                                        as payment_term_bk
    , coalesce(to_char(msat_supplier_site.effdt, 'YYYYMMDD')::integer, 19000101)               as start_date__yyyymmdd
    , coalesce(
        nvl(
            to_char(
                lead(msat_supplier_site.effdt - 1)
                    over (partition by msat_supplier_site.supplier_site_hk
                          order by msat_supplier_site.effdt)
            , 'YYYYMMDD')
        , '20991231')
      , '20991231')::integer                                                                   as end_date__yyyymmdd
    , msat_supplier_site.pymnt_terms_cd::text                                                  as payment_term_code
    , msat_payment_term_header.descr                                                           as payment_term_desc
    , ref_time_net.tmg_day_incr_val                                                            as payment_term_due_days
    , ref_time_dscnt.tmg_day_incr_val                                                          as discount_days
    , msat_payment_term_discount_final.dscnt_trms_percent                                      as discount_percent
    , msat_supplier_site.currency_cd                                                           as currency_code
    , iff(msat_supplier_site.eff_status = 'I' or msat_supplier_site.psa_delete_ind = 'Y', 'Y', 'N')  as is_deleted
    , hub_supplier.bkcc
    , hub_supplier.rec_src
    /* To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
    , case
        when hub_supplier.supplier_bk = '0'  then '0'
        when hub_supplier.supplier_bk = '-1' then '-1'
        when hub_supplier.supplier_bk = '-2' then '-2'
        else concat_ws('||', hub_supplier.supplier_bk, hss.supplier_site_bk, hub_supplier.bkcc)
      end                                                                                      as drvd_supplier_payment_term_durable_bk
    /* This is an SCD Type 2 dimension. This Hash key is a Stable Key to tie all versions to the same Supplier Payment Term business entity key, it does not change over time */
    , md5_binary(upper(concat_ws('||',
        coalesce(nullif(trim(cast(drvd_supplier_payment_term_durable_bk as varchar)), ''), '^^')
    )))                                                                                        as supplier_payment_term_durable_hk
    /* To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
    , case
        when hub_supplier.supplier_bk = '0'  then '0'
        when hub_supplier.supplier_bk = '-1' then '-1'
        when hub_supplier.supplier_bk = '-2' then '-2'
        else concat_ws('||', hub_supplier.supplier_bk, hss.supplier_site_bk, start_date__yyyymmdd, hub_supplier.bkcc)
      end                                                                                      as drvd_supplier_payment_term_bk
    /* This is an SCD Type 2 dimension. The hash key is generated using start_date__yyyymmdd to uniquely identify and track each version. */
    , md5_binary(upper(concat_ws('||',
        coalesce(nullif(trim(cast(drvd_supplier_payment_term_bk as varchar)), ''), '^^')
    )))                                                                                        as supplier_payment_term_hk
from lnk_supplier_site_payment_term l
    inner join hub_supplier_site hss
    on l.supplier_site_hk = hss.supplier_site_hk
    inner join hub_supplier
        on l.supplier_hk = hub_supplier.supplier_hk
    left join msat_supplier_site
        on msat_supplier_site.supplier_site_hk = hss.supplier_site_hk
    left join msat_payment_term_header
        on msat_supplier_site.pymnt_terms_cd = msat_payment_term_header.pymnt_terms_cd
        and msat_supplier_site.setid = msat_payment_term_header.setid
    left join msat_payment_term_net_final
        on msat_payment_term_header.payment_term_hk = msat_payment_term_net_final.payment_term_hk
    left join ref_payment_term_time as ref_time_net
        on msat_payment_term_net_final.setid = ref_time_net.setid
        and msat_payment_term_net_final.net_trms_time_id = ref_time_net.pay_trms_time_id
    left join msat_payment_term_discount_final
        on msat_payment_term_header.payment_term_hk = msat_payment_term_discount_final.payment_term_hk
    left join ref_payment_term_time as ref_time_dscnt
        on msat_payment_term_discount_final.setid = ref_time_dscnt.setid
        and msat_payment_term_discount_final.dscnt_trms_time_id = ref_time_dscnt.pay_trms_time_id
where bkcc = 'Swimming_Ocean' and nullif(hub_supplier.supplier_bk, '') is not null
