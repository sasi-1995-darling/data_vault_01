{{
    config(
        tags=['pit_bridge', 'sku_rationalization']
    )
}}

-- ============================================================
-- SKU Rationalization Analysis — PIT Bridge
-- Purpose: Analyze SKU performance and rationalization segments for Moen items
-- ============================================================

---- SRC LAYER ----
WITH
SRC_FY             as ( SELECT 2025 as current_year, 2024 as previous_year, 2023 as base_year )

, SRC_PBI          as ( SELECT * FROM {{ ref('pb_item') }} as SRC WHERE bkcc = 'Hiding_Tiger' )
/*
SRC_PBI            as ( SELECT * FROM bus_vault.pb_item WHERE bkcc = 'Hiding_Tiger' )
*/

, SRC_FSF          as ( SELECT * FROM {{ ref('pb_shipment') }} as SRC WHERE bkcc = 'Hiding_Tiger' )
/*
SRC_FSF            as ( SELECT * FROM bus_vault.pb_shipment WHERE bkcc = 'Hiding_Tiger' )
*/

, SRC_FSP          as ( SELECT * FROM {{ ref('fact_shipment_profitability') }} as SRC WHERE bkcc = 'Hiding_Tiger' )

---- LOGIC LAYER ----

, LOGIC_FY as (
    SELECT
        current_year
      , previous_year
      , base_year
    FROM SRC_FY
)

, LOGIC_PBI as (
    -- Compute deletion_segment per item using product attribute rules
    SELECT
        item_id                                                      as                                              item_hk                              -- pb_item exposes the HK under the alias ITEM_ID
      , item_number
      , base_material
      , item_product_segment                                         as                                       product_segment
      , item_reporting_category                                      as                                         product_group
      , item_sub_class                                               as                                              platform
      , concat_ws('|', item_sub_class, item_finish, item_price_band, item_style)                            as                  node
      , item_style                                                   as                                         product_style
      , case
            when item_type_code in ('CF', 'CFG')                                                                    then 'CFG'

            -- Kitchen
            when item_reporting_category in ('KITCHEN FAUCET', 'KITCHEN ADJACENCIES', 'KITCHEN SINKS')
                 and item_product_segment <> 'COMMERCIAL PRODUCTS'
                 and item_room_area_detail = 'KITCHEN'                                                              then 'Kitchen'

            -- Accessories: Bath Adjacencies reporting category
            when item_reporting_category = 'BATH ADJACENCIES'
                 and item_product_segment <> 'COMMERCIAL PRODUCTS'                                                  then 'Accessories'

            -- Bath: Lav Faucets reporting category
            when item_reporting_category = 'BATH LAV FAUCETS'
                 and item_product_segment <> 'COMMERCIAL PRODUCTS'                                                  then 'Bath'

            -- Disposals: Garbage Disposal reporting category
            when item_reporting_category = 'GARBAGE DISPOSAL'
                 and item_product_segment <> 'COMMERCIAL PRODUCTS'                                                  then 'Disposals'

            -- Showering: Showering & Bathing reporting category
            when item_reporting_category = 'SHOWERING & BATHING'
                 and item_product_segment <> 'COMMERCIAL PRODUCTS'                                                  then 'Showering'

            -- Sinks (includes commercial sinks)
            when item_reporting_category = 'KITCHEN SINKS'                                                          then 'Sinks'

            -- VCP - Commercial: Valves price type AND Commercial segment
            when item_sub_category = 'VALVES'
                 and item_product_segment = 'COMMERCIAL PRODUCTS'
                 and item_reporting_category not in ('KITCHEN SINKS', 'DISPOSALS')                                  then 'VCP - Commercial'

            -- VCP - Parts: Replacement Parts reporting category
            when item_reporting_category = 'REPLACEMENT PARTS'
                 and item_product_segment <> 'COMMERCIAL PRODUCTS'
                 and item_reporting_category not in ('KITCHEN SINKS', 'DISPOSALS')                                  then 'VCP - Parts'

            -- VCP - Valves: Valves price type, non-commercial
            when item_sub_category = 'VALVES'
                 and item_product_segment <> 'COMMERCIAL PRODUCTS'
                 and item_sub_class <> 'BATH COMMERCIAL PRODUCTS'
                 and item_reporting_category not in ('KITCHEN SINKS', 'DISPOSALS')                                  then 'VCP - Valves'

            else null                                                                                               -- SKU does not map to any defined segment
        end                                                          as                                      deletion_segment
      , item_finish
      , item_product_line as product_line
      , item_product_type as product_type
      , item_price_band as price_band
      , launch_date__yyyymmdd
      , year(TRY_TO_DATE(CAST(launch_date__yyyymmdd AS VARCHAR), 'YYYYMMDD')) as launch_date__yyyy
      , launch_date_source as launch_year_source
      , case
            when launch_date__yyyymmdd = 19000101 then null
            else datediff(YEAR, TRY_TO_DATE(CAST(launch_date__yyyymmdd AS VARCHAR), 'YYYYMMDD'), current_date()::date)
        end                                                          as                                         product_age_years
      , case when launch_date__yyyy >= 2023 then 'Y' else 'N' end as is_newer_product
      , d_chain_code as d_chain_status
      , brand
      , bkcc
      , rec_src
    FROM SRC_PBI
)

