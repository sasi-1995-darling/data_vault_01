{{
    config(
        materialized='ephemeral'
    )
}}


with
    msat_supplier_site_email__mdm_latest as (
        select
            supplier_site_hk,
            usage_type,
            contact_type_seq_no,
            parent_id,
            business_id,
            load_dts,
            email_address,
            last_run_date
        from {{ ref('msat_supplier_site_email__mdm') }}
        qualify (row_number() over(partition by supplier_site_hk, usage_type, contact_type_seq_no order by load_dts desc)) = 1
    ), 

    msat_supplier_site_email__mdm_grp as (
        select
            supplier_site_hk,
            parent_id,
            business_id,
            usage_type,
            max(last_run_date) as last_run_date,
            listagg(email_address, ', ') within group (order by email_address) as email_address
        from msat_supplier_site_email__mdm_latest
        group by all
    )
    
-- Final Layer
select
    supplier_site_hk,
    parent_id,
    business_id,
    usage_type,
    last_run_date,
    email_address
from msat_supplier_site_email__mdm_grp
