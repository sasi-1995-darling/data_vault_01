with cte_s600 as (
    select * from {{ source('bronze_moen_sap', 'z_zdw_s600') }} where try_to_date(sptag, 'YYYYMMDD') >= '2024-04-20'
    union all
    select * from {{ source('bronze_moen_sap_bw', 'azinput') }} where to_date(sptag) < '2024-04-20'
)

select
    cte_s600.kunnr --'Sold-To Party'__shipment input hk
    , to_char(cte_s600.matnr) as matnr --'Material Number'__shipment input hk
    , cte_s600.werks --'Plant'__shipment input hk
    , coalesce(
        try_to_date(cte_s600.erdat, 'YYYYMMDD'), try_to_date(cte_s600.erdat, 'YYYY-MM-DD')
    ) as erdat
    , coalesce(
        to_char(try_to_date(cte_s600.wadat, 'YYYYMMDD')), to_char(try_to_date(cte_s600.wadat, 'YYYY-MM-DD')),''
    ) as wadat --'Goods Issue Date'__shipment input hk
    , cte_s600.vbeln --'Sales Document'__shipment input hk
    , trim(cte_s600.posnr) as posnr --'Sales Document Item'__shipment input hk
    , cte_s600.auart --'Sales Document Type'__shipment input hk
    , nvl(cte_s600.abgru,'') as abgru --'Reason for rejection of quotations and sales orders'__shipment input hk
    , cte_s600.vrkme
    , cte_s600.waerk
    , cte_s600.kwmeng
    , cte_s600.zout_qty
    , cte_s600.netwr
    , cte_s600.z532_kwert
    , cte_s600.zout_dol
    , cte_s600.vkorg
    , cte_s600.vtweg
    , cte_s600.spart
    , cte_s600.pstyv
    , cte_s600.bstnk
    , cte_s600.zzorc
    , cte_s600.wwrsn
    , cte_s600.wwstp
    , cte_s600.mandt --'Client'__shipment input hk
    , nvl(cte_s600.ssour,'') as ssour --'Statistic(s) origin'__shipment input hk
    , cte_s600.vrsio --'Version number in the information structure'__shipment input hk
    , cte_s600.spmon --'Period to analyze - month'__shipment input hk
    , coalesce(
        try_to_date(cte_s600.sptag, 'YYYYMMDD'), try_to_date(cte_s600.sptag, 'YYYY-MM-DD')
    ) as sptag --'Period to analyze - current date'__shipment input hk
    , cte_s600.spwoc --'Period to analyze - week'__shipment input hk
    , cte_s600.spbup --'Period to analyze - posting period'__shipment input hk
    , cte_s600.stwae_01 --'Statistics currency'__shipment input hk
from cte_s600
