{{
    config(
        materialized='ephemeral'
    )
}}

with
lnk_supplier_porg_pterm as (
    select
        lnk_supplier_purchasing_org_payment_term_hk,
        payment_term_hk,
        purchasing_org_hk,
        rec_src,
        supplier_hk
    from {{ ref('lnk_supplier_purchasing_org_payment_terms') }}
    where rec_src <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
    /* Deduplicate to one record per (supplier_hk, supplier_site_hk, load_date) to prevent
       same-day duplicate start_date__yyyymmdd values that cause SUPPLIER_PAYMENT_TERM_HK collisions.
       Keeps the latest intraday load_dts per partition. */
    qualify row_number() over (
        partition by supplier_hk, purchasing_org_hk, to_date(to_char(load_dts, 'YYYYMMDD'), 'YYYYMMDD')
        order by load_dts desc
    ) = 1
)

, hub_supplier as (
    select
        supplier_bk,
        supplier_hk,
        bkcc,
        rec_src
    from {{ ref('hub_supplier_v2') }}
)

, hub_payment_term as (
    select
        payment_term_hk,
        payment_term_bk
    from {{ ref('hub_payment_term') }}
)

, hub_purchasing_org as (
    select
        purchasing_org_bk,
        purchasing_org_hk
    from {{ ref('hub_purchasing_org_v2') }}
)

, lsat_supplier_porg_pterm_lttst as (
    select
        lnk_supplier_purchasing_org_payment_term_hk
      , loevm                                
      , glchangetime
      , glchangetime_dttm
      , lifnr
      , zterm
      , psa_delete_ind
      , ekorg
      , waers
      , inco1
      , inco2
    from {{ ref('lsat_supplier_purchasing_org_payment_terms__winn_sap') }}
    /* QUALIFY clause is intentionally used to enable retrieval of historical snapshots of Payment Term Changes
       and pick only the latest change record for each historical snapshot */
    qualify row_number() over (partition by lnk_supplier_purchasing_org_payment_term_hk,SUBSTR(glchangetime, 1, 8)  ORDER BY LOAD_DTS DESC)=1
)

, lsat_supplier_porg_pterm as (
    select
        lnk_supplier_purchasing_org_payment_term_hk,
        COALESCE (SUBSTR(glchangetime, 1, 8), '19000101' ) ::INTEGER as                               START_DATE__YYYYMMDD
        , COALESCE(
            nvl(
                to_char(
                    lead(
                        to_date(substr(glchangetime, 1, 8), 'YYYYMMDD') - 1
                    ) over (
                        partition by lifnr, ekorg
                        order by to_date(substr(glchangetime, 1, 8), 'YYYYMMDD')
                    ),
                    'YYYYMMDD'
                ),
                '20991231'
            ),
            '20991231'
        )::INTEGER as end_date__yyyymmdd
      , loevm                                                                             as supplier_purchasing_org_status
      , glchangetime
      , glchangetime_dttm
      , lifnr
      , zterm
      , psa_delete_ind
      , ekorg
      , waers
      , inco1
      , inco2
    from lsat_supplier_porg_pterm_lttst
    /* QUALIFY clause is intentionally used to enable retrieval of historical snapshots of Payment Term Changes
       and pick only the latest change record for each historical snapshot */
    -- qualify row_number() over (partition by lnk_supplier_purchasing_org_payment_term_hk, to_date(glchangetime_dttm) order by load_dts desc) = 1
)

, msat_payment_term_winn as (
    select
        payment_term_hk,
        ztagg,
        koart,
        zsmn1,
        ztag1,
        ztag2,
        ztag3,
        zprz1,
        zprz2
    from {{ ref('msat_payment_term__winn_sap') }}
    /* Lower priority is assigned to KOART = 'D' (Customer Payment Terms);
       higher priority is assigned to KOART = 'K' (Supplier Payment Terms) and NULL Default Values */
    qualify row_number() over (partition by payment_term_hk order by decode(koart, 'D', 2, 1), load_dts desc) = 1
)

, msat_payment_term_text_winn as (
    select
        payment_term_hk,
        text1 as payment_term_desc,
        ztagg
    from {{ ref('msat_payment_term_text__winn_sap') }}
    where spras = 'E' /* Filter for English Descriptions */
    qualify row_number() over (partition by payment_term_hk, ztagg, spras order by load_dts desc) = 1
)

