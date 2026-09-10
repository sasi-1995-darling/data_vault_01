with cte_ce1new4 as (
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
        , mandt --'Client'__copa sales hk
        , paledger --'Currency type for an operating concern'__copa sales hk
        , vrgar --'Record Type'__copa sales hk
        , versi --'Plan version (CO-PA)'__copa sales hk
        , perio --'Period/year'__copa sales hk
        , paobjnr --'Profitability Segment Number (CO-PA)'__copa sales hk
        , pasubnr --'Profitability Segment Changes (CO-PA)'__copa sales hk
        , belnr --'Document number of line item in Profitability Analysis'__copa sales hk
        , trim(posnr) as posnr --'Item no. of CO-PA line item'__copa sales hk
    from {{ source("bronze_moen_sap", "z_ce1new4") }}
)

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

select * from cte_azcopa where budat < '2023-12-31'
union
select * from cte_ce1new4 where budat >= '2023-12-31'
