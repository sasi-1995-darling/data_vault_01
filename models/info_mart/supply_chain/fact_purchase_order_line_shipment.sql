--fact_purchase_order_line_shipment - type 1
-- grain is one row per shipment schedule per po line
with cte_link_po_line_shipment as (
    select * from {{ ref('link_po_line_shipment') }}
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

, cte_tlink_po_line_transaction as (
    select * from {{ ref('tlink_po_line_transaction') }}
)

-- po line transaction - used for multiple rollups 1/3
, cte_sat_po_line_transaction_detail__emtk_ebs as (
    select * from {{ ref('sat_po_line_transaction_detail__emtk_ebs') }}
)

-- po line transaction - used for multiple rollups 2/3
, cte_sat_po_line_transaction_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_po_line_transaction_detail__emtk_ebs'
        ,hk_field='po_line_transaction_link_hk') }}
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
    select
        *
        , rank() over (
            partition by purchase_order_hk
            order by load_dts desc
        ) as row_num
    from cte_msat_po_action__emtk_ebs
)

-- po first approval date 3/3
, cte_po_first_approval_date as (
    select
        purchase_order_hk
        , min(to_date(action_date)) as po_first_approved_date
    from cte_msat_po_action__emtk_ebs__latest
    where row_num = 1
    group by purchase_order_hk
)

-- shipment fields for fact 1/4
, cte_sat_po_line_shipment_detail__emtk_ebs as (
    select * from {{ ref('sat_po_line_shipment_detail__emtk_ebs') }}
)

-- shipment fields for fact 2/4
, cte_sat_po_line_shipment_detail__emtk_ebs_latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_po_line_shipment_detail__emtk_ebs'
        ,hk_field='po_line_shipment_hk') }}
)

-- shipment fields for fact 3/4
, cte_hub_po_line_shipment as (
    select * from {{ ref('hub_po_line_shipment') }}
)

-- shipment fields for fact 4/4
, cte_shipment_fact_fields as (
    select
        hub_pls.po_line_shipment_hk
        , sat_plsd.quantity_billed as invoiced_quantity
        , hub_pls.brand
    from cte_sat_po_line_shipment_detail__emtk_ebs_latest as sat_plsd
        inner join cte_hub_po_line_shipment as hub_pls
            on sat_plsd.po_line_shipment_hk = hub_pls.po_line_shipment_hk
)

-- po line transaction - 3a/3
-- any 'RETURN TO VENDOR' records nullify previous 'RECIEVE' records
, cte_shipped_quantity as (
    select
        tlink_plt.po_line_hk
        , sum(sat_pltd.quantity) as shipped_quantity
    from cte_sat_po_line_transaction_detail__emtk_ebs__latest as sat_pltd
        inner join cte_tlink_po_line_transaction as tlink_plt
            on sat_pltd.po_line_transaction_link_hk = tlink_plt.po_line_transaction_link_hk
    where sat_pltd.transaction_type = 'RECEIVE'
        and not exists (
            select 1 as constant
            from cte_sat_po_line_transaction_detail__emtk_ebs__latest as exclusion
            where exclusion.shipment_line_id = sat_pltd.shipment_line_id
                and exclusion.transaction_type = 'RETURN TO VENDOR'
        )
    group by tlink_plt.po_line_hk
)

-- po line transaction - 3b/3
, cte_received_quantity as (
    select
        tlink_plt.po_line_hk
        , sum(sat_pltd.quantity) as received_quantity
    from cte_sat_po_line_transaction_detail__emtk_ebs__latest as sat_pltd
        inner join cte_tlink_po_line_transaction as tlink_plt
            on sat_pltd.po_line_transaction_link_hk = tlink_plt.po_line_transaction_link_hk
    where sat_pltd.transaction_type = 'DELIVER'
    group by tlink_plt.po_line_hk
)

-- po line transaction - 3c/3
, cte_returned_quantity as (
    select
        tlink_plt.po_line_hk
        , sum(sat_pltd.quantity) as returned_quantity
    from cte_sat_po_line_transaction_detail__emtk_ebs__latest as sat_pltd
        inner join cte_tlink_po_line_transaction as tlink_plt
            on sat_pltd.po_line_transaction_link_hk = tlink_plt.po_line_transaction_link_hk
    where sat_pltd.transaction_type = 'RETURN TO VENDOR'
    group by tlink_plt.po_line_hk
)

-- po line transaction - 3d/3
, cte_transaction_fields as (
    select
        tlink_plt.po_line_hk
        , min(sat_pltd.shipment_num) as shipment_num
        , min(to_date(sat_pltd.shipped_date)) as first_shipped_date
        , max(to_date(sat_pltd.shipped_date)) as last_shipped_date
    from cte_sat_po_line_transaction_detail__emtk_ebs__latest as sat_pltd
        inner join cte_tlink_po_line_transaction as tlink_plt
            on sat_pltd.po_line_transaction_link_hk = tlink_plt.po_line_transaction_link_hk
    group by tlink_plt.po_line_hk
)

, cte_final as (
    select
        link_pols.po_line_shipment_link_hk as fact_purchase_order_line_shipment_pk
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
        , coalesce(trf.first_shipped_date, '1900-01-01') as po_line_first_shipped_date
        , coalesce(trf.last_shipped_date, '1900-01-01') as po_line_last_shipped_date
        , shq.shipped_quantity
        , shq.shipped_quantity - coalesce(rcq.received_quantity, 0) as asn_quantity
        , rcq.received_quantity
        , rtq.returned_quantity
        , sff.invoiced_quantity
        , trf.shipment_num
        , sff.brand
    from cte_link_po_line_shipment as link_pols
        inner join cte_link_po_line as link_pol
            on link_pols.po_line_hk = link_pol.po_line_hk
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
        inner join cte_shipment_fact_fields as sff
            on link_pols.po_line_shipment_hk = sff.po_line_shipment_hk
        left outer join cte_shipped_quantity as shq
            on link_pol.po_line_hk = shq.po_line_hk
        left outer join cte_received_quantity as rcq
            on link_pol.po_line_hk = rcq.po_line_hk
        left outer join cte_returned_quantity as rtq
            on link_pol.po_line_hk = rtq.po_line_hk
        left outer join cte_transaction_fields as trf
            on link_pol.po_line_hk = trf.po_line_hk

)

select * from cte_final
