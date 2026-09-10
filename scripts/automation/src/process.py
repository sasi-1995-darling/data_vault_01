import openpyxl
import logging
from sheets import validate_tables_columns, get_derived_names, get_output_name
from build import build

logger = logging.getLogger(__name__)

def process_std_map(args, xls):
    logging.debug('FUNCTION: process_std_map')
    src_file = xls.name.split('.')[0]
    schemas = {'HUB':'RAW_VAULT', 'SAT':'RAW_VAULT', 'LSAT':'RAW_VAULT', 'MSAT':'RAW_VAULT', 'ESAT':'RAW_VAULT', 'LNK':'RAW_VAULT', 'TLINK':'RAW_VAULT', 'REF':'RAW_VAULT', 'BASE':'STAGING', 'STG':'STAGING', 'INT':'STAGING', 'PIT':'BUSINESS_VAULT', 'PB':'BUSINESS_VAULT', 'BRIDGE':'BUSINESS_VAULT', 'DIM':'BUSINESS_VAULT', 'FACT':'BUSINESS_VAULT', 'RPT':'INFOMART', 'REP':'INFOMART'}

    # Initialize report for this file
    report = args.reporter.start_file(xls.name)

    try:
        wb = openpyxl.load_workbook(xls)
        found_sheets = wb.sheetnames

        # Group sheets by layer type
        layer_groups = {}
        for sheet in found_sheets:
            parts = sheet.split()
            if len(parts) >= 2:
                layer = parts[0]
                if layer not in layer_groups:
                    layer_groups[layer] = []
                layer_groups[layer].append(sheet)

        # Log found sheets
        report.add_info(f"Found {len(found_sheets)} sheets in workbook")
        for layer, sheets in layer_groups.items():
            report.add_info(f"Layer {layer}: {len(sheets)} sheets")
            for sheet in sheets:
                report.add_info(f"  - {sheet}")

        # Process each layer
        for layer, sheets in layer_groups.items():
            for sheet in sheets:
                parts = sheet.split()
                table_name = ' '.join(parts[1:-1])
                sheet_type = parts[-1]
                
                if sheet_type == 'Tables':
                    # Add table to tracking
                    table_result = report.add_table(table_name, layer)
                    
                    try:
                        print(f'\t\t-- Processing {layer} {table_name} in: {xls.name}')
                        tables_data = process_tables(args, wb, sheet)
                        columns_sheet = f"{layer} {table_name} Columns"
                        
                        if columns_sheet in found_sheets:
                            columns_data = process_columns(args, wb, columns_sheet)
                            
                            # Validate table and column relationships
                            is_valid = validate_tables_columns(xls, tables_data, columns_data, layer, table_name)
                            
                            if not is_valid:
                                report.add_error(
                                    f"Table and Column aliases validation failed", 
                                    table_name
                                )
                                print(f'\t## ERROR: Table and Column aliases are not valid in: {xls.name} for {layer} {table_name}\n\n')
                                continue
                            
                            print(f'\n{layer} table: {layer}_{table_name}')
                            
                            try:
                                # Build the model
                                build(args, args.modeldir, f"{layer}_{table_name}", tables_data, columns_data, wb)
                                report.add_info(
                                    f"Successfully built {layer}_{table_name}", 
                                    table_name
                                )
                                if table_result.status != "WARNING":
                                    table_result.status = "SUCCESS"
                            except Exception as e:
                                error_msg = f"Build failed: {str(e)}"
                                report.add_error(error_msg, table_name)
                                table_result.status = "ERROR"
                        else:
                            table_result.status = "ERROR"
                            report.add_error(f"Missing Columns sheet: {columns_sheet}", table_name)
                    
                    except Exception as e:
                        table_result.status = "ERROR"
                        report.add_error(f"Processing failed: {str(e)}", table_name)

        return 1 if report.error_count > 0 else 0

    except Exception as e:
        report.add_error(f"Failed to process file: {str(e)}")
        return 1