, LOGIC_FSF as (
    -- Aggregate fact to one row per base_material x fiscal window for Moen Americas sales
    SELECT
        f.base_material                                              as                                    base_material_number
      , sum(case when f.fiscal_year__yyyy = fy.base_year     then f.revenue_dollars else 0 end)            as          gs_base_yr_amt
      , sum(case when f.fiscal_year__yyyy = fy.current_year  then f.revenue_dollars else 0 end)            as       gs_current_yr_amt
      , sum(case when f.fiscal_year__yyyy = fy.previous_year then f.revenue_dollars else 0 end)            as         gs_prior_yr_amt
      , sum(case when f.fiscal_year__yyyy = fy.base_year     then f.sales_quantity  else 0 end)            as         units_base_yr_qty
      , sum(case when f.fiscal_year__yyyy = fy.current_year  then f.sales_quantity  else 0 end)            as      units_current_yr_qty
      , sum(case when f.fiscal_year__yyyy = fy.previous_year then f.sales_quantity  else 0 end)            as        units_prior_yr_qty
      , sum(case when f.fiscal_year__yyyy = fy.current_year and f.channel = 'RT' then f.revenue_dollars else 0 end) as  gs_current_yr_rt_amt
      , sum(case when f.fiscal_year__yyyy = fy.current_year and f.channel = 'WH' then f.revenue_dollars else 0 end) as  gs_current_yr_wh_amt
      , sum(case when f.fiscal_year__yyyy = fy.current_year and f.channel = 'EC' then f.revenue_dollars else 0 end) as  gs_current_yr_ec_amt
      , sum(case when f.fiscal_year__yyyy = fy.current_year and f.channel = 'DR' then f.revenue_dollars else 0 end) as  gs_current_yr_dr_amt
      , sum(coalesce(fsp.gross_sales, 0))                              as                                            gross_sales
      , sum(coalesce(fsp.net_sales, 0))                                as                                              net_sales
      , sum(coalesce(fsp.cogs, 0))                                     as                                                   cogs
    FROM SRC_FSF f
    LEFT JOIN SRC_FSP fsp
        ON f.shipment_id = fsp.shipment_id
    CROSS JOIN SRC_FY fy
    WHERE f.sales_org IN ('USFS', 'CANS', 'AMCS', 'MXFS', 'USIT')
      AND f.fiscal_year__yyyy BETWEEN fy.base_year AND fy.current_year
    GROUP BY f.base_material
)

---- RENAME LAYER ----

, RENAME_FY as (
    SELECT
        current_year
      , previous_year
      , base_year
    FROM LOGIC_FY
)

, RENAME_PBI as (
    SELECT
        item_hk
      , item_number
      , product_segment
      , product_group
      , platform
      , node
      , product_style
      , deletion_segment
      , item_finish
      , product_line
      , product_type
      , price_band
      , launch_date__yyyymmdd
      , launch_date__yyyy
      , launch_year_source
      , product_age_years
      , d_chain_status
      , is_newer_product
      , brand
      , bkcc
      , rec_src
    FROM LOGIC_PBI
)

