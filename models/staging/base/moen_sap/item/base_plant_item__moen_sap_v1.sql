with
cte_bkcc as (
    select * from {{ ref('ref_business_key_collision') }}
    where rec_src = 'USOHNO.SAP.ECCPRD.Z_MARC'
)

, cte_marc as (select * from {{ source('bronze_moen_sap', 'z_marc') }})

select
    m.matnr
    , m.werks
    , m.mandt
    , m.glrequest
    , m.glsourcesystem
    , m.pstat
    , m.lvorm
    , m.bwtty
    , m.xchar
    , m.mmsta
    , m.mmstd
    , m.maabc
    , m.kzkri
    , m.ekgrp
    , m.ausme
    , m.dispr
    , m.dismm
    , m.dispo
    , m.kzdie
    , m.plifz
    , m.webaz
    , m.perkz
    , m.ausss
    , m.disls
    , m.beskz
    , m.sobsl
    , m.minbe
    , m.eisbe
    , m.bstmi
    , m.bstma
    , m.bstfe
    , m.bstrf
    , m.mabst
    , m.losfx
    , m.sbdkz
    , m.lagpr
    , m.altsl
    , m.kzaus
    , m.ausdt
    , m.nfmat
    , m.kzbed
    , m.miskz
    , m.fhori
    , m.pfrei
    , m.ffrei
    , m.rgekz
    , m.fevor
    , m.bearz
    , m.ruezt
    , m.tranz
    , m.basmg
    , m.dzeit
    , m.maxlz
    , m.lzeih
    , m.kzpro
    , m.gpmkz
    , m.ueeto
    , m.ueetk
    , m.uneto
    , m.wzeit
    , m.atpkz
    , m.vzusl
    , m.herbl
    , m.insmk
    , m.sproz
    , m.quazt
    , m.ssqss
    , m.mpdau
    , m.kzppv
    , m.kzdkz
    , m.wstgh
    , m.prfrq
    , m.nkmpr
    , m.umlmc
    , m.ladgr
    , m.xchpf
    , m.usequ
    , m.lgrad
    , m.auftl
    , m.plvar
    , m.otype
    , m.objid
    , m.mtvfp
    , m.periv
    , m.kzkfk
    , m.vrvez
    , m.vbamg
    , m.vbeaz
    , m.lizyk
    , m.bwscl
    , m.kautb
    , m.kordb
    , m.stawn
    , m.herkl
    , m.herkr
    , m.expme
    , m.mtver
    , m.prctr
    , m.trame
    , m.mrppp
    , m.sauft
    , m.fxhor
    , m.vrmod
    , m.vint1
    , m.vint2
    , m.verkz
    , m.stlal
    , m.stlan
    , m.plnnr
    , m.aplal
    , m.losgr
    , m.sobsk
    , m.frtme
    , m.lgpro
    , m.disgr
    , m.kausf
    , m.qzgtp
    , m.qmatv
    , m.takzt
    , m.rwpro
    , m.copam
    , m.abcin
    , m.awsls
    , m.sernp
    , m.cuobj
    , m.stdpd
    , m.sfepr
    , m.xmcng
    , m.qssys
    , m.lfrhy
    , m.rdprf
    , m.vrbmt
    , m.vrbwk
    , m.vrbdt
    , m.vrbfk
    , m.autru
    , m.prefe
    , m.prenc
    , m.preno
    , m.prend
    , m.prene
    , m.preng
    , m.itark
    , m.servg
    , m.kzkup
    , m.strgr
    , m.cuobv
    , m.lgfsb
    , m.schgt
    , m.ccfix
    , m.eprio
    , m.qmata
    , m.resvp
    , m.plnty
    , m.uomgr
    , m.umrsl
    , m.abfac
    , m.sfcpf
    , m.shflg
    , m.shzet
    , m.mdach
    , m.kzech
    , m.megru
    , m.mfrgr
    , m.vkumc
    , m.vktrw
    , m.kzagl
    , m.fvidk
    , m.fxpru
    , m.loggr
    , m.fprfm
    , m.glgmg
    , m.vkglg
    , m.indus
    , m.mownr
    , m.mogru
    , m.casnr
    , m.gpnum
    , m.steuc
    , m.fabkz
    , m.matgr
    , m.vspvb
    , m.dplfs
    , m.dplpu
    , m.dplho
    , m.minls
    , m.maxls
    , m.fixls
    , m.ltinc
    , m.compl
    , m.convt
    , m.shpro
    , m.ahdis
    , m.diber
    , m.kzpsp
    , m.ocmpf
    , m.apokz
    , m.mcrue
    , m.lfmon
    , m.lfgja
    , m.eislo
    , m.ncost
    , m.rotation_date
    , m.uchkz
    , m.ucmat
    , m.bwesb
    , m.sgt_covs
    , m.sgt_statc
    , m.sgt_scope
    , m.sgt_mrpsi
    , m.sgt_prcm
    , m.sgt_chint
    , m.sgt_stk_prt
    , m.sgt_defsc
    , m.sgt_mrp_atp_status
    , m.sgt_mmstd
    , m.fsh_mg_arun_req
    , m.fsh_seaim
    , m.fsh_var_group
    , m.fsh_kzech
    , m.fsh_calendar_group
    , m.ppskz
    , m.pps_strategy
    , m.pps_planning_type
    , m.pps_heur_id
    , m.pps_fixpeg
    , m.pps_peg_strategy
    , m.pps_grprt
    , m.pps_giprt
    , m.pps_conhap
    , m.pps_hunit
    , m.pps_conhap_out
    , m.pps_hunit_out
    , m.pps_atpcheck
    , m.pps_peg_fut_al
    , m.pps_peg_past_al
    , m."/SAPMP/TOLPRPL" as sapmp_tolprpl
    , m."/SAPMP/TOLPRMI" as sapmp_tolprmi
    , m."/VSO/R_PKGRP" as vso_r_pkgrp
    , m."/VSO/R_LANE_NUM" as vso_r_lane_num
    , m."/VSO/R_PAL_VEND" as vso_r_pal_vend
    , m."/VSO/R_FORK_DIR" as vso_r_fork_dir
    , m.iuid_relevant
    , m.iuid_type
    , m.uid_iea
    , m.cons_procg
    , m.gi_pr_time
    , m.multiple_ekgrp
    , m.ref_schema
    , m.min_troc
    , m.max_troc
    , m.target_stock
    , m.zzobsdt
    , m.zzdpla
    , m.zzpltsl
    , m.zzexltm
    , m.zzxmatnr
    , m.zzslsrce
    , m.zzgovtmatclass
    , m.zzsupply_var_fct
    , m.zzatcostatus
    , m.zz_snp_horiz
    , m.zztarget_dur
    , m.zzctm
    , m.zztarget_method
    , m.zzplanner_pps
    , m.zzdprex
    , m.zzsprex
    , m.zzrrp_type
    , m.zzheur_id
    , m.zzss_method
    , m.zzconvh
    , m.zzpeg_strategy
    , m.zzpeg_past_max
    , m.zzpeg_future_max
    , m.zzdeldate
    , m.zzfinlbq
    , m.zzwarrantydt
    , m.zzprod_priority
    , m.zzperod_spl_prof
    , m.zzservice_time
    , m.zzplanning_time
    , m.zzfrozen_period
    , m.zziominmaxtype
    , m.zziominssvalue
    , m.zziomaxssvalue
    , m.zziominmaxreason
    , m.zzcovprofequal
    , m.zziooutputcont
    , m.zziosafetystock
    , m.zzriskmitweeks
    , m.zzriskmitstock
    , m.zzmanualssvalue
    , m.zzmanualssreason
    , m.zzionotes
    , m.zzioprodtime
    , m.zzopt
    , m.zzproductionoffset
    , m.zzleadtimeoffset
    , m.gldelflag
    , to_timestamp(
        substr(glchangetime, 1, 8) || ' '
        || substr(glchangetime, 9, 2) || ':'
        || substr(glchangetime, 11, 2) || ':'
        || substr(glchangetime, 13, 2) || '.'
        || regexp_replace(substr(glchangetime, 16), '^\\.', '')
        , 'YYYYMMDD HH24:MI:SS.FF9'
    ) as glchangetime_dttm -- GLUE_REPLICATION_DATE (EQUIVALENT TO FIVETRAN_SYNC_DTTM),
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_marc as m
    inner join cte_bkcc on 1 = 1

