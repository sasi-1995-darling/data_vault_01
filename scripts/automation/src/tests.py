import logging

logger = logging.getLogger(__name__)

def get_model_tests(row, table_name, severity='warn'):
    """Generate model-level tests following dbt v1.8+ syntax with proper arguments structure.
    https://github.com/fishtown-analytics/dbt-utils
    """
    logger.debug('FUNCTION: get_model_tests')
    test_cols = ['UNIQUE', 'MODEL EQUALITY', 'MODEL EQUAL ROWCOUNT', 'TEST EXPRESSION', 'PK']
    tests = []

    for atest in test_cols:
        if atest not in row:
            continue
        if not row[atest]:
            continue

        if atest == 'UNIQUE':
            if ':' in str(row[atest]):
                test = str(row[atest]).replace('COMPOSITE:', '').strip()
                test = test.replace("unique:", "").replace("Unique:", "").strip()
                tests.append({
                    'dbt_utils.unique_combination_of_columns': {
                        'arguments': {
                            'combination_of_columns': [each.strip() for each in test.split(',')]
                        },
                        'config': {
                            'severity': severity
                        }
                    }
                })

        elif atest == 'PK':
            if ':' in str(row[atest]):
                test = str(row[atest]).replace('PK:', '').strip()
                pk_test = {
                    'dbt_constraints.primary_key': {
                        'arguments': {
                            'column_names': [each.strip() for each in test.split(',')]
                        },
                        'config': {
                            'severity': severity
                        }
                    }
                }
                tests.append(pk_test)

        elif atest == 'MODEL EQUALITY':
            logger.debug(f'Found Model Equality -> {row[atest]}')
            test = str(row[atest]).strip()
            tests.append({
                'dbt_utils.equality': {
                    'arguments': {
                        'compare_model': f"ref( {row['STAGING LAYER COLUMN NAME']} )",
                        'compare_columns': [each.strip() for each in test.split(',')]
                    }
                }
            })

        elif atest == 'MODEL EQUAL ROWCOUNT':
            logger.debug(f'Found Model Equal Rowcount -> {row[atest]}')
            tests.append({
                'dbt_utils.equal_rowcount': {
                    'arguments': {
                        'compare_model': f'ref({row[atest]!r})'
                    }
                }
            })

        elif atest == 'TEST EXPRESSION':
            if row.get('STAGING LAYER COLUMN NAME', 'x') in row.get('TEST EXPRESSION', 'y'):
                test = str(row[atest]).strip()
                tests.append({
                    'dbt_utils.expression_is_true': {
                        'arguments': {
                            'expression': test
                        },
                        'config': {
                            'severity': severity
                        }
                    }
                })

    return tests


