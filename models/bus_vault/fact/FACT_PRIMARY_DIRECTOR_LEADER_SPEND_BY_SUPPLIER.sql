---- SRC LAYER ----
{{ config(
    description='Identifies the primary Category Leader and Director with the highest total LTM Direct Spend for each Supplier (grain: SUPPLIER_HK). Direct spend is derived via SPEND_TYPE_FLAG: item-linked spend outside excluded category codes. Director and category leader names are sourced from DIM_ITEM_SOURCING_CATEGORY joined on item_bk + opco.'
) }}

with src_spend as (
    select
          supplier_hk
        , item_bk
        , DRVD_OPCO as opco
        , category_cd
        , spend_usd
        , POSTING_DATE as posting_date__yyyymmdd
		, SPEND_TYPE_FLAG
    from {{ ref('pb_global_spend_detail') }}
)

, src_supplier as (
    select
          supplier_hk
        , mdm_supplier_bk
        , mdm_golden_record
        , unified_supplier_key
        , unified_supplier_name
        , unified_bkcc
        , unified_rec_src
    from {{ ref('pb_supplier_mdm') }}
)

, src_category as (
    select
          item
        , op_co
        , category_leader_name
        , director_name
    from {{ ref('ref_item_sourcing_category_v2') }}
)

---- LOGIC LAYER ----

/* Then enrich with category leader and director from DIM_ITEM_SOURCING_CATEGORY (item_bk + opco).
   Rows with no category mapping resolve to REVIEW and are excluded in the JOIN layer. */
, logic_spend_flagged as (
    select
          s.supplier_hk
        , s.spend_usd
        , s.posting_date__yyyymmdd
        , s.spend_type_flag
        , COALESCE(c.director_name, 'REVIEW')                   as director_name
        , COALESCE(c.category_leader_name, 'REVIEW')            as category_leader_name
    from src_spend as s
        left join src_category as c  /* resolve category ownership via item + opco */
            on s.item_bk = c.item
                and s.opco = c.op_co
)

---- JOIN LAYER ----

/* Aggregate LTM Direct spend per SUPPLIER_HK + leader, then rank to find the primary.
   director_name <> REVIEW filter excludes items with no category mapping. */
, join_spend_aggregated as (
    select
          sup.supplier_hk
        , sup.mdm_supplier_bk
        , sup.mdm_golden_record
        , sup.unified_supplier_key
        , sup.unified_supplier_name
        , sup.unified_bkcc
        , sup.unified_rec_src
        , lsc.director_name
        , lsc.category_leader_name
        , SUM(lsc.spend_usd) over (
            partition by sup.supplier_hk, lsc.category_leader_name
          ) as category_leader_total_spend
        , SUM(lsc.spend_usd) over (
            partition by sup.supplier_hk, lsc.director_name
          ) as director_total_spend
    from logic_spend_flagged as lsc
        left join src_supplier as sup
            on lsc.supplier_hk = sup.supplier_hk
    where lsc.posting_date__yyyymmdd >= DATEADD(month, -12, CURRENT_DATE())
        and lsc.spend_type_flag = 'DIRECT'
        and lsc.director_name <> 'REVIEW'  /* exclude items with no category mapping */
)

, join_spend_ranked as (
    select
        *
        , ROW_NUMBER() over (
            partition by supplier_hk
            order by director_total_spend desc, director_name asc
          ) as director_rank
        , ROW_NUMBER() over (
            partition by supplier_hk
            order by category_leader_total_spend desc, category_leader_name asc
          ) as category_rank
    from join_spend_aggregated
)

---- FINAL LAYER ----

select
      supplier_hk
    , mdm_supplier_bk
    , mdm_golden_record
    , unified_supplier_key
    , unified_supplier_name
    , MIN_BY(director_name, director_rank)                as primary_director_name
    , MIN_BY(director_total_spend, director_rank)         as primary_director_ltm_spend_usd
    , MIN_BY(category_leader_name, category_rank)         as primary_category_leader_name
    , MIN_BY(category_leader_total_spend, category_rank)  as primary_category_leader_ltm_spend_usd
    , unified_bkcc
    , unified_rec_src
from join_spend_ranked
where (director_rank = 1 or category_rank = 1)
group by all