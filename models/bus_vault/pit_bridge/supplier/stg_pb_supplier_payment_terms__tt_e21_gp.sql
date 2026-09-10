{{
    config(
        materialized='ephemeral'
    )
}}

/*
    stg_pb_supplier_payment_terms__tt_e21_gp
    -----------------------------------------
    Conformed PIT bridge for E21 + GP supplier payment terms.
    Mirrors the output contract of stg_pb_supplier_payment_terms__winn_sap.
    SCD Type 2: each HASHDIFF change in the payment term satellite creates a new version
    with start_date / end_date boundaries derived from LOAD_DTS.
*/

with

/* ====================== HUBS ====================== */
hub_supplier as (
    select
        supplier_hk
        , supplier_bk
        , bkcc
        , rec_src
    from {{ ref('hub_supplier_v2') }}
)

, hub_payment_term as (
    select
        payment_term_hk
        , payment_term_bk
    from {{ ref('hub_payment_term') }}
)

/* ====================== LINK ====================== */
, lnk_supplier_payment_term as (
    select
        lnk_supplier_payment_term_hk
        , supplier_hk
        , payment_term_hk
        , load_dts
        , rec_src
    from {{ ref('lnk_supplier_payment_term') }}
    where rec_src <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'
)

/* ====================== E21 PAYMENT TERM SATELLITE ====================== */
, sat_pterm_e21 as (
    select
        payment_term_hk
        , terms_code
        , terms_desc
        , due_days
        , disc_days
        , disc_pct
        , terms_type
        , psa_delete_ind
        , load_dts
        , hashdiff
    from {{ ref('sat_payment_term__tt_e21') }}
)

/* SCD Type 2: derive start/end dates from each satellite version */
, sat_pterm_e21_scd as (
    select
        payment_term_hk
        , terms_code
        , terms_desc
        , due_days
        , disc_days
        , disc_pct
        , terms_type
        , psa_delete_ind
        , load_dts
        , hashdiff
    from sat_pterm_e21
    /* Deduplicate to one record per payment_term_hk per day */
    qualify row_number() over (
        partition by payment_term_hk, to_date(to_char(load_dts, 'YYYYMMDD'), 'YYYYMMDD')
        order by load_dts desc
    ) = 1
)

/* ====================== GP PAYMENT TERM SATELLITE ====================== */
, sat_pterm_gp as (
    select
        payment_term_hk
        , pymtrmid
        , duetype
        , duedtds
        , disctype
        , discdtds
        , dscpctam
        , dscdlram
        , psa_delete_ind
        , load_dts
        , hashdiff
    from {{ ref('sat_payment_term__tt_gp') }}
)

, sat_pterm_gp_scd as (
    select
        payment_term_hk
        , pymtrmid
        , duetype
        , duedtds
        , disctype
        , discdtds
        , dscpctam
        , dscdlram
        , psa_delete_ind
        , load_dts
        , hashdiff
    from sat_pterm_gp
    qualify row_number() over (
        partition by payment_term_hk, to_date(to_char(load_dts, 'YYYYMMDD'), 'YYYYMMDD')
        order by load_dts desc
    ) = 1
)

/* ====================== FINAL SELECT ====================== */
select
      lnk.supplier_hk
    , lnk.payment_term_hk
    , lnk.lnk_supplier_payment_term_hk
    , hs.supplier_bk
    , hp.payment_term_bk
    /* SCD Type 2 date boundaries */
    , to_char(lnk.load_dts, 'YYYYMMDD')::integer                        as start_date__yyyymmdd
        , coalesce(
            to_char(
                lead(lnk.load_dts) over (
                    partition by lnk.SUPPLIER_HK
                    order by lnk.load_dts
                ) - interval '1 day'
                , 'YYYYMMDD'
            )::integer
            , 20991231
        )                                                                 as end_date__yyyymmdd
    /* Payment term attributes — COALESCE E21 then GP */
    , coalesce(e21.terms_code, gp.pymtrmid, hp.payment_term_bk)::text    as payment_term_code
    , e21.terms_desc                                                      as payment_term_desc
    , coalesce(e21.due_days, gp.duedtds)                                 as payment_term_due_days
    , coalesce(e21.disc_days, gp.discdtds)                               as discount_days
    , coalesce(e21.disc_pct, (gp.dscpctam/100))                           as discount_percent
    , null                                                                as currency_code
    , null                                                                as incoterms_1
    , null                                                                as incoterms_2
    , null                                                                as supplier_purchasing_org_status
    , coalesce(e21.psa_delete_ind, gp.psa_delete_ind, 'N')                    as is_deleted
    , lnk.rec_src
    , hs.bkcc
    /* Durable BK: ties all SCD versions to the same business entity */
    , case
        when hs.supplier_bk in ('0', '-1', '-2') then hs.supplier_bk
        else concat_ws('||', hs.supplier_bk, hp.payment_term_bk, hs.bkcc)
      end                                                                 as drvd_supplier_payment_term_durable_bk
    , md5_binary(upper(concat_ws('||',
        coalesce(nullif(trim(cast(drvd_supplier_payment_term_durable_bk as varchar)), ''), '^^')
    )))                                                                   as supplier_payment_term_durable_hk
    /* Versioned BK: unique per SCD Type 2 version */
    , case
        when hs.supplier_bk in ('0', '-1', '-2') then hs.supplier_bk
        else concat_ws('||', hs.supplier_bk, hp.payment_term_bk, start_date__yyyymmdd, hs.bkcc)
      end                                                                 as drvd_supplier_payment_term_bk
    , md5_binary(upper(concat_ws('||',
        coalesce(nullif(trim(cast(drvd_supplier_payment_term_bk as varchar)), ''), '^^')
    )))                                                                   as supplier_payment_term_hk

from lnk_supplier_payment_term lnk
    left join hub_supplier hs
        on lnk.supplier_hk = hs.supplier_hk
    left join hub_payment_term hp
        on lnk.payment_term_hk = hp.payment_term_hk
    left join sat_pterm_e21_scd e21
        on lnk.payment_term_hk = e21.payment_term_hk
    left join sat_pterm_gp_scd gp
        on lnk.payment_term_hk = gp.payment_term_hk
where BKCC = 'Kicking_Panda' AND nullif(hs.supplier_bk, '') is not null
