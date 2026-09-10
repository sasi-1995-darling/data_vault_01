# config.py
import argparse
import logging
from pathlib import Path
from datetime import datetime
from reporter import ProcessReporter

logger = logging.getLogger(__name__)

def process_args():
    """Process command line arguments"""
    logger.debug('FUNCTION: process_args')
    parser = argparse.ArgumentParser(description='Command Line Arguments')
    parser.add_argument('--rootdir', default=Path.cwd(),
                        help='The Working Directory for maps and Models (defaults to Current Directory)')
    # boolean
    parser.add_argument('--yml', action='store_true', help='If set, only generate YAML schema/test files')
    parser.add_argument('--silent', action='store_true', help='If flagged will only print file names')
    parser.add_argument('--loglevel', default='INFO', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
                        help='Set the logging level')
    parser.add_argument('--yaml-config', default=None,
                        help='Path to YAML config file (Stage 2 pipeline). Bypasses XLSX workflow.')

    args = parser.parse_args()
    args.schema = 'DEV_EDW'

    if args.rootdir:
        args.rootdir = Path(args.rootdir)

    # Initialize reporter
    args.reporter = ProcessReporter()

    return args

def determine_subdir(output_name, target_schema):
    if output_name.startswith('v_psa_stg'):
        return 'int_staging_views'
    elif output_name.startswith('dim'):
        return 'bus_vault/dim'
    elif output_name.startswith('fact'):
        return 'bus_vault/fact'
    elif output_name.startswith('pb_'):
        return 'bus_vault/pit_bridge'
    elif output_name.startswith('pit'):
        return 'bus_vault/pit'
    elif output_name.startswith('bridge'):
        return 'bus_vault/bridge'
    elif output_name.startswith('rpt'):
        return 'info_mart/report_views'
    elif output_name.startswith('rep'):
        return 'info_mart/report_views'
    elif output_name.startswith('ref_'):
        return 'bus_vault/reference'
    elif output_name.startswith('hub'):
        return 'raw_vault/hub'
    elif output_name.startswith(('lnk', 'link', 'tlink')):
        return 'raw_vault/link'
    elif any(output_name.startswith(prefix) for prefix in ['sat', 'lsat', 'msat', 'esat']):
        return 'raw_vault/sat'
    elif output_name.startswith('im_'):
        return f'info_mart/{target_schema}'
    else:
        return ''

def setup(args):
    """Setup directories"""
    logger.debug('FUNCTION: setup')
    # Dictionary of directory names and their subdirectories
    dir_list = {'mapdir': 'mappings', 
                'modeldir': 'models'}

    # Create directories if they don't exist
    for dir_name, dir_path in dir_list.items():
        setattr(args, dir_name, args.rootdir / dir_path)
        if not getattr(args, dir_name).exists():
            getattr(args, dir_name).mkdir()

    logging.info('--Setting up directories--')
    for dir_name in dir_list:
        logging.info(f'{dir_name} directory: {getattr(args, dir_name)}')
    logging.info(f'{"-"*30}')

    logging.info('Mapping docs (XLS) in: %s', args.mapdir)
    logging.info('Output (SQL, YML) going to: %s', args.modeldir)

    # Show existing XLS files in Mapdir
    for afile in args.mapdir.glob('*.xlsx'):
        logging.info(f'\tMapping found: {afile}')

def setup_logging(log_level=logging.INFO, log_dir='logs'):
    """Setup logging configuration"""
    # Check if logging has already been configured
    if not getattr(logging.getLogger(''), 'handlers', []):
        log_dir_path = Path(log_dir)
        if not log_dir_path.exists():
            log_dir_path.mkdir(parents=True)
        
        log_file = log_dir_path / f'{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'
        log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        logging.basicConfig(level=log_level,
                          format=log_format,
                          handlers=[
                              logging.FileHandler(log_file),
                              logging.StreamHandler()
                          ])
        logging.info("Logging is set up.")

# Only initialize if this file is run directly
if __name__ == '__main__':
    args = process_args()
    setup_logging(log_level=getattr(logging, args.loglevel.upper(), logging.INFO))
    setup(args)
else:
    # Logging should be configured by the entrypoint (e.g., main.py)
    pass


