select
    item_id
    , base_material
    , item_status
    , item_type_code
    , item_category
    , item_sub_category
    , item_class
    , item_sub_class
    , brand

from {{ ref('ref_item_master') }}