, RENAME_FSF as (
    SELECT
        base_material_number
      , gs_base_yr_amt
      , gs_current_yr_amt
      , gs_prior_yr_amt
      , units_base_yr_qty
      , units_current_yr_qty
      , units_prior_yr_qty
      , gs_current_yr_rt_amt
      , gs_current_yr_wh_amt
      , gs_current_yr_ec_amt
      , gs_current_yr_dr_amt
      , gross_sales
      , net_sales
      , cogs
    FROM LOGIC_FSF
)

---- FILTER LAYER ----

, FILTER_FY as (
    SELECT *
    FROM RENAME_FY
)

, FILTER_PBI as (
    SELECT *
    FROM RENAME_PBI
    WHERE deletion_segment IS NOT NULL                                                                                  -- exclude SKUs with no segment match
)

, FILTER_FSF as (
    SELECT *
    FROM RENAME_FSF
)

---- JOIN LAYER ----

, JOIN_RESULT as (
    SELECT
        fy.current_year
      , fy.previous_year
      , fy.base_year
      , ir.item_hk
      , ir.item_number
      , ir.product_segment
      , ir.product_group
      , ir.platform
      , ir.node
      , ir.product_style
      , ir.deletion_segment
      , ir.item_finish
      , ir.product_line
      , ir.product_type
      , ir.price_band
      , ir.launch_date__yyyymmdd
      , ir.launch_date__yyyy
      , ir.launch_year_source
      , ir.product_age_years
      , ir.d_chain_status
      , ir.is_newer_product
      , ir.brand
      , ir.bkcc
      , ir.rec_src
      , coalesce(bs.base_material_number, ir.item_number)              as                                    base_material_number
      , coalesce(bs.gs_base_yr_amt, 0)                                as                                           gs_base_yr_amt
      , coalesce(bs.gs_current_yr_amt, 0)                             as                                        gs_current_yr_amt
      , coalesce(bs.gs_prior_yr_amt, 0)                               as                                          gs_prior_yr_amt
      , coalesce(bs.units_base_yr_qty, 0)                             as                                         units_base_yr_qty
      , coalesce(bs.units_current_yr_qty, 0)                          as                                      units_current_yr_qty
      , coalesce(bs.units_prior_yr_qty, 0)                            as                                        units_prior_yr_qty
      , coalesce(bs.gs_current_yr_rt_amt, 0)                          as                                     gs_current_yr_rt_amt
      , coalesce(bs.gs_current_yr_wh_amt, 0)                          as                                     gs_current_yr_wh_amt
      , coalesce(bs.gs_current_yr_ec_amt, 0)                          as                                     gs_current_yr_ec_amt
      , coalesce(bs.gs_current_yr_dr_amt, 0)                          as                                     gs_current_yr_dr_amt
      , coalesce(
            case
                when bs.gs_base_yr_amt > 0
                     and bs.gs_current_yr_amt / nullif(bs.gs_base_yr_amt, 0) > 0
                    then power((bs.gs_current_yr_amt / nullif(bs.gs_base_yr_amt, 0)), (1.0 / nullif(fy.current_year - fy.base_year, 0))) - 1
                else null
            end, 0
        )                                                          as                                              gs_3yr_cagr
      , coalesce(bs.gross_sales, 0)                                    as                                            gross_sales
      , coalesce(bs.net_sales, 0)                                      as                                              net_sales
      , coalesce(bs.cogs, 0)                                           as                                                   cogs
    FROM FILTER_FY fy
    CROSS JOIN FILTER_PBI ir
    LEFT JOIN FILTER_FSF bs
      ON ir.item_number = bs.base_material_number
)

---- CALCULATE LAYER ----

