with cte_contact as (
    select *
    from {{ source('emtk_crm_sales', 'contact') }}
    where _fivetran_deleted = false
)

, cte_sales_rep as (
    select *
    from {{ source('emtk_crm_sales', 'fbin_salesrep') }}
    where _fivetran_deleted = false
)

, cte_sales_rep_agency_to_contact as (
    select *
    from {{ source('emtk_crm_sales', 'fbin_salesrepagencytocontact') }}
    where _fivetran_deleted = false
    -- one contactid from contacts can link to many _fbin_contact_value in this table
    -- when duplicate _fbin_contact_value <> _fbin_salesrepagency_value, 
    --    pick the most recent version based on versionnumber
    qualify
        row_number() over (partition by _fbin_contact_value, _fbin_salesrepagency_value order by versionnumber desc) = 1
)

, cte_jtf_rs_salesreps as (
    select *
    from {{ source('emtk_ebs_sales__jtf', 'jtf_rs_salesreps') }}
    where _fivetran_deleted = false
)

, cte_distinct_terrirtories as (
    -- NOTE: Oracle stores business territories in the SalesRep table
    select distinct salesrep_number as territory_security_key
    from cte_jtf_rs_salesreps
)

, cte_final as (
    select
        lower(c.emailaddress_1) as sales_rep_email
        -- NOTE: Oracle stores business territories in the SalesRep table
        , jtfsr.salesrep_number as territory_security_key
    from cte_contact as c
        inner join cte_sales_rep_agency_to_contact as sratc
            on c.contactid = sratc._fbin_contact_value
        inner join cte_sales_rep as sr
            on sratc._fbin_salesrepagency_value = sr.fbin_salesrepid
        ------- Oracle EBS joins to get to territory
        inner join cte_jtf_rs_salesreps as jtfsr
            on sr.fbin_salesrepnumber = jtfsr.salesrep_number

    union

    -- the following query is to add power user emails
    select
        value as sales_rep_email
        , salesrep_number as territory_security_key
    from cte_jtf_rs_salesreps
    ,
        lateral strtok_split_to_table(
            'anthony.campomizzi@moen.com|megan.fricker@moen.com|zach.hubel@fbin.com|dezcleveland@gmail.com'
            , '|'
        )
)

-- Power_user_email, Date_entered, Created_by, Updated_by
select *
from cte_final

