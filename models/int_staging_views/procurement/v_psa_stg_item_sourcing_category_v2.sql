---- SRC LAYER ----
with
src_src as (
    select
        business_unit
        , op_co
        , item_material_number
        , item_material_description
        , category_i
        , category_ii
        , category_iii
        , category_leader_name
        , director_name
        , requestor
        , business_days_since_approval
        , created_date_only
        , _fivetran_synced
        , _fivetran_deleted
        , psa_load_dts
        , psa_record_source
        , psa_delete_ind
    from {{ source('smartsheet__nonworkspace_sheets', 'new_hierarchy_assignment_request_processing_5073596788461444') }}
    /*
    The following is a REF table-specific dedup step. The QUALIFY statement keeps only the latest record for each OP_CO and ITEM_MATERIAL_NUMBER.
    Multiple versions of the same item can exist in PSA for the same business key, and PSA stores that landing history across sync events and loads.
    To avoid duplicate current-state records while preserving PSA history, we use ROW_NUMBER() ordered by _FIVETRAN_SYNCED DESC and PSA_LOAD_DTS DESC so the most recently synced record is selected first, with PSA_LOAD_DTS as a deterministic tie-breaker.
    This ordering is intentional and should remain aligned with the QUALIFY clause below to avoid reintroducing non-deterministic latest-record selection.
    */
    qualify
        1
        = row_number()
            over (
                partition by upper(op_co), item_material_number
                order by _fivetran_synced desc, psa_load_dts desc
            )
)

, src_ctg_ldr_xref as (
    select
        category_i
        , category_ii
        , category_iii
        , new_category_owner
        , director
        , modified_by
    from {{ source('smartsheet__nonworkspace_sheets', 'category_assignment_cross_sheet_106904244146052') }}
    qualify
        1 = row_number() over (partition by hash(category_i, category_ii, category_iii) order by _fivetran_synced desc)
)

, src_xref as (
    select
        tm_ss_email
        , text_name
    from {{ source('smartsheet__nonworkspace_sheets', 'sourcing_tm_hierarchy_3965509561175940') }}
    qualify 1 = row_number() over (partition by tm_ss_email order by _fivetran_synced desc)
)

/*
SRC_src            as ( SELECT * FROM smartsheet__nonworkspace_sheets.new_hierarchy_assignment_request_processing_5073596788461444 )
SRC_ctg_ldr_xref   as ( SELECT * FROM smartsheet__nonworkspace_sheets.category_assignment_cross_sheet_106904244146052 )
SRC_xref_d         as ( SELECT * FROM smartsheet__nonworkspace_sheets.sourcing_tm_hierarchy_3965509561175940
 )
*/
---- LOGIC LAYER ----

, logic_src as (
    select
        op_co
        , item_material_number as item
        , requestor as requestor_email
        , category_i as fbin_category_i
        , category_ii as fbin_category_ii
        , category_iii as fbin_category_iii
        , business_unit
        , psa_load_dts
        , psa_record_source
        , psa_delete_ind
        , created_date_only as created_at
        , _fivetran_synced
        , _fivetran_deleted
        , convert_timezone('UTC', _fivetran_synced) as load_dts
        , hash(category_i, category_ii, category_iii) as cat_hash
    from src_src
)

, logic_ctg_ldr_xref as (
    select
        -- when it's an email, use it as join key; otherwise NULL (join won't match)
        case when director like '%@%' then director end             as director_email
        , case when new_category_owner like '%@%' then new_category_owner end as category_leader_email
        -- when it's already a name, capture it directly
        , case when director not like '%@%' then director end       as director_name_direct
        , case when new_category_owner not like '%@%' then new_category_owner end as category_leader_name_direct
        , hash(category_i, category_ii, category_iii) as ctg_ldr_xref_cat_hash
        , category_i
        , category_ii
        , category_iii
    from src_ctg_ldr_xref
)

, logic_xref as (
    select
        coalesce(text_name, 'UPDATE CROSS REFERENCE') as name
        ,tm_ss_email as email
    from src_xref
)

---- RENAME LAYER ----

, rename_src as (
    select
        op_co
        , item
        , requestor_email
        , fbin_category_i
        , fbin_category_ii
        , fbin_category_iii
        , business_unit
        , psa_load_dts
        , psa_record_source
        , psa_delete_ind
        , _fivetran_synced
        , load_dts
        , cat_hash
        , created_at
    from logic_src
)

, rename_ctg_ldr_xref as (
    select
        director_email
        , category_leader_email
        , director_name_direct
        , category_leader_name_direct
        , ctg_ldr_xref_cat_hash
        , category_i
        , category_ii
        , category_iii
    from logic_ctg_ldr_xref
)

, rename_xref as (
    select
        name
        , email
    from logic_xref
)

---- FILTER LAYER ----

, filter_src as (
    select *
    from rename_src
)

, filter_ctg_ldr_xref as (
    select *
    from rename_ctg_ldr_xref
)

, filter_xref as (
    select *
    from rename_xref
)

---- JOIN LAYER ----
, join_result as (
    select
        filter_src.op_co
        , filter_src.item
        , filter_src.requestor_email
        , filter_src.fbin_category_i
        , filter_src.fbin_category_ii
        , filter_src.fbin_category_iii
        , filter_src.business_unit
        , filter_src.psa_load_dts
        , filter_src.psa_record_source
        , filter_src.psa_delete_ind
        , filter_src.created_at
        , filter_src._fivetran_synced
        , filter_src.load_dts
        , filter_ctg_ldr_xref.director_email
        , filter_ctg_ldr_xref.category_leader_email
        , coalesce(
            nullif(trim(filter_ctg_ldr_xref.director_name_direct), ''),
            filter_xref_d.name,
            'UPDATE CROSS REFERENCE'
          ) as director_name
        , coalesce(
            nullif(trim(filter_ctg_ldr_xref.category_leader_name_direct), ''),
            filter_xref_c.name,
            'UPDATE CROSS REFERENCE'
          ) as category_leader_name
    from filter_src
        left join filter_ctg_ldr_xref
            on filter_src.cat_hash = filter_ctg_ldr_xref.ctg_ldr_xref_cat_hash
        left join filter_xref as filter_xref_d
            on filter_ctg_ldr_xref.director_email = filter_xref_d.email
        left join filter_xref as filter_xref_c
            on filter_ctg_ldr_xref.category_leader_email = filter_xref_c.email
)

---- FINAL LAYER ----
select
    op_co
    , item
    , requestor_email
    , director_email
    , director_name
    , category_leader_email
    , category_leader_name
    , fbin_category_i
    , fbin_category_ii
    , fbin_category_iii
    , business_unit
    , psa_load_dts
    , psa_record_source
    , psa_delete_ind
    , created_at
    , _fivetran_synced
    , load_dts
from join_result
