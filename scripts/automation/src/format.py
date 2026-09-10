import logging

logger = logging.getLogger(__name__)

##all formatting functions will be stored here

def format_select_cols(columns, layer):
    """Legacy XLSX-path formatter. The YAML path uses build.py instead.

    .. deprecated::
        This function is part of the legacy XLSX pipeline and will be
        removed once all models are migrated to the YAML pipeline.
        New models MUST use build.py instead.
    """
    logger.debug('FUNCTION: format_select_cols')
    select_cols = []
    hashdiff_columns = []

    for idx, col in enumerate(columns.values()):
        col_name = col.get('STAGING LAYER COLUMN NAME')
        src_sql = col.get('SQL')
        hashdiff_flag = (col.get('HASHDIFF') or '').strip().upper()

        if col_name:
            if layer == 'FINAL':
                # Gather columns for HASHDIFF if applicable
                if hashdiff_flag in ('Y', 'YES'):
                    hashdiff_columns.append(col_name)

                # Non-HASHDIFF columns are simply listed
                col_str = col_name if idx == 0 else f"      , {col_name}"

            else:
                # Non-final layer logic: Handle SQL formatting or col_name assignment
                if '\n' in src_sql:
                    src_sql = format_manual_logic(src_sql, ' ' * 12)
                col_str = f"{src_sql:<60} as {col_name:>50}"

            select_cols.append(col_str)

    # For FINAL layer, append the HASHDIFF calculation
    # NOTE: Legacy formula uses MD5(). The YAML path (build.py) uses the DV 2.x standard:
    # MD5_BINARY(UPPER(NULLIF(CONCAT(IFNULL(TRIM(col::text), '^^'), '||', ...), '^^||^^')))
    if layer == 'FINAL' and hashdiff_columns:
        hashdiff_expression = " || '|' || ".join(hashdiff_columns)
        hashdiff_sql = f"MD5({hashdiff_expression}) as HASHDIFF"
        select_cols.append(f"      , {hashdiff_sql}")

    return '\n'.join(select_cols)


def format_manual_logic(logic, indent):
    logger.debug('FUNCTION: format_manual_logic')
    if not logic or '\n' not in logic:
        return logic
    lines = logic.split('\n')
    return f"{lines[0]}\n" + '\n'.join([f"{indent}{line.strip()}" for line in lines[1:]])