select
      lnk_supplier_porg_pterm.supplier_hk
    , lnk_supplier_porg_pterm.payment_term_hk
    , lnk_supplier_porg_pterm.purchasing_org_hk
    , lnk_supplier_porg_pterm.lnk_supplier_purchasing_org_payment_term_hk
    , hub_supplier.supplier_bk
    , hub_payment_term.payment_term_bk
    , hub_purchasing_org.purchasing_org_bk
    , lsat_supplier_porg_pterm.start_date__yyyymmdd
    , lsat_supplier_porg_pterm.end_date__yyyymmdd    
    , lsat_supplier_porg_pterm.zterm::text                                             as payment_term_code
    , msat_payment_term_text_winn.payment_term_desc                              as payment_term_desc           
    , case
        when msat_payment_term_winn.ztag3 != 0 then msat_payment_term_winn.ztag3
        when msat_payment_term_winn.ztag2 != 0 then msat_payment_term_winn.ztag2
        when msat_payment_term_winn.ztag1 != 0 then msat_payment_term_winn.ztag1
        when msat_payment_term_winn.zsmn1 = 3   then 90
        when msat_payment_term_winn.zsmn1 = 2   then 60
        when msat_payment_term_winn.zsmn1 = 1   then 30
        else msat_payment_term_winn.ztag1
      end                                                                  as payment_term_due_days
    , case 
        when msat_payment_term_winn.zprz1 != 0 then msat_payment_term_winn.ztag1
        when msat_payment_term_winn.zprz2 != 0 then msat_payment_term_winn.ztag2
        else 0 
      end                                                                   as discount_days   
    , case 
        when msat_payment_term_winn.zprz1 != 0 then msat_payment_term_winn.zprz1
        when msat_payment_term_winn.zprz2 != 0 then msat_payment_term_winn.zprz2
        else 0 
      end                                                                        as discount_percent
    , lsat_supplier_porg_pterm.waers                                             as currency_code
    , lsat_supplier_porg_pterm.inco1                                             as incoterms_1
    , lsat_supplier_porg_pterm.inco2                                             as incoterms_2
    , lsat_supplier_porg_pterm.supplier_purchasing_org_status                    as supplier_purchasing_org_status
    , lsat_supplier_porg_pterm.psa_delete_ind                                    as is_deleted
    , lnk_supplier_porg_pterm.rec_src
    , hub_supplier.bkcc
    /* To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
    , case
        when hub_supplier.supplier_bk = '0'  then '0'
        when hub_supplier.supplier_bk = '-1' then '-1'
        when hub_supplier.supplier_bk = '-2' then '-2'
        else concat_ws('||', hub_supplier.supplier_bk, hub_purchasing_org.purchasing_org_bk, hub_supplier.bkcc)
      end                                                                        as drvd_supplier_payment_term_durable_bk
    /* This is an SCD Type 2 dimension. This Hash key is a Stable Key to tie all versions to the same Supplier Payment Term business entity key, it does not change over time*/
    , md5_binary(upper(concat_ws('||',
        coalesce(nullif(trim(cast(drvd_supplier_payment_term_durable_bk as varchar)), ''), '^^')
    )))                                                                           as supplier_payment_term_durable_hk
    /* To handle the optional null default for the Hash key generation and to match with the Ghost Key Hash value */
    , case
        when hub_supplier.supplier_bk = '0'  then '0'
        when hub_supplier.supplier_bk = '-1' then '-1'
        when hub_supplier.supplier_bk = '-2' then '-2'
        else concat_ws('||', hub_supplier.supplier_bk, hub_purchasing_org.purchasing_org_bk, lsat_supplier_porg_pterm.start_date__yyyymmdd, hub_supplier.bkcc)
      end                                                                        as drvd_supplier_payment_term_bk
    /* This is an SCD Type 2 dimension. The hash key is generated using start_date__yyyymmdd to uniquely identify and track each version. */
    , md5_binary(upper(concat_ws('||',
        coalesce(nullif(trim(cast(drvd_supplier_payment_term_bk as varchar)), ''), '^^')
    )))                                                                          as supplier_payment_term_hk
from lnk_supplier_porg_pterm
    left join hub_supplier
        on lnk_supplier_porg_pterm.supplier_hk = hub_supplier.supplier_hk
    left join hub_payment_term
        on lnk_supplier_porg_pterm.payment_term_hk = hub_payment_term.payment_term_hk
    left join hub_purchasing_org
        on lnk_supplier_porg_pterm.purchasing_org_hk = hub_purchasing_org.purchasing_org_hk
    left join lsat_supplier_porg_pterm
        on lnk_supplier_porg_pterm.lnk_supplier_purchasing_org_payment_term_hk = lsat_supplier_porg_pterm.lnk_supplier_purchasing_org_payment_term_hk
    left join msat_payment_term_winn
        on hub_payment_term.payment_term_hk = msat_payment_term_winn.payment_term_hk
    left join msat_payment_term_text_winn
        on hub_payment_term.payment_term_hk = msat_payment_term_text_winn.payment_term_hk
        and msat_payment_term_winn.ztagg = msat_payment_term_text_winn.ztagg
/* Exclude suppliers with NULL or empty strings to ensure only valid, named suppliers are included in the PIT table. */
where nullif(hub_supplier.supplier_bk, '') is not null
