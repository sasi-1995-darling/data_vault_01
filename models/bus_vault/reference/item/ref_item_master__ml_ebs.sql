{{
    config(
        materialized='ephemeral'
    )
}}


with cte_sat_item_base__ml_ebs as (
    select * from {{ ref('sat_item_base__ml_ebs') }}
)
, cte_sat_item_base__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_item_base__ml_ebs'
        ,hk_field='item_hk') }}
)
, cte_sat_item_language__ml_ebs as (
    select * from {{ ref('sat_item_language__ml_ebs') }}
)
, cte_sat_item_language__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_item_language__ml_ebs'
        ,hk_field='item_hk') }}
)
, cte_sat_item_categories__ml_ebs as (
    select * from {{ ref('sat_item_categories__ml_ebs') }}
)
, cte_sat_item_categories__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_item_categories__ml_ebs'
        ,hk_field='item_categories_hk') }}
)


-- Taking seg2,3,4 for Sales and Operations Planning as they represent category, sub_cat, class                                
, attr_sales_oper_plan as(
    select ib.ITEM_HK, 
            cb.segment2 as item_category,
            cb.segment3 as item_sub_category,
            cb.segment4 as item_main_class 
    from {{ ref('hub_item') }} ah
    JOIN cte_sat_item_base__ml_ebs__latest ib on ah.ITEM_HK = ib.ITEM_HK
    JOIN cte_sat_item_language__ml_ebs__latest itl on ah.ITEM_HK = itl.ITEM_HK
    and itl.language = 'US'
    and itl.REC_SRC = 'ML EBS'
    join (select distinct ITEM_HK, category_set_id,
         first_value(category_id) OVER (PARTITION BY category_set_id, ITEM_HK ORDER BY LOAD_DTS,LAST_UPDATE_DATE DESC NULLS LAST) as category_id
         from cte_sat_item_categories__ml_ebs__latest) ic
         on ib.ITEM_HK = ic.ITEM_HK
    join {{ ref('ref_item_categories_base__ml_ebs') }} cb
          on ic.category_id = cb.category_id
    join {{ ref('ref_item_category_group__ml_ebs') }} stl 
          on ic.category_set_id = stl.category_set_id 
          and stl.category_set_name = 'Sales and Operations Planning'

),
-- Joining with rest attributes                                                                  
unpivoted as(                               
    select ib.item_hk, ib.inventory_item_id as item_id, ib.organization_id as plant, 
          REGEXP_SUBSTR(long_description, '<b>(.*?)</b>', 1, 1, 'e', 1) as item_title,
        --   SUBSTR(REPLACE(ib.description, '"', ''''''),1,80) base_material,
          ib.material as base_material,
          ib.primary_unit_of_measure	As	PRIMARY_UNIT_OF_MEASURE,
          ib.inventory_item_status_code item_status,
          ib.item_type as item_type_code,
          stl.category_set_name as Attribute, cb.segment1 as Value,
          asp.item_category,
          asp.item_sub_category,
          asp.item_main_class,
          'TMLC' As Brand 
    from {{ ref('hub_item') }} ah
    JOIN cte_sat_item_base__ml_ebs__latest ib on ah.ITEM_HK = ib.ITEM_HK
    JOIN cte_sat_item_language__ml_ebs__latest itl on ah.ITEM_HK = itl.ITEM_HK
    and itl.language = 'US'
    and itl.REC_SRC = 'ML EBS'
    join (select distinct ITEM_HK, category_set_id,
         first_value(category_id) OVER (PARTITION BY category_set_id, ITEM_HK ORDER BY LOAD_DTS,LAST_UPDATE_DATE DESC NULLS LAST) as category_id
         from cte_sat_item_categories__ml_ebs__latest ) ic
         on ib.ITEM_HK = ic.ITEM_HK
    join {{ ref('ref_item_categories_base__ml_ebs') }} cb
          on ic.category_id = cb.category_id
    join {{ ref('ref_item_category_group__ml_ebs') }} stl
          on ic.category_set_id = stl.category_set_id
          and stl.category_set_name != 'Sales and Operations Planning'
    left join attr_sales_oper_plan asp
          on ib.item_hk = asp.item_hk
    where stl.category_set_name in ('Pricing', 'Commercial', 'Registered Brand', 'Prod Class', 'Finish', 'Retail_Seg', 'Body_Size')

),
-- Pivoting to get final values
pivoted as (
  SELECT * 
    FROM unpivoted
      pivot(max(value) for attribute in ('Pricing', 'Commercial', 'Registered Brand', 'Prod Class', 'Finish', 'Retail_Seg', 'Body_Size'))
      as p(ITEM_HK, ITEM_ID, PLANT, ITEM_TITLE, BASE_MATERIAL,PRIMARY_UNIT_OF_MEASURE, ITEM_STATUS, ITEM_TYPE_CODE, ITEM_CATEGORY, ITEM_SUB_CATEGORY, ITEM_MAIN_CLASS, BRAND, Pricing,	Commercial,	Registered_Brand, Product_Class, Finish, Retail_Seg, Size_Attribute)
),

