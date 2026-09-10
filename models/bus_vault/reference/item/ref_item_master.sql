select * from {{ ref('ref_item_master__ml_ebs') }}
union all
select * from {{ ref('ref_item_master__tt_e21') }}
union all
select * from {{ ref('ref_item_master__moen_sap') }}
