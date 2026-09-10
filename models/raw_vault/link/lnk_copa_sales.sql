{{
  config(
    full_refresh = var('force_full_refresh', false)
  )
}}
---- SRC LAYER ----
WITH
    src_ce1new4 AS (
        SELECT
            lnk_copa_sales_hk,
            copa_hk,
            controlling_area_hk,
            cost_center_hk,
            cost_element_hk,
            currency_type_hk,
            order_header_hk,
            order_line_hk,
            customer_hk,
            sales_organization_hk,
            distribution_channel_hk,
            division_hk,
            item_hk,
            plant_hk,
            mandt,
            vrgar,
            versi,
            perio,
            paobjnr,
            pasubnr,
            load_dts,
            rec_src
        FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} AS src
        {% if is_incremental() %} --this block added to reduce the computation/processing after a full load
        WHERE src.load_dts > current_date - 4 
        {% endif %}
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hash(
                belnr,
                posnr,
                kokrs,
                skost,
                kstar,
                paledger,
                kaufn,
                kdpos,
                mandt,
                vrgar,
                versi,
                perio,
                paobjnr,
                pasubnr,
                kndnr,
                vkorg,
                vtweg,
                spart,
                artnr,
                werks
            )
            ORDER BY glchangetime
        ) = 1
    ),

    -- the below table scan is required for only the initial load due to the historical data
    {% if not is_incremental() %}
    src_azcopa AS (
        SELECT
            lnk_copa_sales_hk,
            copa_hk,
            controlling_area_hk,
            cost_center_hk,
            cost_element_hk,
            currency_type_hk,
            order_header_hk,
            order_line_hk,
            customer_hk,
            sales_organization_hk,
            distribution_channel_hk,
            division_hk,
            item_hk,
            plant_hk,
            mandt,
            vrgar,
            versi,
            perio,
            paobjnr,
            pasubnr,
            load_dts,
            rec_src
        FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} AS src
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hash(
                belnr,
                posnr,
                kokrs,
                skost,
                kstar,
                paledger,
                kaufn,
                kdpos,
                mandt,
                vrgar,
                versi,
                perio,
                paobjnr,
                pasubnr,
                kndnr,
                vkorg,
                vtweg,
                spart,
                artnr,
                werks
            )
            ORDER BY zextractdate
        ) = 1
    ),
    {% endif %}

---- JOIN LAYER ----

join_result AS (
    SELECT * FROM src_ce1new4
    {% if not is_incremental() %} -- the union is required for only the initial load due to the historical data
    UNION ALL
    SELECT * FROM src_azcopa
    {% endif %}
)

---- FINAL LAYER ----

SELECT
    lnk_copa_sales_hk,
    copa_hk,
    controlling_area_hk,
    cost_center_hk,
    cost_element_hk,
    currency_type_hk,
    order_header_hk,
    order_line_hk,
    customer_hk,
    sales_organization_hk,
    distribution_channel_hk,
    division_hk,
    item_hk,
    plant_hk,
    mandt,
    vrgar,
    versi,
    perio,
    paobjnr,
    pasubnr,
    load_dts,
    rec_src
FROM join_result
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1
    FROM {{ this }} existing
    WHERE existing.lnk_copa_sales_hk = join_result.lnk_copa_sales_hk
)
{% endif %}
{% if not is_incremental() %}
UNION ALL
SELECT
    md5_binary(gr.value) AS lnk_copa_sales_hk,
    md5_binary(gr.value) AS copa_hk,
    md5_binary(gr.value) AS controlling_area_hk,
    md5_binary(gr.value) AS cost_center_hk,
    md5_binary(gr.value) AS cost_element_hk,
    md5_binary(gr.value) AS currency_type_hk,
    md5_binary(gr.value) AS order_header_hk,
    md5_binary(gr.value) AS order_line_hk,
    md5_binary(gr.value) AS customer_hk,
    md5_binary(gr.value) AS sales_organization_hk,
    md5_binary(gr.value) AS distribution_channel_hk,
    md5_binary(gr.value) AS division_hk,
    md5_binary(gr.value) AS item_hk,
    md5_binary(gr.value) AS plant_hk,
    gr.value::text AS mandt,
    gr.value::text AS vrgar,
    gr.value::text AS versi,
    gr.value::text AS perio,
    gr.value::text AS paobjnr,
    gr.value::text AS pasubnr,
    convert_timezone('UTC', '1900-01-01'::timestamp) AS load_dts,
    'usazet.snowflake.fbin.derived' AS rec_src
FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS gr
{% endif %}