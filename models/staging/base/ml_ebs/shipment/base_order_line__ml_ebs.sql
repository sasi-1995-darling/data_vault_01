select distinct line_id, item_type_code from {{ source('bronze_ml_ebs_ont', 'oe_order_lines_all') }}
where _fivetran_deleted = 'FALSE'
