"""
build_shipments_line_item.py — Build shipments_line_item.yml for FACT only.

The HUB, SAT, and PB layers already exist as the COPA MDP pipeline:
  - RAW_VAULT.HUB_COPA          (258M rows)
  - RAW_VAULT.LNK_COPA_SALES    (258M rows)
  - RAW_VAULT.LSAT_COPA_SALES__WINN_SAP (80M rows)
  - BUS_VAULT.PB_COPA           (258M rows, 204 columns)

This script generates ONLY the FACT_SHIPMENTS_LINE_ITEM model, which:
  1. Sources from PB_COPA (existing, already populated)
  2. Selects ~42 consumer columns (dim keys + GTN waterfall measures)
  3. Renames VV fields to business-friendly names for AtScale
  4. Joins to DIM_ITEM_FBIN and DIM_DATE_FISCAL_445

Usage (from repo root):
    python scripts/configs/build_shipments_line_item.py
    python scripts/generate_tech_spec.py --config scripts/configs/shipments_line_item.yml --outdir output/mappings/
    python src/main.py --rootdir output --loglevel INFO
"""
import yaml, pathlib


def col(alias, src, dtype, staging=None, comment='', pk=None, rel=None, manual=None):
    staging = staging or src
    entry = {
        'source_table': alias,
        'source_column': src,
        'datatype': dtype,
        'staging_column_name': staging,
        'staging_datatype': dtype,
    }
    if comment:
        entry['mapping_notes'] = comment
    if pk:
        entry['pk'] = pk
    if rel:
        entry['relationship'] = rel
    if manual:
        entry['manual_logic'] = manual
    return entry


# ── FACT columns — sourced from PB_COPA (actual column names) ────────────────
# PB_COPA uses: LNK_COPA_SALES_HK, CUSTOMER, PRODUCT_NUMBER, WERKS,
# POSTING_DATE__YYYYMMDD, FISCAL_YEAR__YYYY, FISCAL_MONTH__YYYYMM,
# RECORD_TYPE, DEAL_TYPE, BILLING_TYPE, etc.
# VV fields keep raw names: VVGRS, VVNET, VVCST, etc.
fact_columns = [
    # Primary key
    col('PB', 'LNK_COPA_SALES_HK', 'BINARY', pk='PK: LNK_COPA_SALES_HK'),
    # Dimension keys (using PB_COPA's actual column names)
    col('PB', 'CUSTOMER', 'TEXT', comment='Customer number — join to DIM_CUSTOMER'),
    col('PB', 'PRODUCT_NUMBER', 'TEXT', comment='Material number — join to DIM_ITEM_FBIN'),
    col('PB', 'WERKS', 'TEXT', comment='Plant'),
    col('PB', 'SALES_ORGANIZATION', 'TEXT'),
    col('PB', 'DISTRIBUTION_CHANNEL', 'TEXT'),
    col('PB', 'POSTING_DATE__YYYYMMDD', 'NUMBER', comment='Posting date YYYYMMDD — join to DIM_DATE'),
    col('PB', 'FISCAL_YEAR__YYYY', 'NUMBER'),
    col('PB', 'FISCAL_MONTH__YYYYMM', 'NUMBER'),
    col('PB', 'RECORD_TYPE', 'TEXT', comment='F=billing, C=settlement — filter criterion'),
    col('PB', 'DEAL_TYPE', 'TEXT', comment='Used in FI_RULES reclassification'),
    col('PB', 'WWRSN', 'TEXT', comment='Deal Type / Reason Code — used in FI_RULES'),
    col('PB', 'BILLING_TYPE', 'TEXT'),
    col('PB', 'ITEM_CATEGORY', 'TEXT'),
    col('PB', 'ORDER_REASON', 'TEXT'),
    col('PB', 'COMPANY_CODE', 'TEXT'),
    col('PB', 'PRCTR', 'TEXT', comment='Profit Center'),
    # GTN waterfall measures — VV fields renamed to business-friendly names
    col('PB', 'VVQTY', 'NUMBER', 'INVOICED_QTY', comment='Quantity'),
    col('PB', 'VVGRS', 'NUMBER', 'GR_SALES_BEFORE_INCENTIVES', comment='Gross Sales'),
    col('PB', 'VVNET', 'NUMBER', 'NET_SALES', comment='Net Sales'),
    col('PB', 'VVCST', 'NUMBER', 'STANDARD_COST', comment='Standard Cost (COGS)'),
    col('PB', 'VVGMG', 'NUMBER', 'GROSS_MARGIN', comment='Gross Margin'),
    col('PB', 'VVRST', 'NUMBER', 'RETURNS', comment='Returns'),
    col('PB', 'VVTRC', 'NUMBER', 'REVENUE_DOLLARS', comment='Trade Revenue / Gross Billing'),
    col('PB', 'VVFRA', 'NUMBER', 'FREIGHT', comment='Freight Allowance'),
    col('PB', 'VVACL', 'NUMBER', 'ACCRUALS', comment='Accrued Returns and Allowances'),
    col('PB', 'VVACD', 'NUMBER', 'POLICY_INCENTIVES', comment='Advertising Credit Deductions'),
    col('PB', 'VVCBA', 'NUMBER', 'CO_OP_ADV', comment='Co-op/Business Advertising'),
    col('PB', 'VVPRD', 'NUMBER', 'PRICE_PROMOS', comment='Price Reduction/Discount'),
    col('PB', 'VVVLR', 'NUMBER', 'REBATED_CJQ', comment='Volume Rebate'),
    col('PB', 'VVBLD', 'NUMBER', 'BUILDER_DEVELOPER', comment='Builder/Developer'),
    col('PB', 'VVBON', 'NUMBER', 'OTHER_FIXED_REBATES', comment='Bonus'),
    col('PB', 'VVCRL', 'NUMBER', 'CASH_DISCOUNTS', comment='Credit/Loss'),
    col('PB', 'VVMWP', 'NUMBER', 'MARKDOWNS', comment='Markdown/Writedown Provision'),
    col('PB', 'VVSHW', 'NUMBER', 'CV_SHOWROOM', comment='Showroom'),
    col('PB', 'VVSPD', 'NUMBER', 'SPECIAL_DEDUCTIONS', comment='Special Deductions'),
    col('PB', 'VVVBR', 'NUMBER', 'CV_VOLUME', comment='Volume-Based Rebate'),
    col('PB', 'VVPRV', 'NUMBER', 'PRICE_VARIANCE', comment='Price Variance'),
    col('PB', 'VVSSA', 'NUMBER', 'VARIABLE_SELLING', comment='Sales/Service Allowance'),
    col('PB', 'VVSTS', 'NUMBER', 'VARIABLE_DISTRIBUTION', comment='Stock Transfer Sales'),
    col('PB', 'VVPRO', 'NUMBER', 'PROMOTIONS', comment='Promotions'),
    col('PB', 'VVSBD', 'NUMBER', 'SALES_BUDGET_DEDUCTIONS', comment='Sales Budget Deductions'),
    col('PB', 'VVDFR', 'NUMBER', 'CF_CASHFLOW', comment='Deferred Revenue'),
    # DIM joins
    col('DIM_ITEM', 'ITEM_HK', 'BINARY', rel='DIM_ITEM_FBIN.ITEM_HK'),
    col('DIM_DATE', 'DATE_HK', 'BINARY', rel='DIM_DATE_FISCAL_445.DATE_HK'),
]