master_plant_data as (
  select * from pivoted where plant = 1
),
-- Deriving from master plant(1) if actual plant doesnt have attributes
master_plant_resolved_items as (
  select distinct m.item_hk,
  to_char(p.item_id) as item_id, p.plant,
  FIRST_VALUE(coalesce(p.item_title, m.item_title)) OVER (PARTITION BY to_char(p.item_id) ORDER BY len(coalesce(p.item_title, m.item_title)) NULLS LAST) AS item_title,
  coalesce(p.base_material, m.base_material) as base_material,
  case when p.item_status = 'Obsolete' then 'Inactive'
        else p.item_status end as item_status,
  coalesce(p.item_type_code, m.item_type_code) as item_type_code,
  coalesce(p.item_category, m.item_category) as item_category,
  coalesce(p.item_sub_category, m.item_sub_category) as item_sub_category,
  coalesce(p.item_main_class, m.item_main_class) as item_main_class,
  coalesce(p.Pricing, m.Pricing) as Pricing,
--   coalesce(p.Commercial, m.Commercial) as Commercial,
  coalesce(p.Registered_Brand, m.Registered_Brand) as Registered_Brand,
  coalesce(p.Product_Class, m.Product_Class) as Product_Class,
  coalesce(p.Finish, m.Finish) as Finish,
  coalesce(p.Retail_Seg, m.Retail_Seg) as Business_Segment,
  p.Brand, 
  coalesce(p.primary_unit_of_measure, m.primary_unit_of_measure) as PRIMARY_UNIT_OF_MEASURE,
  coalesce(p.Size_Attribute,m.Size_Attribute) as Size_Attribute
  from pivoted p
  left join master_plant_data m 
  on p.item_id = m.item_id
  where p.plant != 1
),
-- Applying registered brand logic
registered_brand_items as (
select distinct * exclude(plant, Registered_Brand),
decode(Registered_Brand,'Sentry Safe','SAFES','LOCKS') as item_area
from master_plant_resolved_items
-- where product_status = 'Active'
),

-- Adding Item Categories from reference
item_categories as (
    select distinct
    item_hk ,
    item_id	,
    item_title	,
    i.base_material	,
    upper(item_status) as item_status	,
    item_type_code	,
    map.category as item_category	,
    map.sub_category as item_sub_category	,
    map.class as item_class	,
    map.sub_class as item_sub_class	,
    pricing	,
    finish	,
    business_segment	,
    brand	,
    primary_unit_of_measure	,
    size_attribute	,
    item_area	
    from registered_brand_items i
    left join {{ ref('ref_item_category_map') }} map 
        on i.base_material = map.base_material
),

--- Giving preference to item status
im_item_status as
(
  select *,
  case when item_status = 'ACTIVE' then  1 when item_status = 'INACTIVE' then 2
       when item_status = 'PHASE-OUT' then  3 when item_status = 'SCRAP' then 4
       when item_status = 'REWORK' then  5 when item_status = 'DRAW DOWN' then 6
       when item_status = 'SETUP' then  7 when item_status = 'ENG SET-UP' then 8
  else 9 end as item_status_order
  from item_categories
),

--- Giving preference to List pricing
im_pricing_order as
(
  select * exclude(item_status_order),
  case when pricing = 'List' then  1 when pricing = 'Custom' then 2 else 3 end as pricing_order
  from im_item_status 
    where (item_id, brand, item_status_order) in 
        (select item_id, brand, min(item_status_order) from im_item_status group by item_id, brand)

),

--- Giving preference to less length base material
im_base_material_order as
(
select * exclude(pricing_order),
    len(base_material) as base_material_order
from im_pricing_order
    where (item_id, brand, pricing_order) in 
        (select item_id, brand, min(pricing_order) from im_pricing_order group by item_id, brand)
),

--- Giving preference to non expired item
im_exp_item_order as
(
select * exclude(base_material_order),
    case when item_type_code = 'FG' then  1 
         when item_type_code = 'COMP' then 2
         when item_type_code = 'EXP' then 3
    else 9 end as item_type_code_order   
from im_base_material_order
    where (item_id, brand, base_material_order) in 
        (select item_id, brand, min(base_material_order) from im_base_material_order group by item_id, brand)
),

--- Giving preference to non null category
im_category_order as
(
select * exclude(item_type_code_order),
       to_number(item_category is null)+1 as category_order
from im_exp_item_order
    where (item_id, brand, item_type_code_order) in 
        (select item_id, brand, min(item_type_code_order) from im_exp_item_order group by item_id, brand)
),

--- Giving random preference so that one item id exists
im_random_order as
(
select * exclude(category_order),
        dense_rank() over(partition by item_id, brand order by base_material) as random_order
from im_category_order
    where (item_id, brand, category_order) in 
        (select item_id, brand, min(category_order) from im_category_order group by item_id, brand)
)

select distinct * exclude(random_order)
from im_random_order
    where (item_id, brand, random_order) in 
        (select item_id, brand, min(random_order) from im_random_order group by item_id, brand)