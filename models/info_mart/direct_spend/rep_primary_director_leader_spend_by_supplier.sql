---- SRC LAYER ----
{{ config(
    description='Identifies the Category Leader and Director with the highest total Spend over the past 12 months for each Supplier Golden Record.'
) }}

/*Calculate the total USD Spend attributed to each Category Leader and Director */
with spend_aggregated as (
    select
        ds.mdm_supplier_bk
        , ds.mdm_golden_record
        , ds.unified_supplier_key
        , ds.unified_supplier_name
        , ds.unified_bkcc
        , ds.unified_rec_src
        , fgsd.director_name
        , fgsd.category_leader_name
        , SUM(fgsd.spend_usd) over (partition by ds.unified_supplier_key, fgsd.category_leader_name) as category_leader_total_spend
        , SUM(fgsd.spend_usd) over (partition by ds.unified_supplier_key, fgsd.director_name) as director_total_spend
    from {{ ref('fact_global_spend_detail') }} as fgsd
        left join {{ ref('dim_supplier_v3') }} as ds
            on fgsd.supplier_hk = ds.supplier_hk
    /* Filter last 12months  */
    where TO_DATE(fgsd.posting_date__yyyymmdd::TEXT, 'YYYYMMDD') >= DATEADD(month, -12, CURRENT_DATE())
)

/* Rank the Category Leader and Director for each Supplier based on highest Spend.*/
/* In case of a tie in Spend, use alphabetical order of their Names to determine rank.*/
, spend_order_by_ctg_dir_name as (
    select
        *
        , ROW_NUMBER()
            over (partition by unified_supplier_key order by director_total_spend desc, director_name asc)
            as director_rank
        , ROW_NUMBER()
            over (partition by unified_supplier_key order by category_leader_total_spend desc, category_leader_name asc)
            as category_rank
    from spend_aggregated
)

select
      mdm_supplier_bk
    , mdm_golden_record
    , unified_supplier_key
    , unified_supplier_name
    , MIN_BY(director_name, director_rank) as primary_director_name
    , MIN_BY(director_total_spend, director_rank) as primary_director_ltm_spend_usd
    , MIN_BY(category_leader_name, category_rank) as primary_category_leader_name
    , MIN_BY(category_leader_total_spend, category_rank) as primary_category_leader_ltm_spend_usd
    , unified_bkcc
    , unified_rec_src
from spend_order_by_ctg_dir_name
where (director_rank = 1 or category_rank = 1)
group by all