with
cte_bkcc as (
    select * from {{ ref('ref_business_key_collision') }}
    where rec_src = 'USOHNO.SAP.ECCPRD.Z_T001W'
)

select
    mandt
    , werks
    , glrequest
    , name1
    , bwkey
    , kunnr
    , lifnr
    , fabkl
    , name2
    , stras
    , pfach
    , pstlz
    , ort01
    , ekorg
    , vkorg
    , chazv
    , kkowk
    , kordb
    , bedpl
    , land1
    , regio
    , counc
    , cityc
    , adrnr
    , iwerk
    , txjcd
    , vtweg
    , spart
    , spras
    , wksop
    , awsls
    , chazv_old
    , vlfkz
    , bzirk
    , zone1
    , taxiw
    , bzqhl
    , let01
    , let02
    , let03
    , txnam_ma1
    , txnam_ma2
    , txnam_ma3
    , betol
    , j_1bbranch
    , vtbfi
    , fprfw
    , achvm
    , dvsart
    , nodetype
    , nschema
    , pkosa
    , misch
    , mgvupd
    , vstel
    , mgvlaupd
    , mgvlareval
    , sourcing
    , fsh_mg_arun_req
    , fsh_seaim
    , fsh_bom_maintenance
    , oilival
    , oihvtype
    , oihcredipi
    , storetype
    , dep_store
    , gldelflag
    , glchangetime
    , TO_TIMESTAMP(
        SUBSTR(glchangetime, 1, 8) || ' '
        || SUBSTR(glchangetime, 9, 2) || ':'
        || SUBSTR(glchangetime, 11, 2) || ':'
        || SUBSTR(glchangetime, 13, 2) || '.'
        || REGEXP_REPLACE(SUBSTR(glchangetime, 16), '^\\.', '')
        , 'YYYYMMDD HH24:MI:SS.FF9'
    ) as glchangetime_dttm -- GLUE_REPLICATION_DATE (EQUIVALENT TO FIVETRAN_SYNC_DTTM),
    , glsourcesystem
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from {{ source('bronze_moen_sap', 'z_t001w') }}
    inner join cte_bkcc on 1 = 1

union all

select
    null as mandt
    , '-2' as werks
    , null as glrequest
    , null as name1
    , null as bwkey
    , null as kunnr
    , null as lifnr
    , null as fabkl
    , null as name2
    , null as stras
    , null as pfach
    , null as pstlz
    , null as ort01
    , null as ekorg
    , null as vkorg
    , null as chazv
    , null as kkowk
    , null as kordb
    , null as bedpl
    , null as land1
    , null as regio
    , null as counc
    , null as cityc
    , null as adrnr
    , null as iwerk
    , null as txjcd
    , null as vtweg
    , null as spart
    , null as spras
    , null as wksop
    , null as awsls
    , null as chazv_old
    , null as vlfkz
    , null as bzirk
    , null as zone1
    , null as taxiw
    , null as bzqhl
    , null as let01
    , null as let02
    , null as let03
    , null as txnam_ma1
    , null as txnam_ma2
    , null as txnam_ma3
    , null as betol
    , null as j_1bbranch
    , null as vtbfi
    , null as fprfw
    , null as achvm
    , null as dvsart
    , null as nodetype
    , null as nschema
    , null as pkosa
    , null as misch
    , null as mgvupd
    , null as vstel
    , null as mgvlaupd
    , null as mgvlareval
    , null as sourcing
    , null as fsh_mg_arun_req
    , null as fsh_seaim
    , null as fsh_bom_maintenance
    , null as oilival
    , null as oihvtype
    , null as oihcredipi
    , null as storetype
    , null as dep_store
    , null as gldelflag
    , null as glchangetime
    , null as glchangetime_dttm
    , null as glsourcesystem
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_bkcc
