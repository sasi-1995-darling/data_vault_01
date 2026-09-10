with cte_po_action_history as (
    select
        object_id
        , object_type_code
        , object_sub_type_code
        , sequence_num
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , action_code
        , action_date
        , employee_id
        , note
        , object_revision_num
        , last_update_login
        , program_update_date
        , program_date
    from {{ source('emtk_ebs_po__po', 'po_action_history') }}
    where _fivetran_deleted = false
        and action_code is not null
        and action_date is not null
)

, cte_purchase_order_bk as (
    select distinct
        po_header_id
        , org_id
        , segment1 as poh_segment1
    from {{ source('emtk_ebs_po__po', 'po_headers_all') }}
    where _fivetran_deleted = false
)

, cte_final as (
    select
        po.org_id
        ,po.poh_segment1
        , pah.object_id
        , pah.action_code
        , pah.action_date
        , pah.sequence_num
        , pah.object_type_code
        , pah.object_sub_type_code
        , pah.last_update_date
        , pah._fivetran_synced
        , pah.last_updated_by
        , pah.creation_date
        , pah.created_by
        , pah.employee_id
        , pah.note
        , pah.object_revision_num
        , pah.last_update_login
        , pah.program_update_date
        , pah.program_date
    from cte_po_action_history as pah
        inner join cte_purchase_order_bk as po
            on pah.object_id = po.po_header_id
)

select *
from cte_final
