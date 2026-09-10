with cte_cust as (select * from {{ source("bronze_lrsn_psft", "ps_l_rep_cust") }})

select distinct
    cte_cust.setid
    , cte_cust.business_unit
    , cte_cust.cust_id
    , cte_cust.cust_name
    , cte_cust.sold_to_flg
    , cte_cust.ship_from_bu
    , cte_cust.route_cd
    , cte_cust.store_number
    , cte_cust.corporate_cust_id
    , cte_cust.l_corp_cust_name
    , cte_cust.l_region
    , cte_cust.bill_to_cust_id
    , cte_cust.region_cd
    , cte_cust.l_pb_email
    , cte_cust.address1
    , cte_cust.address2
    , cte_cust.city
    , cte_cust.state
    , cte_cust.postal
    , cte_cust.country
from cte_cust
where cte_cust._fivetran_deleted = false