# ── Assemble config ───────────────────────────────────────────────────────────
config = {
    'filename': 'Unified_Shipments_Line_Item_Design_Spec_RV',
    'models': [
        {
            'layer': 'FACT',
            'short_name': 'SHIP LI',
            'derived_name': 'fact_shipments_line_item',
            'sources': [
                {
                    'source_schema': 'BUS_VAULT',
                    'source_table': 'pb_copa',
                    'alias': 'PB',
                    'source_layer_filter': '',
                    'filter_conditions': '',
                    'final_layer_filter': '',
                    'parent_join_number': 1,
                    'parent_table_join': '',
                    'child_table_join': '',
                    'join_type': '',
                    'target_schema': 'BUS_VAULT',
                },
                {
                    'source_schema': 'BUS_VAULT',
                    'source_table': 'dim_item_fbin',
                    'alias': 'DIM_ITEM',
                    'source_layer_filter': '',
                    'filter_conditions': '',
                    'final_layer_filter': '',
                    'parent_join_number': 2,
                    'parent_table_join': 'PB.PRODUCT_NUMBER',
                    'child_table_join': 'DIM_ITEM.PRODUCT_NUMBER',
                    'join_type': 'LEFT JOIN',
                    'target_schema': 'BUS_VAULT',
                },
                {
                    'source_schema': 'BUS_VAULT',
                    'source_table': 'dim_date_fiscal_445',
                    'alias': 'DIM_DATE',
                    'source_layer_filter': '',
                    'filter_conditions': '',
                    'final_layer_filter': '',
                    'parent_join_number': 3,
                    'parent_table_join': 'PB.POSTING_DATE__YYYYMMDD',
                    'child_table_join': 'DIM_DATE.DATE_KEY',
                    'join_type': 'LEFT JOIN',
                    'target_schema': 'BUS_VAULT',
                },
            ],
            'columns': fact_columns,
        },
    ],
}


# ── Write YAML ────────────────────────────────────────────────────────────────
out = pathlib.Path(__file__).with_name('shipments_line_item.yml')
with open(out, 'w', encoding='utf-8') as f:
    yaml.dump(config, f, default_flow_style=False, sort_keys=False, width=120, allow_unicode=True)

print(f"✓ Wrote {out}  ({sum(len(m['columns']) for m in config['models'])} total columns across {len(config['models'])} models)")
