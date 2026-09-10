{{
    config(
        materialized='ephemeral'
    )
}}


WITH msat_supplier_site_phone__mdm AS (
    SELECT
        supplier_site_hk,
        phone_type,
        contact_type_seq_no,
        load_dts,
        phone_number,
        parent_id,
        business_id,
        last_run_date
    FROM {{ ref('msat_supplier_site_phone__mdm') }}
    QUALIFY (ROW_NUMBER() OVER(PARTITION BY supplier_site_hk, phone_type, contact_type_seq_no ORDER BY load_dts DESC)) = 1
),

msat_supplier_site_phone__mdm_pivot AS (
    SELECT
        supplier_site_hk,
        contact_type_seq_no,
        load_dts,
        phone_number,
        fax_number,
        parent_id,
        business_id,
        last_run_date
    FROM msat_supplier_site_phone__mdm
    PIVOT (
        MAX(phone_number) FOR phone_type IN ('Telephone' AS phone_number, 'Fax' AS fax_number)
    )
),

msat_supplier_site_phone__mdm_grp AS (
    SELECT
        supplier_site_hk,
        parent_id,
        business_id,
        MAX(last_run_date) as last_run_date,
        LISTAGG(phone_number, ', ') WITHIN GROUP (ORDER BY phone_number) AS phone_number,
        LISTAGG(fax_number, ', ') WITHIN GROUP (ORDER BY fax_number) AS fax_number
    FROM msat_supplier_site_phone__mdm_pivot
    GROUP BY ALL
)

--Final Layer
SELECT
    supplier_site_hk,
    parent_id,
    business_id,
    last_run_date,
    phone_number,
    fax_number
FROM msat_supplier_site_phone__mdm_grp