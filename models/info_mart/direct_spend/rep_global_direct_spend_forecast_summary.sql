---- SRC LAYER ----
{{ config(
    description='Enhanced spend forecasting model for LARSON OPCO with 18-month rolling forecast',
    tags=['forecast', 'spend', 'larson', 'EMTEK & SCHAUB']
) }}

-- Configuration parameters
{% set forecast_months = 18 %}
{% set historical_days = 180 %}

with
src_spend_summary as (
    select
         bkcc
        , business_unit
        , cal_month
        , cal_year
        , category_cd
        , category_desc
        , category_leader_name
        , country_of_origin
        , director_name
        , document_type
        , fbin_category_i
        , fbin_category_ii
        , fbin_category_iii
        , item_bk
        , item_hk
        , opco
        , opco_item
        , payment_terms
        , plant_bk
        , plant_hk
        , posting_date_key
        , receipt_qty
        , receipt_spend
        , rec_src
        , spend_usd
        , supplier_name_child
        , supplier_name_parent
        , supplier_number_child
        , supplier_number_parent
        , uom
    from {{ ref('fact_global_direct_spend_daily_summary') }}
    where opco in ('LARSON', 'EMTEK & SCHAUB')  
)

-- Item dimension data
, src_item_dim as (
    select
        item_id
        , item_title
    from {{ ref('dim_item_fbin') }}
)

-- Fiscal 445 dimension data
, src_dim_445 as (
   SELECT DATE_BK, FISCAL_445_CAL_MONTH, FISCAL_445_CAL_YEAR 
   FROM {{ ref('dim_date_fiscal_445') }} as SRC
)

-- Most recent price for each item/supplier/plant combination
, item_price_recent as (
    select
        item_bk as material
        , supplier_number_parent as supplier_parent
        , plant_bk as plant
        , spend_usd
        , receipt_qty
        , (spend_usd / NULLIF(receipt_qty, 0)) as price
        , TO_DATE(TO_CHAR(posting_date_key), 'YYYYMMDD') as posting_date
    from src_spend_summary
    where receipt_qty > 0  -- Avoid division by zero
    qualify ROW_NUMBER() over (
        partition by item_bk, supplier_number_parent, plant_bk
        order by posting_date_key desc
    ) = 1
)

-- Historical spend data for forecasting (last 180 days)
, spend_data_historical as (
    select
        spend.*
        , item.item_title
    from src_spend_summary as spend
        left join src_item_dim as item
            on spend.item_hk = item.item_id
    where TO_DATE(TO_CHAR(posting_date_key), 'YYYYMMDD') >= CURRENT_DATE - interval '{{ historical_days }} DAY'
)

-- Generate forecast periods (0 = current month, 1-17 = future months)
, forecast_periods as (
    select
        forecast_month_offset
        , case
            when forecast_month_offset = 0 then CURRENT_DATE
            else DATE_TRUNC('MONTH', DATEADD(month, forecast_month_offset, CURRENT_DATE))
        end as forecast_period_start
        , case
            when forecast_month_offset = 0 then LAST_DAY(CURRENT_DATE)
            else LAST_DAY(DATE_TRUNC('MONTH', DATEADD(month, forecast_month_offset, CURRENT_DATE)))
        end as forecast_period_end
    from (
        select ROW_NUMBER() over (order by null) - 1 as forecast_month_offset
        from TABLE(GENERATOR(ROWCOUNT => {{ forecast_months }}))
    )
)

-- Calculate forecast metrics for each period
, forecast_calculations as (
    select
        fp.forecast_month_offset
        , fp.forecast_period_start
        , fp.forecast_period_end
        , YEAR(fp.forecast_period_start) as cal_year
        , MONTH(fp.forecast_period_start) as cal_month
        , TO_VARCHAR(fp.forecast_period_start, 'YYYYMMDD')::INTEGER as forecast_date_key
        , CONCAT(YEAR(fp.forecast_period_start), '|', MONTH(fp.forecast_period_start)) as year_month
        -- Calculate days in forecast period
        , case
            when fp.forecast_month_offset = 0
                then DATEDIFF(day, CURRENT_DATE, fp.forecast_period_end) + 1
            else DATEDIFF(day, fp.forecast_period_start, fp.forecast_period_end) + 1
        end as days_in_period
    from forecast_periods as fp
)