def get_column_tests(row, table_name, severity='warn'):
    """Generate column-level tests following dbt v1.8+ syntax with proper arguments structure.
    https://github.com/fishtown-analytics/dbt-utils
    """
    logger.debug('FUNCTION: get_column_tests')
    test_cols = ['UNIQUE', 'NOT NULL', 'TEST EXPRESSION', 'ACCEPTED VALUES', 'RELATIONSHIP', 'SET DEFAULT']
    tests = []

    for atest in test_cols:
        if atest not in row:
            continue
        if not row[atest]:
            continue

        if atest == 'SET DEFAULT':
            test = str(row[atest]).strip()
            row['DEFAULT'] = test
            # Skip adding as test for fact tables and others
            if table_name.startswith('F'):
                continue

        elif atest == 'UNIQUE':
            if ':' not in str(row[atest]):
                tests.append({
                    'unique': {
                        'config': {
                            'severity': severity
                        }
                    }
                })

        elif atest == 'NOT NULL':
            # Skip not_null test on BK columns when null_bk_coalesced is true
            # (COALESCE already handles NULLs, so the test would be meaningless)
            if row.get('_NULL_BK_COALESCED'):
                logger.debug(f"Skipping not_null test on {row.get('STAGING LAYER COLUMN NAME', '')} (null_bk_coalesced=true)")
                continue
            if 'where' in str(row[atest]).lower():
                test = str(row[atest]).upper().replace('WHERE', '').strip()
                tests.append({
                    'dbt_utils.not_null_where': {
                        'arguments': {
                            'where': test
                        }
                    }
                })
            else:
                tests.append({
                    'not_null': {
                        'config': {
                            'severity': severity
                        }
                    }
                })

        elif atest == 'ACCEPTED VALUES':
            if 'not:' in str(row[atest]).lower():
                test = str(row[atest]).upper().replace('NOT:', '').strip()
                tests.append({
                    'not_accepted_values': {
                        'arguments': {
                            'values': [each.strip() for each in test.split(',')]
                        },
                        'config': {
                            'severity': severity
                        }
                    }
                })
            else:
                test = str(row[atest])
                tests.append({
                    'accepted_values': {  # Fixed typo: was 'accepted_valids'
                        'arguments': {
                            'values': [each.strip() for each in test.split(',')]
                        },
                        'config': {
                            'severity': severity
                        }
                    }
                })

        elif atest == 'TEST EXPRESSION':
            if not row.get('STAGING LAYER COLUMN NAME', 'x') in str(row[atest]).strip():
                test = str(row[atest]).strip()
                tests.append({
                    'dbt_utils.expression_is_true': {
                        'arguments': {
                            'expression': test
                        },
                        'config': {
                            'severity': severity,
                            'ignore': ''  # Custom property moved under config
                        }
                    }
                })

        elif atest == 'RELATIONSHIP':
            # Parse relationship configuration
            ref_table, ref_field, ref_ignore = _parse_relationship_config(row)
            ignore_in = _get_ignore_values(row, ref_field)
            
            # Create the relationships_where test (even though it gets filtered out later)
            tests.append({
                'dbt_utils.relationships_where': {
                    'arguments': {
                        'to': f'ref( {ref_table.lower()!r} )',
                        'field': f"{ref_field}"
                    }
                }
            })

            # Create the foreign key constraint test
            tests.append({
                'dbt_constraints.foreign_key': {
                    'arguments': {
                        'pk_table_name': f'ref( {ref_table.lower()!r} )',
                        'pk_column_name': f"{ref_field}"
                    }
                }
            })

    return tests


def _parse_relationship_config(row):
    """
    Helper function to parse relationship configuration.
    Returns: (ref_table, ref_field, ref_ignore)
    """
    relationship_value = row['RELATIONSHIP']
    ref_ignore = row['STAGING LAYER COLUMN NAME']
    
    if '.' in relationship_value:
        ref_table = relationship_value.split('.')[0]
        ref_field = relationship_value.split('.')[1]
    else:
        ref_table = relationship_value
        ref_field = row['STAGING LAYER COLUMN NAME']
    
    return ref_table, ref_field, ref_ignore


def _get_ignore_values(row, ref_field):
    """
    Helper function to get ignore values for relationship tests.
    """
    if ref_field == 'DATE_KEY':
        return " -1, -2, -3 "
    
    ignore_list = row.get('SET DEFAULT')
    if ignore_list is not None:
        ignore_vals = str(ignore_list).split(',')
        ignore_md5 = [f'{val}' for val in ignore_vals]
        return ', '.join(ignore_md5)
    
    return " '40c5dea533476acdd01f7ef0e84de22f', 'fcbcdcb8f6b1c597c5fdc7a54cd321ae' "


# Legacy support functions (if needed for backward compatibility)
def _convert_legacy_test_format(test_dict):
    """
    Convert legacy test format to new dbt v1.8+ format.
    This can be used if you need to support both formats temporarily.
    """
    if not isinstance(test_dict, dict):
        return test_dict
    
    converted = {}
    for test_name, test_config in test_dict.items():
        if isinstance(test_config, dict):
            # Separate arguments from config
            arguments = {}
            config = {}
            
            for key, value in test_config.items():
                if key in ['severity', 'warn_if', 'error_if', 'where', 'limit']:
                    config[key] = value
                else:
                    arguments[key] = value
            
            new_test = {test_name: {}}
            if arguments:
                new_test[test_name]['arguments'] = arguments
            if config:
                new_test[test_name]['config'] = config
            
            converted.update(new_test)
        else:
            converted[test_name] = test_config
    
    return converted