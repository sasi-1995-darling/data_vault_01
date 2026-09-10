{%- set yaml_metadata -%}

source_model: 'stg_partmstr__tt_e21'
src_pk: 
    - item_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - part_code
    - part_desc
    - uom
    - part_type
    - part_status
    - long_desc1
    - long_desc2
    - long_desc3
    - long_desc4
    - long_desc5
    - long_desc6
    - long_desc7
    - long_desc8
    - long_desc9
    - long_desc10
    - tt_color
    - tt_shape
    - part_length
    - part_width
    - part_height
    - sellable
    - base_part_flag
    - part_grp
    - part_subgrp
    - part_subgrp2
    - part_subgrp3
src_ldts: load_dts
src_source: rec_src

{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                   src_hashdiff=metadata_dict["src_hashdiff"],
                   src_payload=metadata_dict["src_payload"],
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}