def process_unified(args, xls):
    logging.debug('FUNCTION: process_unified')
    
    # Initialize report for this file
    report = args.reporter.start_file(xls.name)
    print(f'\t-- UNIFIED MAPPING: {xls.name}')
    
    try:
        wb = openpyxl.load_workbook(xls)
        derived_names = get_derived_names(wb)
        found_sheets = wb.sheetnames

        # Group sheets by layer type and table name
        layer_groups = {}
        for sheet in found_sheets:
            parts = sheet.split()
            if len(parts) >= 3:  # Layer, Table Name, Sheet Type
                layer = parts[0]
                sheet_type = parts[-1]
                table_name = ' '.join(parts[1:-1])
                
                if layer not in layer_groups:
                    layer_groups[layer] = {}
                if table_name not in layer_groups[layer]:
                    layer_groups[layer][table_name] = {'Tables': None, 'Columns': None}
                
                layer_groups[layer][table_name][sheet_type] = sheet

        # Log found sheets
        report.add_info("Found sheets by layer:")
        for layer, tables in layer_groups.items():
            if layer != 'Other':
                sheet_list = []
                for table_name, sheets in tables.items():
                    for sheet_type, sheet in sheets.items():
                        if sheet:
                            sheet_list.append(sheet)
                if sheet_list:
                    report.add_info(f"{layer} Layer: {', '.join(sheet_list)}")

        # Process each layer
        layers = {'HUB', 'SAT', 'LSAT', 'MSAT', 'ESAT', 'LNK', 'TLINK', 'REF', 'BASE', 'STG', 'INT', 'PIT', 'PB', 'BRIDGE', 'DIM', 'FACT', 'RPT', 'REP'}
        for this_layer in layers:
            if this_layer not in layer_groups:
                report.add_info(f'No sheets found for {this_layer} layer')
                continue

            for table_name, sheets in layer_groups[this_layer].items():
                # Add table to tracking
                table_result = report.add_table(table_name, this_layer)
                
                tables_tab = sheets.get('Tables')
                columns_tab = sheets.get('Columns')

                if not (tables_tab and columns_tab):
                    table_result.status = "SKIPPED"
                    report.add_warning(f"Skipping due to missing Tables or Columns sheet", table_name)
                    continue

                try:
                    # Process Tables sheet
                    report.add_info(f"Processing {this_layer} {table_name}", table_name)
                    tables = process_tables(args, wb, tables_tab)
                    columns = process_columns(args, wb, columns_tab)

                    # Validate and note any issues
                    is_valid = validate_tables_columns(xls, tables, columns, this_layer, table_name)
                    if not is_valid:
                        report.add_warning(
                            f"Table and Column aliases validation failed", 
                            table_name
                        )

                    # Get the output name and build
                    output_name = get_output_name(f"{this_layer} {table_name}", derived_names)
                    full_table_name = output_name.replace(' ', '_')
                    
                    try:
                        build(args, args.modeldir, full_table_name, tables, columns, wb)
                        report.add_info(
                            f"Successfully built {full_table_name}", 
                            table_name
                        )
                        if table_result.status != "WARNING":
                            table_result.status = "SUCCESS"
                    except Exception as e:
                        error_msg = f"Build failed: {str(e)}"
                        report.add_error(error_msg, table_name)
                        table_result.status = "ERROR"

                except Exception as e:
                    error_msg = f"Failed to process table: {str(e)}"
                    report.add_error(error_msg, table_name)
                    table_result.status = "ERROR"

        return 1 if report.error_count > 0 else 0

    except Exception as e:
        error_msg = f"Failed to process file: {str(e)}"
        report.add_error(error_msg)
        return 1

