with cte_supplier_bk as (
    select
        segment1 --BK
        , party_id
    from {{ source("emtk_ebs_po__ap", "ap_suppliers") }}
    where _fivetran_deleted = false
)

, cte_contact_bk as (
    select
        contact_point_id::varchar as contact_point_id--BK
        , owner_table_id
    from {{ source('emtk_ebs_common__ar', 'hz_contact_points') }}
    where _fivetran_deleted = false
        and owner_table_name = 'HZ_PARTY_SITES'
)

, cte_hz_party_sites as (
    select
        party_site_id
        , party_id
        , _fivetran_synced -- load_dts
    from {{ source("emtk_ebs_common__ar", "hz_party_sites") }}
    where _fivetran_deleted = false
)

, cte_final as (
    select distinct
        sup.segment1
        , con.contact_point_id
        , hps._fivetran_synced

    from cte_hz_party_sites as hps
        inner join cte_supplier_bk as sup on hps.party_id = sup.party_id
        inner join cte_contact_bk as con on hps.party_site_id = con.owner_table_id
)

select * from cte_final
