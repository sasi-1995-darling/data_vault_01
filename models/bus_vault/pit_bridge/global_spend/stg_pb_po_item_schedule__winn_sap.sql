{{
    config(
        materialized='ephemeral'
    )
}}

with 
  cte_sat_po_item_schedule_lines__winn_sap as 
(
    select * from {{ ref('sat_po_item_schedule_lines__winn_sap') }}
    QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY po_item_hk, etenr ORDER BY load_dts DESC)
)


,cte_sat_po_item_schedule_lines__winn_sap_aggr as 
(
    select po_item_hk, 
        max(EINDT)  MAX_EINDT,
        min(EINDT) MIN_EINDT    
    from cte_sat_po_item_schedule_lines__winn_sap
    GROUP BY ALL 
)


select     
    s.po_item_hk,
    s.MAX_EINDT::INTEGER as REQUESTED_DELIVERY_DATE_LATEST,
     s.MIN_EINDT::INTEGER as REQUESTED_DELIVERY_DATE_EARLIEST
from cte_sat_po_item_schedule_lines__winn_sap_aggr s
