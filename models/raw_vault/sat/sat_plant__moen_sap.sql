{%- set yaml_metadata -%}

source_model: 'stg_plant__moen_sap'
src_pk: 
    - plant_hk
src_hashdiff: 
  source_column: hash_diff
  alias: hashdiff
src_payload:
    - mandt
    - glrequest
    - name1
    - bwkey
    - kunnr
    - lifnr
    - fabkl
    - name2
    - stras
    - pfach
    - pstlz
    - ort01
    - ekorg
    - vkorg
    - chazv
    - kkowk
    - kordb
    - bedpl
    - land1
    - regio
    - counc
    - cityc
    - adrnr
    - iwerk
    - txjcd
    - vtweg
    - spart
    - spras
    - wksop
    - awsls
    - chazv_old
    - vlfkz
    - bzirk
    - zone1
    - taxiw
    - bzqhl
    - let01
    - let02
    - let03
    - txnam_ma1
    - txnam_ma2
    - txnam_ma3
    - betol
    - j_1bbranch
    - vtbfi
    - fprfw
    - achvm
    - dvsart
    - nodetype
    - nschema
    - pkosa
    - misch
    - mgvupd
    - vstel
    - mgvlaupd
    - mgvlareval
    - sourcing
    - fsh_mg_arun_req
    - fsh_seaim
    - fsh_bom_maintenance
    - oilival
    - oihvtype
    - oihcredipi
    - storetype
    - dep_store
    - gldelflag
    - glsourcesystem

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