--fact_purchase_order_line_transaction - type 1
-- grain is one row per transaction per po line
with cte_tlink_po_line_transaction as (
    select * from {{ ref('tlink_po_line_transaction') }}
)

, cte_link_po_line as (
    select * from {{ ref('link_po_line') }}
)

, cte_link_po_line_item_plant_location as (
    select * from {{ ref('link_po_line_item_plant_location') }}
)

, cte_link_po_supplier as (
    select * from {{ ref('link_po_supplier') }}
)

, cte_link_supplier_contact as (
    select * from {{ ref('link_supplier_contact') }}
)

, cte_link_po_line_shipment as (
    select * from {{ ref('link_po_line_shipment') }}
)

-- po line transaction fields- 1/3
, cte_sat_po_line_transaction_detail__emtk_ebs as (
    select * from {{ ref('sat_po_line_transaction_detail__emtk_ebs') }}
)

-- po line transaction fields - 2/3
, cte_sat_po_line_transaction_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_po_line_transaction_detail__emtk_ebs'
        ,hk_field='po_line_transaction_link_hk') }}
)

-- po line transaction fields - 3/3
, cte_transaction_fact_fields as (
    select
        po_line_transaction_link_hk
        , transaction_id
        , to_date(transaction_date) as transaction_date
        , transaction_date as transacted_at
        , transaction_type
        , quantity
        , unit_of_measure
        , inspection_status_code
        , shipment_num
        , shipped_date
        , destination_type_code
        , shipment_header_id
        , shipment_line_id
        , primary_quantity
        , primary_unit_of_measure
        , po_unit_price
        , brand
    from cte_sat_po_line_transaction_detail__emtk_ebs__latest
)

--keep just most recent supplier data for purchase order
, cte_link_po_supplier_latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_link_po_supplier'
        ,hk_field='purchase_order_hk') }}
)

-- primary supplier email 1/3
, cte_sat_contact_detail__emtk_ebs as (
    select * from {{ ref('sat_contact_detail__emtk_ebs') }}
)

-- primary supplier email 2/3
, cte_sat_contact_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_contact_detail__emtk_ebs'
        ,hk_field='contact_hk') }}
)

-- primary supplier email 3/3
, cte_supplier_primary_email as (
    select
        link_sc.supplier_hk
        , sat_cd_l.contact_hk
        , row_number() over (
            partition by link_sc.supplier_hk
            order by sat_cd_l.last_update_date desc
        ) as row_num
    from cte_sat_contact_detail__emtk_ebs__latest as sat_cd_l
        inner join cte_link_supplier_contact as link_sc
            on sat_cd_l.contact_hk = link_sc.contact_hk
    where sat_cd_l.contact_point_type = 'EMAIL'
        and sat_cd_l.primary_flag = 'Y'
-- qualify row_num = 1 (not working for some reason)
)

-- item inventory category 1/3
, cte_msat_item_category__emtk_ebs as (
    select * from {{ ref('msat_item_category__emtk_ebs') }}
)

-- item inventory category 2/3
, cte_msat_item_category__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_msat_item_category__emtk_ebs'
        ,hk_field='item_category_hk') }}
)

-- item inventory category 3/3
, cte_item_inventory_category as (
    select
        item_hk
        , item_category_hk
        , row_number() over (
            partition by item_hk
            order by last_update_date desc
        ) as row_num
    from cte_msat_item_category__emtk_ebs__latest
    where category_set_id = 1 -- inventory
-- qualify row_num = 1 (not working for some reason)
)

-- po header dates 1/3
, cte_sat_po_detail__emtk_ebs__emtk_ebs as (
    select * from {{ ref('sat_po_detail__emtk_ebs') }}
)

-- po header dates 2/3
, cte_sat_po_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_po_detail__emtk_ebs__emtk_ebs'
        ,hk_field='purchase_order_hk') }}
)

-- po header dates 3/3
, cte_purchase_order_header_dates as (
    select
        purchase_order_hk
        , to_date(creation_date) as po_created_date
        , to_date(closed_date) as po_closed_date
    from cte_sat_po_detail__emtk_ebs__latest
)