, CALCULATE_RESULT as (
SELECT
        current_year
      , previous_year
      , base_year
      , item_hk
      , item_number
      , product_segment
      , product_group
      , platform
      , node
      , product_style
      , deletion_segment
      , item_finish
      , product_line
      , product_type
      , price_band
      , launch_date__yyyymmdd
      , launch_date__yyyy
      , launch_year_source
      , product_age_years
      , d_chain_status
      , is_newer_product
      , gross_sales
      , net_sales
      , cogs
      , net_sales - cogs                                               as                               standard_margin_dollars
      , gross_sales - cogs                                             as                                product_margin_dollars
      , round(div0(net_sales - cogs, net_sales), 2)                   as                                     standard_margin
      , round(div0(gross_sales - cogs, cogs), 2)                      as                                       product_margin
      , brand
      , bkcc
      , rec_src
      , base_material_number
      , gs_base_yr_amt
      , gs_current_yr_amt
      , gs_prior_yr_amt
      , units_base_yr_qty
      , units_current_yr_qty
      , units_prior_yr_qty
      , gs_current_yr_rt_amt
      , gs_current_yr_wh_amt
      , gs_current_yr_ec_amt
      , gs_current_yr_dr_amt
      , gs_3yr_cagr
      , gs_current_yr_amt - gs_prior_yr_amt                           as                                        dollar_difference_amt
      , units_current_yr_qty - units_prior_yr_qty                     as                                         unit_difference_qty
      , round(div0(gs_current_yr_amt - gs_prior_yr_amt, gs_prior_yr_amt), 2) as                                yoy_growth_pct

      , percent_rank() over (
            partition by deletion_segment
            order by gs_current_yr_amt
        )                                                            as                                              pct_rank_pre

      -- node level inherits deletion_segment + product_segment + product_group
      , sum(gs_current_yr_amt) over (
            partition by deletion_segment, product_segment, product_group, node
            order by gs_current_yr_amt desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment, product_segment, product_group, node), 0)
                                                                     as                                              gs_cum_share_by_node

      , case
            when sum(gs_current_yr_amt) over (
                partition by deletion_segment, product_segment, product_group, node
                order by gs_current_yr_amt desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment, product_segment, product_group, node), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              gs_value_80_20_trend_tag_by_node

      , sum(units_current_yr_qty) over (
            partition by deletion_segment, product_segment, product_group, node
            order by units_current_yr_qty desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment, product_segment, product_group, node), 0)
                                                                     as                                              units_cum_share_by_node

      , case
            when sum(units_current_yr_qty) over (
                partition by deletion_segment, product_segment, product_group, node
                order by units_current_yr_qty desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment, product_segment, product_group, node), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              units_value_80_20_trend_tag_by_node

      , sum(gs_current_yr_amt) over (
            partition by deletion_segment
            order by gs_current_yr_amt desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment), 0)
                                                                     as                                              gs_cum_share

      , case
            when sum(gs_current_yr_amt) over (
                partition by deletion_segment
                order by gs_current_yr_amt desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              gs_value_80_20_trend_tag                                        -- partitioned by deletion_segment

      -- Cumulative Units share within deletion_segment
      , sum(units_current_yr_qty) over (
            partition by deletion_segment
            order by units_current_yr_qty desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment), 0)
                                                                     as                                              units_cum_share

      , case
            when sum(units_current_yr_qty) over (
                partition by deletion_segment
                order by units_current_yr_qty desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              units_value_80_20_trend_tag                                     -- partitioned by deletion_segment

      -- product_segment level inherits deletion_segment
      , sum(gs_current_yr_amt) over (
            partition by deletion_segment, product_segment
            order by gs_current_yr_amt desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment, product_segment), 0)
                                                                     as                                              gs_cum_share_by_product_segment

      , case
            when sum(gs_current_yr_amt) over (
                partition by deletion_segment, product_segment
                order by gs_current_yr_amt desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment, product_segment), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              gs_value_80_20_trend_tag_by_product_segment

      , sum(units_current_yr_qty) over (
            partition by deletion_segment, product_segment
            order by units_current_yr_qty desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment, product_segment), 0)
                                                                     as                                              units_cum_share_by_product_segment

      , case
            when sum(units_current_yr_qty) over (
                partition by deletion_segment, product_segment
                order by units_current_yr_qty desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment, product_segment), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              units_value_80_20_trend_tag_by_product_segment

      -- product_group level inherits deletion_segment + product_segment
      , sum(gs_current_yr_amt) over (
            partition by deletion_segment, product_segment, product_group
            order by gs_current_yr_amt desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment, product_segment, product_group), 0)
                                                                     as                                              gs_cum_share_by_product_group

      , case
            when sum(gs_current_yr_amt) over (
                partition by deletion_segment, product_segment, product_group
                order by gs_current_yr_amt desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment, product_segment, product_group), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              gs_value_80_20_trend_tag_by_product_group

      , sum(units_current_yr_qty) over (
            partition by deletion_segment, product_segment, product_group
            order by units_current_yr_qty desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment, product_segment, product_group), 0)
                                                                     as                                              units_cum_share_by_product_group

      , case
            when sum(units_current_yr_qty) over (
                partition by deletion_segment, product_segment, product_group
                order by units_current_yr_qty desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment, product_segment, product_group), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              units_value_80_20_trend_tag_by_product_group

      -- platform level inherits deletion_segment + product_segment + product_group
      , sum(gs_current_yr_amt) over (
            partition by deletion_segment, product_segment, product_group, platform
            order by gs_current_yr_amt desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment, product_segment, product_group, platform), 0)
                                                                     as                                              gs_cum_share_by_platform

      , case
            when sum(gs_current_yr_amt) over (
                partition by deletion_segment, product_segment, product_group, platform
                order by gs_current_yr_amt desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(gs_current_yr_amt) over (partition by deletion_segment, product_segment, product_group, platform), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              gs_value_80_20_trend_tag_by_platform

      , sum(units_current_yr_qty) over (
            partition by deletion_segment, product_segment, product_group, platform
            order by units_current_yr_qty desc, base_material_number
            rows between unbounded preceding and current row
        ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment, product_segment, product_group, platform), 0)
                                                                     as                                              units_cum_share_by_platform

      , case
            when sum(units_current_yr_qty) over (
                partition by deletion_segment, product_segment, product_group, platform
                order by units_current_yr_qty desc, base_material_number
                rows between unbounded preceding and current row
            ) / nullif(sum(units_current_yr_qty) over (partition by deletion_segment, product_segment, product_group, platform), 0) <= 0.8
                then 'Top 80%'
            else 'Bottom 20%'
        end
        || case
            when coalesce(gs_3yr_cagr, gs_current_yr_amt - gs_prior_yr_amt) > 0 then ' Increasing'
            else ' Decreasing'
        end                                                          as                                              units_value_80_20_trend_tag_by_platform
