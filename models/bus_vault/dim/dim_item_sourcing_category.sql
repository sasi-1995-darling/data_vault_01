---- SRC LAYER ----
with
src_gp as (
    select
        item
        , fbin_category_i
        , fbin_category_ii
        , fbin_category_iii
        , category_leader_name
        , director_name
        , op_co
        , business_unit
    from {{ ref('ref_item_sourcing_category_v2') }}
)

---- LOGIC LAYER ----

, logic_gp as (
    select
        op_co
        , item
        , business_unit
        , fbin_category_i
        , fbin_category_ii
        , fbin_category_iii
        , category_leader_name
        , director_name
    from src_gp
)

---- RENAME LAYER ----

, rename_gp as (
    select
        op_co
        , item
        , business_unit
        , fbin_category_i
        , fbin_category_ii
        , fbin_category_iii
        , category_leader_name
        , director_name
    from logic_gp
)

---- FILTER LAYER ----

, filter_gp as (
    select *
    from rename_gp
)

---- JOIN LAYER ----
, join_result as (
    select *
    from filter_gp
)

---- FINAL LAYER ----
select
    op_co
    , item
    , business_unit
    , fbin_category_i
    , fbin_category_ii
    , fbin_category_iii
    , category_leader_name
    , director_name
from join_result