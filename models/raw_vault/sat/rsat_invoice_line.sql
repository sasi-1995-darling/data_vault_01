with 
stg_emtk_ebs_sales as (
    select *
    from {{ ref('stg_rst_invoice_line__emtk_ebs_sales') }}
)
{% if is_incremental() %} --if the table has yet to be created, this where clause will cause a failure
, max_rst as (
    select 
        max(load_dts) as max_load_dts
        , invoice_line_hk
    from {{ this }}
    group by invoice_line_hk
)

, max_rst_full_record as (
    select rst.*
    from max_rst
    inner join {{ this }} rst
    on max_rst.invoice_line_hk = rst.invoice_line_hk
    and max_rst.max_load_dts = rst.load_dts
)
{% endif %}
select
    stg.invoice_line_hk
    , stg.load_dts
    , stg.rec_src
    , stg._fivetran_synced
    , stg.status
from stg_emtk_ebs_sales stg
{% if is_incremental() %} --if the table has yet to be created, this where clause will cause a failure
left join max_rst_full_record rst
    on stg.invoice_line_hk = rst.invoice_line_hk
where rst.invoice_line_hk is null -- a record does not exist yet in the target
or stg._fivetran_synced > rst._fivetran_synced -- a record exists but its status has changed
{% endif %}