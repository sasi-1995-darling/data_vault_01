with cte_gross_price_base_winn as (
/*filter shipment data for Moen_Ferguson sales w/ valid qty & rev, calc gross price, join with fiscal cal to get fiscal period
where USFS ties to moen_ferguson sales and ROHS ties to HoFR_ferguson sales*/
    select
        pbs.base_material as base_material_bk
        , pbs.base_material_id as base_material_key
        , pbs.key_account_number
        , pbs.sales_org
        , pbs.channel
        , pbs.source
        , 'PB_SHIPMENT' as pb_rec_src
        , pdf.fiscal_445_cal_month_yyyymm
        , pdf.fiscal_445_cal_year
        , (pbs.revenue_dollars / pbs.invoiced_qty) as gross_price
    from {{ ref('pb_shipment') }} as pbs
        left join {{ ref('pit_date_fiscal_445') }} as pdf
            on pbs.posted_datekey = pdf.date_bk
    where pbs.source = 'MOEN'
        and pbs.shipment_type = 'SAL'
        and pbs.key_account_number = '101' --Ferguson key acc#
        and pbs.sales_org in ('USFS', 'ROHS')
        and pbs.key_account_number is not null
        and pdf.fiscal_445_cal_year >= 2019
        and coalesce(pbs.invoiced_qty, 0) > 0
        and coalesce(pbs.revenue_dollars, 0) > 0
)

, cte_pb_competitive_product_winn as (/*get valid model and competitive product keys for winn*/
    select
        retailer_hk
        , competitive_product_bk
        , model
        , bkcc
    from {{ ref('pb_competitive_product') }}
    where sat_rec_src = 'US.PROFITERO_WINN.PRODUCTS'
        and model is not null
)

, cte_item_base_material_winn as (  /*get unique item and base material for winn; org/plant na*/
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
        , cp.bkcc
    from cte_pb_competitive_product_winn as cp
        inner join cte_item_base_material_winn as bm
            on cp.model = bm.item_number
)

, cte_consumer_price_base_winn as (
/*get valid winn profitero price from build.com for mapped competitive product base material across fiscal period for >=2019*/
    select
        pbm.base_material_key
        , pbm.base_material as base_material_bk
        , spcp.date
        , pdf.fiscal_445_cal_year
        , pdf.fiscal_445_cal_month_yyyymm
        , spcp.retailer_bk
        , spcp.retailer_key
        , spcp.sat_rec_src as rec_src
        , spcp.bkcc
        , spcp.regular_price
    from {{ ref('stg_pricing_competitive_profitero') }} as spcp
        inner join cte_product_base_material_winn as pbm
            on spcp.retailer_key = pbm.retailer_key
                and spcp.product_id = pbm.product_id
        left join {{ ref('pit_date_fiscal_445') }} as pdf
            on spcp.date = pdf.date
    where spcp.regular_price is not null
        and spcp.sat_rec_src = 'US.PROFITERO_WINN.PRICING_AVAILABILITY_HISTORY'
        and spcp.retailer_bk = 'build.com [build]'
        and pdf.fiscal_445_cal_year >= 2019
)

, cte_avg_markup_fiscal_period_winn as (
    /*calc avg markup rate for key acc, sales org, retailer, etc. across all products and fiscal period*/
    select
        gp.fiscal_445_cal_year
        , gp.fiscal_445_cal_month_yyyymm
        , gp.key_account_number
        , gp.sales_org
        , gp.channel
        , cpb.retailer_bk
        , cpb.retailer_key
        , avg((cpb.regular_price / gp.gross_price)) as avg_consumer_markup_rate_fiscal_period
    from cte_gross_price_base_winn as gp
        inner join cte_consumer_price_base_winn as cpb
            on gp.fiscal_445_cal_year = cpb.fiscal_445_cal_year
                and gp.fiscal_445_cal_month_yyyymm = cpb.fiscal_445_cal_month_yyyymm
                and gp.base_material_key = cpb.base_material_key
    group by all
)

, cte_avg_markup_fiscal_year_winn as (
    /*calc avg markup rate for key acc, sales org, retailer, etc. across all products and fiscal year*/
    select
        gp.fiscal_445_cal_year
        , gp.key_account_number
        , gp.sales_org
        , gp.channel
        , cpb.retailer_bk
        , cpb.retailer_key
        , avg((cpb.regular_price / gp.gross_price)) as avg_consumer_markup_rate_fiscal_year
    from cte_gross_price_base_winn as gp
        inner join cte_consumer_price_base_winn as cpb
            on gp.fiscal_445_cal_year = cpb.fiscal_445_cal_year
                and gp.base_material_key = cpb.base_material_key
    group by all
)