union all

select
    ma.matnr
    , '-2' as werks
    , null as mandt
    , null as glrequest
    , null as glsourcesystem
    , null as pstat
    , null as lvorm
    , null as bwtty
    , null as xchar
    , null as mmsta
    , null as mmstd
    , null as maabc
    , null as kzkri
    , null as ekgrp
    , null as ausme
    , null as dispr
    , null as dismm
    , null as dispo
    , null as kzdie
    , null as plifz
    , null as webaz
    , null as perkz
    , null as ausss
    , null as disls
    , null as beskz
    , null as sobsl
    , null as minbe
    , null as eisbe
    , null as bstmi
    , null as bstma
    , null as bstfe
    , null as bstrf
    , null as mabst
    , null as losfx
    , null as sbdkz
    , null as lagpr
    , null as altsl
    , null as kzaus
    , null as ausdt
    , null as nfmat
    , null as kzbed
    , null as miskz
    , null as fhori
    , null as pfrei
    , null as ffrei
    , null as rgekz
    , null as fevor
    , null as bearz
    , null as ruezt
    , null as tranz
    , null as basmg
    , null as dzeit
    , null as maxlz
    , null as lzeih
    , null as kzpro
    , null as gpmkz
    , null as ueeto
    , null as ueetk
    , null as uneto
    , null as wzeit
    , null as atpkz
    , null as vzusl
    , null as herbl
    , null as insmk
    , null as sproz
    , null as quazt
    , null as ssqss
    , null as mpdau
    , null as kzppv
    , null as kzdkz
    , null as wstgh
    , null as prfrq
    , null as nkmpr
    , null as umlmc
    , null as ladgr
    , null as xchpf
    , null as usequ
    , null as lgrad
    , null as auftl
    , null as plvar
    , null as otype
    , null as objid
    , null as mtvfp
    , null as periv
    , null as kzkfk
    , null as vrvez
    , null as vbamg
    , null as vbeaz
    , null as lizyk
    , null as bwscl
    , null as kautb
    , null as kordb
    , null as stawn
    , null as herkl
    , null as herkr
    , null as expme
    , null as mtver
    , null as prctr
    , null as trame
    , null as mrppp
    , null as sauft
    , null as fxhor
    , null as vrmod
    , null as vint1
    , null as vint2
    , null as verkz
    , null as stlal
    , null as stlan
    , null as plnnr
    , null as aplal
    , null as losgr
    , null as sobsk
    , null as frtme
    , null as lgpro
    , null as disgr
    , null as kausf
    , null as qzgtp
    , null as qmatv
    , null as takzt
    , null as rwpro
    , null as copam
    , null as abcin
    , null as awsls
    , null as sernp
    , null as cuobj
    , null as stdpd
    , null as sfepr
    , null as xmcng
    , null as qssys
    , null as lfrhy
    , null as rdprf
    , null as vrbmt
    , null as vrbwk
    , null as vrbdt
    , null as vrbfk
    , null as autru
    , null as prefe
    , null as prenc
    , null as preno
    , null as prend
    , null as prene
    , null as preng
    , null as itark
    , null as servg
    , null as kzkup
    , null as strgr
    , null as cuobv
    , null as lgfsb
    , null as schgt
    , null as ccfix
    , null as eprio
    , null as qmata
    , null as resvp
    , null as plnty
    , null as uomgr
    , null as umrsl
    , null as abfac
    , null as sfcpf
    , null as shflg
    , null as shzet
    , null as mdach
    , null as kzech
    , null as megru
    , null as mfrgr
    , null as vkumc
    , null as vktrw
    , null as kzagl
    , null as fvidk
    , null as fxpru
    , null as loggr
    , null as fprfm
    , null as glgmg
    , null as vkglg
    , null as indus
    , null as mownr
    , null as mogru
    , null as casnr
    , null as gpnum
    , null as steuc
    , null as fabkz
    , null as matgr
    , null as vspvb
    , null as dplfs
    , null as dplpu
    , null as dplho
    , null as minls
    , null as maxls
    , null as fixls
    , null as ltinc
    , null as compl
    , null as convt
    , null as shpro
    , null as ahdis
    , null as diber
    , null as kzpsp
    , null as ocmpf
    , null as apokz
    , null as mcrue
    , null as lfmon
    , null as lfgja
    , null as eislo
    , null as ncost
    , null as rotation_date
    , null as uchkz
    , null as ucmat
    , null as bwesb
    , null as sgt_covs
    , null as sgt_statc
    , null as sgt_scope
    , null as sgt_mrpsi
    , null as sgt_prcm
    , null as sgt_chint
    , null as sgt_stk_prt
    , null as sgt_defsc
    , null as sgt_mrp_atp_status
    , null as sgt_mmstd
    , null as fsh_mg_arun_req
    , null as fsh_seaim
    , null as fsh_var_group
    , null as fsh_kzech
    , null as fsh_calendar_group
    , null as ppskz
    , null as pps_strategy
    , null as pps_planning_type
    , null as pps_heur_id
    , null as pps_fixpeg
    , null as pps_peg_strategy
    , null as pps_grprt
    , null as pps_giprt
    , null as pps_conhap
    , null as pps_hunit
    , null as pps_conhap_out
    , null as pps_hunit_out
    , null as pps_atpcheck
    , null as pps_peg_fut_al
    , null as pps_peg_past_al
    , null as sapmp_tolprpl
    , null as sapmp_tolprmi
    , null as vso_r_pkgrp
    , null as vso_r_lane_num
    , null as vso_r_pal_vend
    , null as vso_r_fork_dir
    , null as iuid_relevant
    , null as iuid_type
    , null as uid_iea
    , null as cons_procg
    , null as gi_pr_time
    , null as multiple_ekgrp
    , null as ref_schema
    , null as min_troc
    , null as max_troc
    , null as target_stock
    , null as zzobsdt
    , null as zzdpla
    , null as zzpltsl
    , null as zzexltm
    , null as zzxmatnr
    , null as zzslsrce
    , null as zzgovtmatclass
    , null as zzsupply_var_fct
    , null as zzatcostatus
    , null as zz_snp_horiz
    , null as zztarget_dur
    , null as zzctm
    , null as zztarget_method
    , null as zzplanner_pps
    , null as zzdprex
    , null as zzsprex
    , null as zzrrp_type
    , null as zzheur_id
    , null as zzss_method
    , null as zzconvh
    , null as zzpeg_strategy
    , null as zzpeg_past_max
    , null as zzpeg_future_max
    , null as zzdeldate
    , null as zzfinlbq
    , null as zzwarrantydt
    , null as zzprod_priority
    , null as zzperod_spl_prof
    , null as zzservice_time
    , null as zzplanning_time
    , null as zzfrozen_period
    , null as zziominmaxtype
    , null as zziominssvalue
    , null as zziomaxssvalue
    , null as zziominmaxreason
    , null as zzcovprofequal
    , null as zziooutputcont
    , null as zziosafetystock
    , null as zzriskmitweeks
    , null as zzriskmitstock
    , null as zzmanualssvalue
    , null as zzmanualssreason
    , null as zzionotes
    , null as zzioprodtime
    , null as zzopt
    , null as zzproductionoffset
    , null as zzleadtimeoffset
    , null as gldelflag
    , null as glchangetime_dttm
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from {{ source('bronze_moen_sap', 'z_mara') }} as ma
    inner join cte_bkcc on 1 = 1
where ma.matnr not in (select distinct matnr from cte_marc)
