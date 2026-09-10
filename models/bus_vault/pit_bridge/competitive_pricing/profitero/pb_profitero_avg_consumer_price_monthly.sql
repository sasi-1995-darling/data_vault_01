with cte_pb_competitive_product_winn as (/*get valid model and competitive product keys for winn*/
    select
        retailer_hk
        , competitive_product_bk
        , model
        , rec_src
        , bkcc
    from {{ ref('pb_competitive_product') }}
    where sat_rec_src = 'US.PROFITERO_WINN.PRODUCTS'
        and model is not null
)

, cte_item_base_material_winn as ( /*get unique item and base material for winn; org/plant na*/
    select distinct
        item_number
        , base_material_key
        , base_material
    from {{ ref('pb_items_by_plant') }}
    where bkcc = 'Hiding_Tiger'
)

, cte_product_base_material_winn as (
    /*join competitive products to base materials using the model/item_number relationship*/
    select
        cp.retailer_hk as retailer_key
        , cp.competitive_product_bk as product_id
        , bm.base_material_key
        , bm.base_material
        , cp.rec_src
        , cp.bkcc
    from cte_pb_competitive_product_winn as cp
        inner join cte_item_base_material_winn as bm
            on cp.model = bm.item_number

)

, cte_consumer_price_base_winn as (
    /*get valid winn profitero price for competitive product base material across fiscal period for >=2019*/
    select
        pbm.base_material_key
        , pbm.base_material
        , spcp.date
        , pdf.fiscal_445_cal_year
        , pdf.fiscal_445_cal_month_yyyymm
        , spcp.retailer_bk
        , spcp.retailer_key
        , spcp.sat_rec_src
        , pbm.rec_src
        , pbm.bkcc
        , spcp.regular_price
    from {{ ref('stg_pricing_competitive_profitero') }} as spcp
        inner join cte_product_base_material_winn as pbm
            on spcp.retailer_key = pbm.retailer_key
                and spcp.product_id = pbm.product_id
        left join {{ ref('pit_date_fiscal_445') }} as pdf
            on spcp.date = pdf.date
    where spcp.regular_price is not null
        and spcp.sat_rec_src = 'US.PROFITERO_WINN.PRICING_AVAILABILITY_HISTORY'
        and pdf.fiscal_445_cal_year >= 2019
)

, cte_fiscal_period_avg_consumer_price_winn as (
    /*calc avg consumer price for product base material across fiscal period*/
    select
        base_material_key
        , base_material
        , fiscal_445_cal_month_yyyymm
        , retailer_bk
        , retailer_key
        , sat_rec_src
        , rec_src
        , bkcc
        , avg(regular_price) as fiscal_period_avg_consumer_price
    from cte_consumer_price_base_winn
    group by all
)

, cte_fiscal_year_avg_consumer_price_winn as (/*calc avg consumer price for product base material across fiscal year*/
    select
        base_material_key
        , base_material
        , fiscal_445_cal_year
        , retailer_bk
        , retailer_key
        , sat_rec_src
        , rec_src
        , bkcc
        , avg(regular_price) as fiscal_year_avg_consumer_price
    from cte_consumer_price_base_winn
    group by all
)

, cte_all_time_avg_consumer_price_winn as (/*calc avg consumer price for product base material across all time*/
    select
        base_material_key
        , base_material
        , retailer_bk
        , retailer_key
        , sat_rec_src
        , rec_src
        , bkcc
        , avg(regular_price) as all_time_avg_consumer_price
    from cte_consumer_price_base_winn
    group by all
)

, cte_base_materials_winn as (/*unique combination of base material, retailer*/
    select distinct
        base_material
        , base_material_key
        , retailer_key
        , retailer_bk
        , sat_rec_src
        , rec_src
        , bkcc
    from cte_consumer_price_base_winn
)

, cte_fiscal_445_calendar_periods as ( /*get fiscal periods from 2019 to date*/
    select distinct
        fiscal_445_cal_month_yyyymm
        , fiscal_445_cal_year
    from {{ ref('pit_date_fiscal_445') }}
    where fiscal_445_cal_year >= 2019
        and date <= current_date()
)

, cte_base_material_fiscal_periods_base_winn as (
    /*all possible combinations of base material, retailer and fiscal periods*/
    select
        base_material
        , base_material_key
        , retailer_key
        , retailer_bk
        , sat_rec_src
        , rec_src
        , bkcc
        , fiscal_445_cal_month_yyyymm
        , fiscal_445_cal_year
    from cte_base_materials_winn
        cross join cte_fiscal_445_calendar_periods
)

, historized_consumer_price_base_winn as (
/*get avg consumer price for fiscal period, if not available fall back to fiscal year, if still not avalable fall back to all time avg*/
    select
        b.base_material as base_material_bk
        , b.base_material_key
        , b.fiscal_445_cal_month_yyyymm::integer as fiscal_445_cal_month__date_yyyymm
        , b.fiscal_445_cal_year::integer as fiscal_445_cal_year
        , b.retailer_bk
        , b.retailer_key
        , b.sat_rec_src
        , b.rec_src
        , b.bkcc
        , round(
            coalesce(
                fp.fiscal_period_avg_consumer_price, fy.fiscal_year_avg_consumer_price, ata.all_time_avg_consumer_price
            )::float
            , 2
        ) as avg_consumer_price
    from cte_base_material_fiscal_periods_base_winn as b
        left join cte_fiscal_period_avg_consumer_price_winn as fp
            on b.base_material_key = fp.base_material_key
                and b.retailer_key = fp.retailer_key
                and b.rec_src = fp.rec_src
                and b.fiscal_445_cal_month_yyyymm = fp.fiscal_445_cal_month_yyyymm
        left join cte_fiscal_year_avg_consumer_price_winn as fy
            on b.base_material_key = fy.base_material_key
                and b.retailer_key = fy.retailer_key
                and b.rec_src = fy.rec_src
                and b.fiscal_445_cal_year = fy.fiscal_445_cal_year
        left join cte_all_time_avg_consumer_price_winn as ata
            on b.base_material_key = ata.base_material_key
                and b.retailer_key = ata.retailer_key
                and b.rec_src = ata.rec_src
)

select
    random() as seq_id
    , current_date as snapshotdate
    , convert_timezone('UTC', current_timestamp) as pb_load_dts
    , base_material_bk
    , base_material_key
    , fiscal_445_cal_month__date_yyyymm
    , fiscal_445_cal_year
    , avg_consumer_price
    , retailer_bk
    , retailer_key
    , sat_rec_src
    , rec_src
    , bkcc
from historized_consumer_price_base_winn