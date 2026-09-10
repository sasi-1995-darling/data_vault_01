import logging

logger = logging.getLogger(__name__)

def sheet2dict(sheet):
    logger.debug('FUNCTION: sheet2dict')
    logger.info(f'<<<< Processing {sheet}')

    fields = None
    for rownum, row in enumerate(sheet.iter_rows(values_only=True)):
        if rownum == 0:
            fields = row
            continue
        row = dict(zip(fields, row))

        yield row

def sheet2list(sheet):
    logger.debug('FUNCTION: sheet2list')
    for row in sheet.iter_rows(values_only=True):
        if not row or not any(row):
            continue
        yield row

def get_derived_names(wb):
    derived_names = {}
    index_sheet = wb['Index']
    
    for row_index, row in enumerate(index_sheet.iter_rows(min_row=2, values_only=True), start=2):
        if row[0] and isinstance(row[0], str):
            cell = index_sheet.cell(row=row_index, column=1)
            if cell.hyperlink:
                # Use location if available, fall back to target (openpyxl stores
                # internal links as target='#...' when location is not set)
                link_ref = cell.hyperlink.location
                if not link_ref and cell.hyperlink.target:
                    link_ref = cell.hyperlink.target.lstrip('#')
                if not link_ref:
                    continue
                tab_name = link_ref.split('!')[0].replace("'", "")
                name = cell.value.lower().strip()
                derived_name = name[:-len(' tables')].strip() if name.endswith(' tables') else name
                derived_names[tab_name] = derived_name
    
    return derived_names

def get_output_name(tab_name, derived_names):
    logger.debug('FUNCTION: get_output_name')
    return derived_names.get(tab_name, tab_name)

def validate_tables_columns(xls, tables, columns, current_layer, table_name):
    logger.debug('FUNCTION: validate_tables_columns')
    is_valid = True
    
    if current_layer == 'STG':
        # For STG layer, we don't validate aliases
        return True

    # Create a mapping of Source Table to a list of Aliases
    table_alias_mapping = {}
    for table_list in tables.values():
        for table in table_list:
            source_table = table['SOURCE TABLE']
            alias = table['ALIAS']
            if source_table in table_alias_mapping:
                table_alias_mapping[source_table].append(alias)
            else:
                table_alias_mapping[source_table] = [alias]

    # Get the set of aliases used in the Tables sheet
    table_aliases = {alias for aliases in table_alias_mapping.values() for alias in aliases}

    # Get the set of aliases used in the Columns sheet
    column_aliases = set(col['SOURCE TABLE'] for col in columns.values() if col.get('SOURCE TABLE') is not None)

    missing_tables = list(column_aliases - table_aliases)
    missing_columns = list(table_aliases - column_aliases)

    if missing_tables:
        logger.warning(f'Missing Table references on Columns Tab for {current_layer} {table_name}: {missing_tables}')
        is_valid = False
    if missing_columns:
        logger.warning(f'Missing Columns alias in Tables tab for {current_layer} {table_name}: {missing_columns}')
        is_valid = False

    return is_valid

def get_config(cur_layer, alter_sql='', scd_dict=None):
    """Builds the CONFIG dynamically based on the layer, alter SQL, and SCD information."""
    logger.debug('FUNCTION: get_config')
    config = {}

    # Skip config for Rawvault models
    if cur_layer.startswith(('STG', 'HUB', 'LINK', 'SAT', 'LSAT', 'MSAT', 'LNK', 'PIT', 'PB', 'DIM', 'FACT', 'RPT', 'REP' )):
        return ""

    # Basic config setup
    if alter_sql:
        alter_sql_str = '\n'.join(alter_sql) if isinstance(alter_sql, list) else alter_sql
        config['post_hook'] = f'("{alter_sql_str}")'

    # Incorporate snapshot config if SCD info is provided
    if scd_dict:
        snapshot_config = generate_dbt_snapshot_config(scd_dict)
        config.update(snapshot_config)

    # Generate the config string
    config_items = []
    for key, value in config.items():
        if isinstance(value, list):
            config_items.append(f"{key} = {value}")
        elif isinstance(value, str):
            config_items.append(f"{key} = '{value}'")
        else:
            config_items.append(f"{key} = {value}")

    if config_items:
        config_str = "{{ config(\n    " + ",\n    ".join(config_items) + "\n) }}"
    else:
        config_str = ""

    return config_str

