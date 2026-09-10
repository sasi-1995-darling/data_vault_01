select * from ({{validity_check('dim_promotion','PROMOTION_REPORTING_CHANNEL','BKCC',["'Whistling_Walrus'"], "NOT IN ('EC','RT')")}})
union all
select * from ({{validity_check('dim_promotion','PROMOTION_REPORTING_CUSTOMER','BKCC',["'Whistling_Walrus'"], "NOT IN ('HOME DEPOT','MENARDS','AMAZON','LOWES')")}})
