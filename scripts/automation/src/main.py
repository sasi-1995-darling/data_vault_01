import os
import logging
import traceback
from config import process_args, setup, setup_logging
from process import process_unified, process_std_map

# Initialize logger
logger = logging.getLogger(__name__)


def process_yaml_config(args, yaml_config_path):
    """
    Process a YAML config file (Stage 2 pipeline).
    Reads YAML → converts to tables/columns dicts → calls build() for each model.
    """
    from yaml_reader import (
        load_yaml_config, yaml_to_tables_dict, yaml_to_columns_dict,
        get_pipeline_metadata, generate_source_entry,
    )
    from build import build
    from sheets import get_source_sql

    config = load_yaml_config(yaml_config_path)
    meta = get_pipeline_metadata(config)

    logger.info(f"YAML config loaded: {yaml_config_path}")
    logger.info(f"  schema_version: {meta.get('schema_version', '1.0')}")
    logger.info(f"  bkcc_rec_src: {meta.get('bkcc_rec_src')}")
    logger.info(f"  has_fivetran_deleted: {meta.get('has_fivetran_deleted', False)}")
    logger.info(f"  has_psa_delete_ind: {meta.get('has_psa_delete_ind', True)}")
    logger.info(f"  null_bk_coalesced: {meta.get('null_bk_coalesced', False)}")
    logger.info(f"  large_volume: {meta.get('large_volume', False)}")

    source_entries = []

    for model in config["models"]:
        derived_name = model["derived_name"]
        layer = model.get("layer", "STG").upper()
        table_name = f"{layer}_{model.get('short_name', derived_name).replace(' ', '_')}"

        logger.info(f"Processing model: {derived_name} (layer={layer})")

        tables = yaml_to_tables_dict(model)
        columns = yaml_to_columns_dict(model, pipeline_metadata=meta)

        # Determine large_volume per model layer:
        #   STG: uses STG-level large_volume flag (>300M)
        #   HUB: uses hub_use_watermark flag (≥50M) to trigger INCR_WATERMARK CTE
        if layer == 'HUB':
            model_large_volume = meta.get("hub_use_watermark", False)
        else:
            model_large_volume = meta.get("large_volume", False)

        # Build the model
        build(
            args,
            args.modeldir,
            table_name,
            tables,
            columns,
            wb=None,
            large_volume=model_large_volume,
            bkcc_rec_src=meta.get("bkcc_rec_src"),
        )

        # Generate source entry for STG models
        source_entry = generate_source_entry(model, pipeline_metadata=meta)
        if source_entry:
            source_entries.append(source_entry)
            logger.info(f"  Source entry: {source_entry['source_name']}.{source_entry['table_name']}")

        args.count += 1

    # Report source entries
    if source_entries:
        logger.info(f"\n{'='*40}")
        logger.info("Source entries to register in _sources_staging_psa.yml:")
        for entry in source_entries:
            logger.info(f"  - source: {entry['source_name']}, table: {entry['table_name']}")
        logger.info(f"{'='*40}\n")

    return source_entries


# Functions
def main():
    # Get arguments and set up logging just once
    args = process_args()
    loglevel = getattr(logging, args.loglevel.upper(), None)
    if not isinstance(loglevel, int):
        raise ValueError(f'Invalid log level: {args.loglevel}')

    setup_logging(log_level=loglevel)

    # Setup directories
    setup(args)

    if args.rootdir:
        logger.info(f"Working directory: {args.rootdir}")

    args.count, args.err = 0, 0
    plural = ''
    logger.info('\n' + '-'*30)

    # Branch: YAML config path vs XLSX path
    yaml_config = getattr(args, 'yaml_config', None)
    if yaml_config:
        logger.info(f"Using YAML config path: {yaml_config}")
        try:
            source_entries = process_yaml_config(args, yaml_config)
        except Exception as e:
            logger.error(f"YAML config processing failed: {e}")
            traceback.print_exc()
            args.err += 1
    else:
        # Existing XLSX workflow
        for xls in args.mapdir.glob('*.xls*'):
            logger.info(f'<< Processing: {xls}')
            if 'xls' not in xls.suffix.lower():
                logger.warning(f'Skipping non-XLS file: {xls}')
                continue

            logger.info('-'*30)
            logger.info(f"Currently processing {os.path.basename(xls)}")

            if 'UNIFIED' in xls.name.upper():
                logger.info(f'UNIFIED MAPPING: {xls.name}')
                err = process_unified(args, xls)
            else:
                logger.info(f'Standard MAPPING: {xls.name}')
                err = process_std_map(args, xls)

            args.count += 1
            args.err += err

    # Display all processing reports
    args.reporter.display_all()

    plural = 's.' if args.count > 1 else '.'

    logger.info(f'Processed: {args.count} file{plural}')
    if args.count > 0:
        if yaml_config:
            logger.info(f'YAML config: {yaml_config} \nModels written to: {args.modeldir}')
        else:
            logger.info(f'Mapping docs (XLS) in: {args.mapdir} \nModels written to: {args.modeldir}')
    if args.err > 0:
        plural =  'S.' if args.err > 1 else '.'
        logger.error(f'Encountered {args.err} ERROR{plural}')

if __name__ == '__main__':
    main()