def get_source_sql(target_table, cols, tables):
    logger.debug('FUNCTION: get_source_sql')
    current_layer = target_table.split('_')[0]
    columns = cols.copy()

    for idx, row in enumerate(columns.values()):
        src_col = row.get('SOURCE COLUMN', '')
        manual_logic = row.get('MANUAL LOGIC', '')
        datatype = row.get('DATATYPE')
        automated_logic = row.get('AUTOMATED_LOGIC')
        staging_col_name = row.get('STAGING LAYER COLUMN NAME', '')
        source_table = row.get('SOURCE TABLE')

        # Handle special case for deferred hash
        # HASH_FROM_HKS: (link HK from hub HKs, #1907) does NOT contain the substring
        # 'HASH:' so it must be matched explicitly.
        if (src_col == '(DERIVED)' and 
            not source_table and 
            manual_logic and  
            ('HASH:' in manual_logic.upper() or 'HASH_FROM_HKS:' in manual_logic.upper()) and 
            staging_col_name != 'HASHDIFF'):
            
            row['LOGIC_NAME'] = staging_col_name
            row['SQL'] = staging_col_name
            row['DEFER_HASH'] = True
            row['RENAME'] = staging_col_name
            row['IS_DERIVED'] = True
            continue

        # Initialize variables
        src_sql = ''

        # Handle regular cases
        if (current_layer == 'STG' or src_col == '(DERIVED)') and manual_logic:
            if 'HASH:' in str(manual_logic).upper() or 'COMPOSITE:' in str(manual_logic).upper():
                # Parse HASH:/COMPOSITE: directive — comma-separated list of columns
                # to wrap in MD5_BINARY(UPPER(CONCAT_WS(...))) per HK standard
                hashcol = manual_logic.replace('HASH:', '').replace('COMPOSITE:', '').replace('\n', '').replace(' ', '').strip()
                temp1 = [comp.strip() for comp in hashcol.split(',')]
                row['LOGIC_NAME'] = staging_col_name
                
                hash_components = []
                for component in temp1:
                    hash_components.append(f"COALESCE(NULLIF(TRIM(CAST({component} as VARCHAR)),''), '^^')")
                
                hash_concatenation = "\n       , ".join(hash_components)
                final_hash = f"        )))                                            "
                src_sql = f"""MD5_BINARY(UPPER(CONCAT_WS('||',
{hash_concatenation}
{final_hash}"""
            else:
                src_sql = manual_logic.strip()
        elif src_col == '(DERIVED)':
            if datatype == 'DATE':
                src_sql = f"""CASE WHEN {staging_col_name} is null then '-1' 
                                   WHEN {staging_col_name} < '1901-01-01' then '-2' 
                                   WHEN {staging_col_name} > '2099-12-31' then '-3' 
                                   ELSE regexp_replace({staging_col_name}, '[^0-9]+', '') 
                              END :: INTEGER"""
            else:
                src_sql = staging_col_name
            row['LOGIC_NAME'] = staging_col_name
        else:
            # For non-STG layers, treat HASHDIFF like any other source column
            src_sql = src_col
            if automated_logic:
                automated_logic = automated_logic.lower()
                if 'trim' in automated_logic:
                    src_sql = f"TRIM({src_sql})"
                if 'upper' in automated_logic:
                    src_sql = f"UPPER({src_sql})"
                if 'cast text' in automated_logic:
                    src_sql = f"CAST({src_sql} AS TEXT)"
            row['LOGIC_NAME'] = src_col

        row['SQL'] = src_sql
        row['RENAME'] = staging_col_name
        row['IS_DERIVED'] = src_col == '(DERIVED)'

    return columns