FROM JOIN_RESULT
)

---- ROUND LAYER ----

, ROUND_RESULT as (
    SELECT
        current_year
      , previous_year
      , base_year
      , item_hk
      , item_number
      , product_segment
      , product_group
      , platform
      , COALESCE(node, 'N/A')                                            as                                                    node
      , COALESCE(NULLIF(TRIM(product_style), ''), 'N/A')                  as                                             product_style
      , deletion_segment
      , item_finish
      , product_line
      , product_type
      , COALESCE(price_band, 'N/A')                                       as                                               price_band
      , launch_date__yyyymmdd
      , launch_date__yyyy
      , COALESCE(launch_year_source, 'N/A')                               as                                          launch_year_source
      , product_age_years
      , COALESCE(d_chain_status, 'N/A')                                   as                                            d_chain_status
      , is_newer_product
      , gross_sales
      , net_sales
      , cogs
      , standard_margin_dollars
      , product_margin_dollars
      , standard_margin
      , product_margin
      , COALESCE(brand, 'N/A')                                            as                                                   brand
      , bkcc
      , rec_src
      , base_material_number
      , round(gs_base_yr_amt, 2)                                       as                                           gs_base_yr_amt
      , round(gs_current_yr_amt, 2)                                    as                                        gs_current_yr_amt
      , round(gs_prior_yr_amt, 2)                                      as                                          gs_prior_yr_amt
      , units_base_yr_qty
      , units_current_yr_qty
      , units_prior_yr_qty
      , round(gs_current_yr_rt_amt, 2)                                 as                                     gs_current_yr_rt_amt
      , round(gs_current_yr_wh_amt, 2)                                 as                                     gs_current_yr_wh_amt
      , round(gs_current_yr_ec_amt, 2)                                 as                                     gs_current_yr_ec_amt
      , round(gs_current_yr_dr_amt, 2)                                 as                                     gs_current_yr_dr_amt
      , round(gs_3yr_cagr, 2)                                          as                                             gs_3yr_cagr
      , round(dollar_difference_amt, 2)                                    as                                        dollar_difference_amt
      , unit_difference_qty
      , yoy_growth_pct
      , round(pct_rank_pre, 2)                                         as                                            pct_rank_pre
      , COALESCE(round(gs_cum_share_by_node, 2), 0)                      as                                    gs_cum_share_by_node
      , gs_value_80_20_trend_tag_by_node
      , COALESCE(units_cum_share_by_node, 0)                             as                                 units_cum_share_by_node
      , units_value_80_20_trend_tag_by_node
      , COALESCE(round(gs_cum_share, 2), 0)                              as                                            gs_cum_share
      , gs_value_80_20_trend_tag
      , COALESCE(units_cum_share, 0)                                     as                                          units_cum_share
      , units_value_80_20_trend_tag
      , COALESCE(round(gs_cum_share_by_product_segment, 2), 0)           as                           gs_cum_share_by_product_segment
      , gs_value_80_20_trend_tag_by_product_segment
      , COALESCE(units_cum_share_by_product_segment, 0)                  as                        units_cum_share_by_product_segment
      , units_value_80_20_trend_tag_by_product_segment
      , COALESCE(round(gs_cum_share_by_product_group, 2), 0)             as                             gs_cum_share_by_product_group
      , gs_value_80_20_trend_tag_by_product_group
      , COALESCE(units_cum_share_by_product_group, 0)                    as                          units_cum_share_by_product_group
      , units_value_80_20_trend_tag_by_product_group
      , COALESCE(round(gs_cum_share_by_platform, 2), 0)                  as                                gs_cum_share_by_platform
      , gs_value_80_20_trend_tag_by_platform
      , COALESCE(units_cum_share_by_platform, 0)                         as                             units_cum_share_by_platform
      , units_value_80_20_trend_tag_by_platform
    FROM CALCULATE_RESULT
)