-- Final forecast output
select
    -- Supplier Information
    sp.supplier_number_parent
    , sp.supplier_name_parent
    , sp.supplier_number_child
    , sp.supplier_name_child
    , sp.payment_terms
    , sp.document_type

    -- Item Information  
    , sp.item_bk as item
    , sp.item_title as item_description
    , sp.country_of_origin

    -- Time Dimensions
    , fc.cal_year
    , fc.cal_month
    , fc.forecast_date_key
    , fc.forecast_date_key as forecast_date__yyyymmdd
    , fc.year_month
	, dim_445.FISCAL_445_CAL_MONTH
	, dim_445.FISCAL_445_CAL_YEAR 

    -- Organizational Dimensions
    , sp.business_unit
    , sp.opco
    , sp.plant_bk as plant
    , sp.opco_item

    -- Forecast Calculations
    , (
        (SUM(sp.receipt_qty) / {{ historical_days }})
        * fc.days_in_period
        * COALESCE(ipr.price, 0)
    ) as spend

    , (
        (SUM(sp.receipt_qty) / {{ historical_days }}) * fc.days_in_period
    ) as volume

    -- Category and Management Information
    , sp.director_name
    , sp.category_leader_name
    , sp.fbin_category_i
    , sp.fbin_category_ii
    , sp.fbin_category_iii
    , sp.uom
    , COALESCE(ipr.price, 0) as price
    , sp.category_cd
    , sp.category_desc

    -- Technical Keys
    , sp.item_hk
    , sp.plant_hk
    , sp.bkcc
    , sp.rec_src

    -- Metadata
    , fc.forecast_month_offset
    , CURRENT_TIMESTAMP as forecast_generated_at
    , '{{ historical_days }}-day rolling average' as forecast_method

from spend_data_historical as sp
    cross join forecast_calculations as fc
    left join item_price_recent as ipr
        on sp.item_bk = ipr.material
            and sp.supplier_number_parent = ipr.supplier_parent
            and sp.plant_bk = ipr.plant
	left join src_dim_445 as dim_445
			on fc.forecast_date_key = dim_445.DATE_BK

-- Only include combinations where we have price data for future months
where (fc.forecast_month_offset = 0 or ipr.price is not null)

group by
    sp.supplier_number_parent
    , sp.supplier_name_parent
    , sp.supplier_number_child
    , sp.supplier_name_child
    , sp.payment_terms
    , sp.document_type
    -- Item Information
    , sp.item_bk
    , sp.item_title
    , sp.country_of_origin
    -- Time Dimensions  
    , fc.cal_year
    , fc.cal_month
    , fc.forecast_date_key
    , fc.year_month
    , fc.days_in_period
    , dim_445.FISCAL_445_CAL_MONTH
	, dim_445.FISCAL_445_CAL_YEAR 
    -- Organizational Dimensions
    , sp.business_unit
    , sp.opco
    , sp.plant_bk
    , sp.opco_item
    -- Category and Management Information
    , sp.director_name
    , sp.category_leader_name
    , sp.fbin_category_i
    , sp.fbin_category_ii
    , sp.fbin_category_iii
    , sp.uom
    , sp.category_cd
    , sp.category_desc
    -- Technical Keys
    , sp.item_hk
    , sp.plant_hk
    , sp.bkcc
    , sp.rec_src
    -- Price and Metadata
    , ipr.price
    , fc.forecast_month_offset
order by
    sp.supplier_number_parent
    , sp.item_bk
    , sp.plant_bk
    , fc.forecast_month_offset
 