def process_tables(args, wb, tables_tab):
    logging.debug('FUNCTION: process_tables')
    print(f'\t\t-- Processing {tables_tab} ...')
    expected_cols = ['SOURCE SCHEMA', 'SOURCE TABLE', 'ALIAS', 'SOURCE LAYER FILTER', 'FILTER CONDITIONS', 'FILTER RESTRICTION RULE','PARENT JOIN NUMBER', 'PARENT TABLE JOIN', 'CHILD TABLE JOIN','FINAL LAYER FILTER', 'JOIN TYPE', 'TARGET SCHEMA', 'MODEL CONFIG']

    ws = wb[tables_tab]
    tables_dict = {}

    # Get derived names
    derived_names = get_derived_names(wb)

    # Convert found column names to uppercase
    found_cols = [cell.value.upper() if cell.value else None for cell in ws[1]]
    missing_cols = list(set(expected_cols) - set(found_cols))
    extra_cols = list(set(found_cols) - set(expected_cols))

    if extra_cols:
        logging.debug(f'\t\t\t-- Found Extra columns: {extra_cols}')
    if missing_cols:
        logging.debug(f'\t\t\t-- Missing columns: {missing_cols}')

    for row in ws.iter_rows(min_row=2, values_only=True):
        if 'SOURCE TABLE' in found_cols and row[found_cols.index('SOURCE TABLE')] is not None:
            source_table = row[found_cols.index('SOURCE TABLE')]
            alias = row[found_cols.index('ALIAS')]
            if source_table not in tables_dict:
                tables_dict[source_table] = []
            table_entry = {col: row[i] if i < len(row) else '' for i, col in enumerate(found_cols) if col}
            table_entry['DERIVED_NAME'] = derived_names.get(tables_tab, tables_tab)
            tables_dict[source_table].append(table_entry)

    # Debug: Print processed tables
    logging.debug(f"DEBUG: Processed tables: {tables_dict}")

    return tables_dict


def process_columns(args, wb, columns_tab):
    logging.debug('FUNCTION: process_columns')
    print(f'\t\t-- Processing {columns_tab} ...')
    
    # read the tables tab and convert to a dictionary
    expected_cols = ['SOURCE SCHEMA', 'SOURCE TABLE', 'SOURCE COLUMN', 'DATATYPE', 'AUTOMATED LOGIC', 'MANUAL LOGIC' , 'ORDER#', 'STAGING LAYER COLUMN NAME', 'STAGING LAYER DATATYPE', 'HASHDIFF', 'UNIQUE','SET DEFAULT', 'NOT NULL', 'REMOVE COLUMN', 'TEST EXPRESSION', 'ACCEPTED VALUES', 'RELATIONSHIP', 'MAPPING NOTES', 'PK','SCD']
    dim_cols = ['MODEL EQUALITY', 'MODEL EQUAL ROWCOUNT', 'SCD']
    dbt_cols_list = ['DBT_SCD_ID', 'DBT_VALID_FROM', 'DBT_VALID_TO', 'DBT_UPDATED_AT']
    cur_layer = columns_tab.split(' ')[0]

    if columns_tab.startswith('DIM'):
        expected_cols = expected_cols + dim_cols

    ws = wb[columns_tab]
    columns_dict = {}

    # Check for missing columns and convert to a list
    # missing_cols=[x for x in expected_cols if x not in found_cols]
    # extra_cols=[x for x in found_cols if x not in expected_cols]

    # Convert found column names to uppercase
    found_cols = [cell.value.upper() if cell.value else None for cell in ws[1]]
    
    missing_cols = list(set(expected_cols) - set(found_cols))
    extra_cols = list(set(found_cols) - set(expected_cols))

    if extra_cols:
        print(f'\t\t\t-- Found Extra columns: {extra_cols}')
    if missing_cols:
        print(f'\t\t\t-- Missing columns: {missing_cols}')
        
    for idx, row in enumerate(ws.iter_rows(min_row=2, values_only=True)):
        staging_col_name = row[found_cols.index('STAGING LAYER COLUMN NAME')]
        if staging_col_name is not None and staging_col_name not in dbt_cols_list:
            columns_dict[idx] = {}
            for i, col in enumerate(found_cols):
                if col:  # Only process non-None column names
                    columns_dict[idx][col] = row[i] if i < len(row) else ''
            
            # Handle Ghost Record column
            ghost_record_idx = found_cols.index('GHOST RECORD') if 'GHOST RECORD' in found_cols else None
            if ghost_record_idx is not None:
                ghost_record_value = row[ghost_record_idx]
                columns_dict[idx]['GHOST RECORD'] = ghost_record_value if ghost_record_value else 'NULL'

    # Debug: Print processed columns
    logging.debug(f"DEBUG: Processed columns: {columns_dict}")

    return columns_dict


