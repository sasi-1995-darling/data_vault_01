select * from {{ ref('v_shipment__ml_ebs') }}
union all
select * from {{ ref('v_shipment__tt_e21') }}
union all
select * from {{ ref('t_shipment__moen_sap') }}