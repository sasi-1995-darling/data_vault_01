select * from ({{validity_check('fact_global_spend_detail','cal_year','business_unit',["'WINN','SECURITY','OUTDOORS'"],"NOT BETWEEN 1990 and 2030")}})
union all
select * from ({{validity_check('fact_global_spend_detail','cal_month','business_unit',["'WINN','SECURITY','OUTDOORS'"],"NOT IN (1,2,3,4,5,6,7,8,9,10,11,12)")}})
union all
select * from ({{validity_check('fact_global_spend_detail','order_qty','business_unit',["'WINN','SECURITY','OUTDOORS'"],"< 0")}})
union all
select * from ({{validity_check('fact_global_spend_detail','order_qty','business_unit',["'WINN','SECURITY','OUTDOORS'"],"< 0")}})
union all
select * from ({{validity_check('fact_global_spend_detail','business_unit','business_unit',["'WINN','SECURITY','OUTDOORS'"],"NOT IN ('WINN','SECURITY','OUTDOORS')")}})
union all
select * from ({{validity_check('fact_global_spend_detail','CONSIGNMENT_IND','business_unit',["'WINN'"],"NOT IN ('Y','N')")}})