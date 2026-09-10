---- SRC LAYER ----
with
src_s as (
    select
        inv_item_id
        , vendor_id
        , vendor_setid
        , vndr_loc
        , setid
        , accept_all_uom
        , accept_all_shipto
        , qty_type
        , price_dt_type
        , price_can_change
        , use_std_lead_time
        , lead_time
        , stockless_flg
        , country_ist_origin
        , ist_region_origin
        , lc_template_id
        , order_mult_flg
        , round_rule_ordr
        , _fivetran_id
        , _fivetran_deleted
        , _fivetran_synced
        , psa_load_dts
        , psa_record_source
        , psa_delete_ind
    from {{ source('lrsn_psft_sysadm', 'ps_itm_vendor_loc') }}
)

, src_a as (select
            bkcc
            , rec_src
from {{ ref('ref_business_key_collision') }})

/*
SRC_S              as ( SELECT * FROM lrsn_psft_sysadm.ps_itm_vendor_loc )
, SRC_A              as ( SELECT * FROM raw_vault.ref_business_key_collision )
*/
---- LOGIC LAYER ----

, logic_s as (
    select
        inv_item_id
        , vendor_id
        , vendor_setid
        , vndr_loc
        , setid
        , accept_all_uom
        , accept_all_shipto
        , qty_type
        , price_dt_type
        , price_can_change
        , use_std_lead_time
        , lead_time
        , stockless_flg
        , country_ist_origin
        , ist_region_origin
        , lc_template_id
        , order_mult_flg
        , round_rule_ordr
        , _fivetran_id
        , _fivetran_deleted
        , _fivetran_synced
        , psa_load_dts
        , psa_record_source
        , psa_delete_ind
        , CONVERT_TIMEZONE('UTC', _fivetran_synced) as load_dts
    from src_s
)

, logic_a as (
    select
        bkcc
        , rec_src
    from src_a
)
---- RENAME LAYER ----

, rename_s as (
    select
        inv_item_id
        , vendor_id
        , vendor_setid
        , vndr_loc
        , setid
        , accept_all_uom
        , accept_all_shipto
        , qty_type
        , price_dt_type
        , price_can_change
        , use_std_lead_time
        , lead_time
        , stockless_flg
        , country_ist_origin
        , ist_region_origin
        , lc_template_id
        , order_mult_flg
        , round_rule_ordr
        , _fivetran_id
        , _fivetran_deleted
        , _fivetran_synced
        , psa_load_dts
        , psa_record_source
        , psa_delete_ind
        , load_dts
    from logic_s
)

, rename_a as (
    select
        bkcc
        , rec_src
    from logic_a
)
---- FILTER LAYER ----

, filter_s as (
    select *
    from rename_s
)

, filter_a as (
    select *
    from rename_a
    where rec_src = 'USSDBR.ORCL.PSFTPRD.PS_ITM_VENDOR_LOC'
)

---- JOIN LAYER ----
, join_result as (
    select *
    from filter_s
        inner join filter_a
            on '1' = '1'
)

---- FINAL LAYER ----
select
    inv_item_id
    , vendor_id
    , vendor_setid
    , vndr_loc
    , setid
    , accept_all_uom
    , accept_all_shipto
    , qty_type
    , price_dt_type
    , price_can_change
    , use_std_lead_time
    , lead_time
    , stockless_flg
    , country_ist_origin
    , ist_region_origin
    , lc_template_id
    , order_mult_flg
    , round_rule_ordr
    , _fivetran_id
    , _fivetran_deleted
    , _fivetran_synced
    , psa_load_dts
    , psa_record_source
    , psa_delete_ind
    , load_dts
    , MD5_BINARY(UPPER(CONCAT_WS(
            '||'
            , COALESCE(NULLIF(TRIM(CAST(vendor_id as VARCHAR)), ''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(inv_item_id as VARCHAR)), ''), '^^')
            , COALESCE(NULLIF(TRIM(CAST(bkcc as VARCHAR)), ''), '^^')
        ))) as lnk_supplier_item_hk
    , bkcc
    , rec_src
    , MD5_BINARY(UPPER(CONCAT_WS(
        '||'
        , COALESCE(NULLIF(TRIM(CAST(vendor_id as VARCHAR)), ''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(bkcc as VARCHAR)), ''), '^^')
    ))) as supplier_hk
    , MD5_BINARY(UPPER(CONCAT_WS(
        '||'
        , COALESCE(NULLIF(TRIM(CAST(inv_item_id as VARCHAR)), ''), '^^')
        , COALESCE(NULLIF(TRIM(CAST(bkcc as VARCHAR)), ''), '^^')
    ))) as item_hk
    , MD5_BINARY(UPPER(NULLIF(CONCAT(
        COALESCE(TRIM(CAST (vendor_setid as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (vndr_loc as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (setid as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (accept_all_uom as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (accept_all_shipto as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (qty_type as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (price_dt_type as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (price_can_change as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (use_std_lead_time as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (lead_time as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (stockless_flg as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (country_ist_origin as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (ist_region_origin as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (lc_template_id as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (order_mult_flg as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (round_rule_ordr as TEXT)), '^^')
        , '||', COALESCE(TRIM(CAST (_fivetran_deleted as TEXT)), '^^')
    ), '^^||^^'))) as hashdiff
from join_result
