with 
cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'USOHNO.SAP_BW.AZ_COPA')
, cte_azcopa as (
    select
        kaufn
        , kdpos
        , try_to_date(wadat, 'YYYYMMDD') as wadat
        , try_to_date(fadat, 'YYYYMMDD') as fadat
        , try_to_date(budat, 'YYYYMMDD') as budat
        , kndnr
        , artnr
        , vvqty
        , vvcrl
        , vvgbp
        , vvgrs
        , vvcjp
        , vvsip
        , vvacq
        , vvfrc
        , vvrst
        , vvhdl
        , vvvpp
        , vvces
        , vvfrm
        , vvfra
        , vvmin
        , vvdip
        , vvoip
        , wwknu
        , wwstp
        , wwrsn
        , vvvlr
        , vvcop
        , vvcst
        , vvotc
        , vvnsa
        , vvcmg
        , vvqty_me
        , wwpsr
        , vkorg
        , vtweg
        , spart
        , vkbur
        , bzirk
        , werks
        , rec_waers
        , mandt
        , paledger
        , vrgar
        , versi
        , perio
        , paobjnr
        , pasubnr
        , belnr
        , trim(posnr) as posnr
    from {{ source("bronze_moen_sap_bw", "azcopa") }}
)

select 
cte_azcopa.* 
, cte_bkcc.rec_src
, cte_bkcc.bkcc
from cte_azcopa 
inner join cte_bkcc on 1=1
where budat < '2023-12-31'
