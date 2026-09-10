with
cte_ap_suppliers as (
    select
        segment1
        , vendor_id
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , vendor_name
        , vendor_name_alt
        , last_update_login
        , creation_date
        , created_by
        , vendor_type_lookup_code
        , one_time_flag
        , bill_to_location_id
        , terms_id
        , always_take_disc_flag
        , pay_date_basis_lookup_code
        , pay_group_lookup_code
        , num_1099
        , start_date_active
        , payment_method_lookup_code
        , qty_rcv_tolerance
        , qty_rcv_exception_code
        , enforce_ship_to_location_code
        , receipt_days_exception_code
        , receiving_routing_id
        , state_reportable_flag
        , federal_reportable_flag
        , attribute1
        , program_update_date
        , tax_reporting_name
        , party_id
        , tca_sync_num_1099
        , tca_sync_vendor_name
        , tca_sync_vat_reg_num
    from {{ source("emtk_ebs_po__ap", "ap_suppliers") }}
    where _fivetran_deleted = false
)

, cte_union_default as (
    /* because vendor_id can be NULL on po_headers_all */
    select
        '-1' as segment1
        , null as vendor_id
        , null as last_update_date
        , '1900-01-01' as _fivetran_synced
        , null as last_updated_by
        , null as vendor_name
        , null as vendor_name_alt
        , null as last_update_login
        , null as creation_date
        , null as created_by
        , null as vendor_type_lookup_code
        , null as one_time_flag
        , null as bill_to_location_id
        , null as terms_id
        , null as always_take_disc_flag
        , null as pay_date_basis_lookup_code
        , null as pay_group_lookup_code
        , null as num_1099
        , null as start_date_active
        , null as payment_method_lookup_code
        , null as qty_rcv_tolerance
        , null as qty_rcv_exception_code
        , null as enforce_ship_to_location_code
        , null as receipt_days_exception_code
        , null as receiving_routing_id
        , null as state_reportable_flag
        , null as federal_reportable_flag
        , null as attribute1
        , null as program_update_date
        , null as tax_reporting_name
        , null as party_id
        , null as tca_sync_num_1099
        , null as tca_sync_vendor_name
        , null as tca_sync_vat_reg_num
)

, cte_supplier_final as (
    select
        s.segment1
        , s.vendor_id
        , s.last_update_date
        , s._fivetran_synced
        , s.last_updated_by
        , s.vendor_name
        , s.vendor_name_alt
        , s.last_update_login
        , s.creation_date
        , s.created_by
        , s.vendor_type_lookup_code
        , s.one_time_flag
        , s.bill_to_location_id
        , s.terms_id
        , s.always_take_disc_flag
        , s.pay_date_basis_lookup_code
        , s.pay_group_lookup_code
        , s.num_1099
        , s.start_date_active
        , s.payment_method_lookup_code
        , s.qty_rcv_tolerance
        , s.qty_rcv_exception_code
        , s.enforce_ship_to_location_code
        , s.receipt_days_exception_code
        , s.receiving_routing_id
        , s.state_reportable_flag
        , s.federal_reportable_flag
        , s.attribute1
        , s.program_update_date
        , s.tax_reporting_name
        , s.party_id
        , s.tca_sync_num_1099
        , s.tca_sync_vendor_name
        , s.tca_sync_vat_reg_num
    from cte_ap_suppliers as s

    union all

    select * from cte_union_default

)

select * from cte_supplier_final
