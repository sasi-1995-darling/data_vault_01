select
    customer
    , parent_material_number
    , child_material_number
from {{ source('bronze_moen_reference', 'winn_virtual_bundles') }}