-- po line dates 1/3
, cte_sat_po_line_detail__emtk_ebs as (
    select * from {{ ref('sat_po_line_detail__emtk_ebs') }}
)

-- po line dates 2/3
, cte_sat_po_line_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_po_line_detail__emtk_ebs'
        ,hk_field='po_line_hk') }}
)

-- po line dates 3/3
, cte_purchase_order_line_dates as (
    select
        po_line_hk
        , to_date(closed_date) as po_line_closed_date
    from cte_sat_po_line_detail__emtk_ebs__latest
)

-- po first approval date 1/3
, cte_msat_po_action__emtk_ebs as (
    select * from {{ ref('msat_po_action__emtk_ebs') }}
    where action_code = 'APPROVE'
)

-- po first approval date 2/3
, cte_msat_po_action__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_msat_po_action__emtk_ebs'
        ,hk_field='purchase_order_hk') }}
)

-- po first approval date 3/3
, cte_po_first_approval_date as (
    select
        purchase_order_hk
        , min(to_date(action_date)) as po_first_approved_date
    from cte_msat_po_action__emtk_ebs__latest
    group by purchase_order_hk
)

, cte_final as (
    select
        tlink_polt.po_line_transaction_link_hk as fact_purchase_order_line_transaction_pk
        , link_pols.po_line_shipment_hk as dim_purchase_order_line_shipment_pk
        , link_pols.po_line_hk as dim_purchase_order_line_pk
        , link_pol.purchase_order_hk as dim_purchase_order_pk
        , link_polipl.plant_location_hk as dim_plant_location_pk
        , link_pos.supplier_hk as dim_supplier_pk
        , link_pos.supplier_site_hk as dim_supplier_site_pk
        , coalesce(spe.contact_hk, to_binary('545A07F6F4B4611BD8601A1BABD4A8E7')) as dim_contact_supplier_email_pk
        , link_polipl.item_hk as dim_item_pk
        , iic.item_category_hk as dim_item_inventory_category_pk
        , pohd.po_created_date
        , pohd.po_closed_date
        , pold.po_line_closed_date
        , coalesce(pfad.po_first_approved_date, '1900-01-01') as po_first_approved_date
        , tff.transaction_id
        , tff.transaction_date
        , tff.transacted_at
        , tff.transaction_type
        , tff.quantity
        , tff.unit_of_measure
        , tff.inspection_status_code
        , tff.shipment_num
        , tff.shipped_date
        , tff.destination_type_code
        , tff.shipment_header_id
        , tff.shipment_line_id
        , tff.primary_quantity
        , tff.primary_unit_of_measure
        , tff.po_unit_price
        , tff.brand
    from cte_tlink_po_line_transaction as tlink_polt
        inner join cte_link_po_line as link_pol
            on tlink_polt.po_line_hk = link_pol.po_line_hk
        inner join cte_link_po_line_shipment as link_pols
            on link_pol.po_line_hk = link_pols.po_line_hk
        /* ToDo - make left join to cte_link_po_line_item_plant_location with valid "unknown" item key */
        inner join cte_link_po_line_item_plant_location as link_polipl
            on link_pol.po_line_hk = link_polipl.po_line_hk
        inner join cte_link_po_supplier_latest as link_pos
            on link_pol.purchase_order_hk = link_pos.purchase_order_hk
        left join cte_supplier_primary_email as spe
            on link_pos.supplier_hk = spe.supplier_hk
                and spe.row_num = 1
        inner join cte_item_inventory_category as iic
            on link_polipl.item_hk = iic.item_hk
                and iic.row_num = 1
        inner join cte_purchase_order_header_dates as pohd
            on link_pol.purchase_order_hk = pohd.purchase_order_hk
        inner join cte_purchase_order_line_dates as pold
            on link_pol.po_line_hk = pold.po_line_hk
        left outer join cte_po_first_approval_date as pfad
            on link_pol.purchase_order_hk = pfad.purchase_order_hk
        inner join cte_transaction_fact_fields as tff
            on tlink_polt.po_line_transaction_link_hk = tff.po_line_transaction_link_hk
)

select * from cte_final
