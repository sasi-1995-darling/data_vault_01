with cte_gross_price_base as (
/*filter shipment data for Moen sales w/ valid qty & rev, calc gross price, join with fiscal cal to get fiscal period*/
    select
        pbs.base_material
        , pbs.base_material_id as base_material_key
        , pbs.key_account_number
        , pbs.channel
        , pbs.sales_org
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
        and nullif(pbs.key_account_number,'') is not null
        and pdf.fiscal_445_cal_year >= 2019
        and coalesce(pbs.invoiced_qty, 0) > 0
        and coalesce(pbs.revenue_dollars, 0) > 0
)

, fiscal_period_avg_gross_price as (/*calc average gross price for base material, key acc etc across fiscal period*/
    select
        fiscal_445_cal_year
        , fiscal_445_cal_month_yyyymm
        , key_account_number
        , channel
        , sales_org
        , pb_rec_src
        , source
        , base_material
        , base_material_key
        , avg(gross_price) as avg_fiscal_period_gross_price
    from cte_gross_price_base
    group by all
)

, fiscal_year_avg_gross_price as (/*calc average gross price for base material, key acc etc across fiscal year*/
    select
        fiscal_445_cal_year
        , key_account_number
        , channel
        , sales_org
        , pb_rec_src
        , source
        , base_material
        , base_material_key
        , avg(gross_price) as avg_fiscal_year_gross_price
    from cte_gross_price_base
    group by all
)

, all_time_avg_gross_price as (/*calc average gross price for base material, key acc etc across all time*/
    select
        key_account_number
        , channel
        , sales_org
        , pb_rec_src
        , source
        , base_material
        , base_material_key
        , avg(gross_price) as avg_all_time_gross_price
    from cte_gross_price_base
    group by all
)

, cte_base_materials as (/*unique combination of base material, key acc, channel, sales org, etc.*/
    select distinct
        base_material
        , base_material_key
        , key_account_number
        , channel
        , sales_org
        , pb_rec_src
        , source
    from cte_gross_price_base
)

, cte_fiscal_445_calendar_periods as (/*get fiscal periods from 2019 to date*/
    select distinct
        fiscal_445_cal_month_yyyymm
        , fiscal_445_cal_year
    from {{ ref('pit_date_fiscal_445') }}
    where fiscal_445_cal_year >= 2019
        and date <= current_date()
)

, cte_base_material_fiscal_periods_base as (/*all possible combinations of base material and fiscal period*/
    select
        base_material
        , base_material_key
        , key_account_number
        , channel
        , sales_org
        , pb_rec_src
        , source
        , fiscal_445_cal_month_yyyymm
        , fiscal_445_cal_year
    from cte_base_materials
        cross join cte_fiscal_445_calendar_periods
)

, historized_gross_price_winn_base as (
/*get avg gross price for fiscal period, if not available fall back to fiscal year, if still not avalable fall back to all time avg*/
    select
        b.base_material as base_material_bk
        , b.base_material_key
        , b.fiscal_445_cal_month_yyyymm::integer as fiscal_445_cal_month__date_yyyymm
        , b.fiscal_445_cal_year::integer as fiscal_445_cal_year
        , b.key_account_number
        , b.channel
        , b.sales_org
        , b.pb_rec_src
        , b.source
        , round(
            coalesce(
                fp.avg_fiscal_period_gross_price, fy.avg_fiscal_year_gross_price, ata.avg_all_time_gross_price
            )::float
            , 2
        ) as avg_gross_price
    from cte_base_material_fiscal_periods_base as b
        left join fiscal_period_avg_gross_price as fp
            on b.base_material_key = fp.base_material_key
                and b.key_account_number = fp.key_account_number
                and b.channel = fp.channel
                and b.sales_org = fp.sales_org
                and b.source = fp.source
                and b.fiscal_445_cal_month_yyyymm = fp.fiscal_445_cal_month_yyyymm
        left join fiscal_year_avg_gross_price as fy
            on b.base_material_key = fy.base_material_key
                and b.key_account_number = fy.key_account_number
                and b.channel = fy.channel
                and b.sales_org = fy.sales_org
                and b.source = fy.source
                and b.fiscal_445_cal_year = fy.fiscal_445_cal_year
        left join all_time_avg_gross_price as ata
            on b.base_material_key = ata.base_material_key
                and b.key_account_number = ata.key_account_number
                and b.channel = ata.channel
                and b.sales_org = ata.sales_org
                and b.source = ata.source
)

select
    random() as seq_id
    , current_date as snapshotdate
    , convert_timezone('UTC', current_timestamp) as pb_load_dts
    , base_material_bk
    , base_material_key
    , fiscal_445_cal_month__date_yyyymm
    , fiscal_445_cal_year
    , key_account_number
    , channel
    , sales_org
    , avg_gross_price
    , pb_rec_src
    , source
from historized_gross_price_winn_base
