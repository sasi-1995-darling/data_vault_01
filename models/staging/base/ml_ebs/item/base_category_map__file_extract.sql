select distinct
part_number as category_id,
description as base_material,
product_category  as item_category  ,
product_sub_category  as item_sub_category  ,
product_class  as item_class     ,
category        ,
sub_category        ,
class       ,
sub_class   
from {{ source('bronze_reference', 'tmlc_category_map') }}