, cte_avg_markup_all_time_winn as (
    /*calc avg markup rate for key acc, sales org, retailer, etc. across all products for all time*/
    select
        gp.key_account_number
        , gp.sales_org
        , gp.channel
        , cpb.retailer_bk
        , cpb.retailer_key
        , avg((cpb.regular_price / gp.gross_price)) as avg_consumer_markup_rate_all_time
    from cte_gross_price_base_winn as gp
        inner join cte_consumer_price_base_winn as cpb
            on gp.base_material_key = cpb.base_material_key
    group by all
)

, cte_fiscal_445_calendar_periods as (/*get fiscal periods from 2019 to date*/
    select distinct
        fiscal_445_cal_month_yyyymm
        , fiscal_445_cal_year
    from {{ ref('pit_date_fiscal_445') }}
    where fiscal_445_cal_year >= 2019
        and date <= current_date()
)

, cte_key_account_retailer_winn as (
    /*unique combination of key acc, retailer, etc for moen_ferguson sales across all products*/
    select distinct
        gp.key_account_number
        , gp.sales_org
        , gp.channel
        , cpb.retailer_bk
        , cpb.retailer_key
        , cpb.rec_src
        , cpb.bkcc
    from cte_gross_price_base_winn as gp
        inner join cte_consumer_price_base_winn as cpb
            on gp.base_material_key = cpb.base_material_key
)

, cte_key_account_retailer_fiscal_calendar_base_winn as (
    /*all possible combinations of key acc, retailer, etc. and fiscal periods*/
    select
        fiscal_445_cal_month_yyyymm
        , fiscal_445_cal_year
        , key_account_number
        , sales_org
        , channel
        , retailer_bk
        , retailer_key
        , rec_src
        , bkcc
    from cte_fiscal_445_calendar_periods
        cross join cte_key_account_retailer_winn
)

, cte_avg_monthly_consumer_markup as (
/*get avg markup rate for fiscal period, if not available fall back to fiscal year, if still not avalable fall back to all time avg*/
    select distinct
        c.fiscal_445_cal_month_yyyymm::integer as fiscal_445_cal_month__date_yyyymm
        , c.fiscal_445_cal_year::integer as fiscal_445_cal_year
        , c.key_account_number
        , c.sales_org
        , c.channel
        , c.retailer_bk
        , c.retailer_key
        , 'PB_AVG_GROSS_TO_CONSUMER_MARKUP_RATE_MONTHLY' as pb_rec_src
        , c.rec_src
        , c.bkcc
        , round(
            coalesce(
                fp.avg_consumer_markup_rate_fiscal_period
                , fy.avg_consumer_markup_rate_fiscal_year
                , ata.avg_consumer_markup_rate_all_time
            )::float
            , 2
        ) as avg_consumer_markup_rate
    from cte_key_account_retailer_fiscal_calendar_base_winn as c
        left join cte_avg_markup_fiscal_period_winn as fp
            on c.fiscal_445_cal_month_yyyymm = fp.fiscal_445_cal_month_yyyymm
                and c.key_account_number = fp.key_account_number
                and c.sales_org = fp.sales_org
                and c.channel = fp.channel
                and c.retailer_key = fp.retailer_key
        left join cte_avg_markup_fiscal_year_winn as fy
            on c.fiscal_445_cal_year = fy.fiscal_445_cal_year
                and c.key_account_number = fy.key_account_number
                and c.sales_org = fy.sales_org
                and c.channel = fy.channel
                and c.retailer_key = fy.retailer_key
        left join cte_avg_markup_all_time_winn as ata
            on c.key_account_number = ata.key_account_number
                and c.sales_org = ata.sales_org
                and c.channel = ata.channel
                and c.retailer_key = ata.retailer_key
)

select
    random() as seq_id
    , current_date as snapshotdate
    , convert_timezone('UTC', current_timestamp) as pb_load_dts
    , fiscal_445_cal_month__date_yyyymm
    , fiscal_445_cal_year
    , key_account_number
    , sales_org
    , channel
    , avg_consumer_markup_rate
    , retailer_bk
    , retailer_key
    , pb_rec_src
    , rec_src
    , bkcc
from cte_avg_monthly_consumer_markup