---- FINAL_SELECT LAYER ----
SELECT
    random() as seq_id
  , current_timestamp as snapshot_dts
  , item_hk
  , deletion_segment
  , product_segment
  , product_group
  , platform
  , node
  , product_style
  , item_number
  , base_material_number
  , gs_base_yr_amt
  , gs_current_yr_amt
  , gs_prior_yr_amt
  , units_base_yr_qty
  , units_current_yr_qty
  , units_prior_yr_qty
  , gs_current_yr_rt_amt
  , gs_current_yr_wh_amt
  , gs_current_yr_ec_amt
  , gs_current_yr_dr_amt
  , gs_3yr_cagr
  , dollar_difference_amt
  , unit_difference_qty
  , yoy_growth_pct
  , pct_rank_pre
  , gs_cum_share_by_node
  , gs_value_80_20_trend_tag_by_node
  , units_cum_share_by_node
  , units_value_80_20_trend_tag_by_node
  , gs_cum_share
  , gs_value_80_20_trend_tag
  , units_cum_share
  , units_value_80_20_trend_tag
  , gs_cum_share_by_product_segment
  , gs_value_80_20_trend_tag_by_product_segment
  , units_cum_share_by_product_segment
  , units_value_80_20_trend_tag_by_product_segment
  , gs_cum_share_by_product_group
  , gs_value_80_20_trend_tag_by_product_group
  , units_cum_share_by_product_group
  , units_value_80_20_trend_tag_by_product_group
  , gs_cum_share_by_platform
  , gs_value_80_20_trend_tag_by_platform
  , units_cum_share_by_platform
  , units_value_80_20_trend_tag_by_platform
  , item_finish
  , product_line
  , product_type
  , price_band
  , launch_date__yyyymmdd
  , launch_date__yyyy
  , launch_year_source
  , product_age_years
  , d_chain_status
  , is_newer_product
  , gross_sales
  , net_sales
  , cogs
  , standard_margin_dollars
  , product_margin_dollars
  , standard_margin
  , product_margin
  , brand
  , bkcc
  , rec_src
FROM ROUND_RESULT
