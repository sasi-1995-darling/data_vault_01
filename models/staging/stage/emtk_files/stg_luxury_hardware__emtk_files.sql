with cte_unioned as (

{{ dbt_utils.union_relations(relations = [
    ref('base_luxury_hardware_bath__emtk_files'),
    ref('base_luxury_hardware_cabinet__emtk_files')
]
,column_override = {"PROJECTION_WITH_DISC": "varchar(256)",
                    "WIDTH": "varchar(256)",
                    "OVERALL": "varchar(256)",
                    "PRODUCT_WEIGHT_POUNDS": "varchar(256)",
                    "CARTON_1_HEIGHT_EST": "varchar(256)",
                    "CARTON_1_WIDTH_EST_BASED_ON_OVERALL": "varchar(256)",
                    "CARTON_1_DEPTH_EST": "varchar(256)",
                    "NUMBER_OF_BACKPLATES_INCLUDED": "varchar(256)",
                    "NUMBER_OF_HOOKS": "varchar(256)",
                    "ROLL_CAPACITY": "varchar(256)",
                    "UPC": "varchar(256)"
                    }) }}
)

select * from cte_unioned
