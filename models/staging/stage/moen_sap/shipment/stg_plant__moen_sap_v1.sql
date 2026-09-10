{%- set yaml_metadata -%}

source_model: 'base_plant__moen_sap_v1'
derived_columns:
    load_dts: current_timestamp()
    plant_bk: werks
hashed_columns:
    plant_hk: 
        - werks
        - bkcc
    hdiff:
        is_hashdiff: true
        columns:
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
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=metadata_dict["source_model"],
        derived_columns=metadata_dict["derived_columns"],
        null_columns=metadata_dict["null_columns"], 
        hashed_columns=metadata_dict["hashed_columns"],
    )
}}