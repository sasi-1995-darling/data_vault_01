with 
brand_group as (
  select r.*
        , (case r.source
            when 'US WINN' then 1
            when 'US SECURITY' then 2
            when 'US THERMATRU' then 3
            when 'US LARSON' then 4
            when 'US FIBERON' then 5
            when 'US FYPON' then 6
            else 7
        end ) as source_priority -- rank the priority order of sources to pick from in case there are multiple sources for the same id
        , row_number() over (partition by 
                                        id
                                        , source
                            order by updated_at desc
                            ) as rn -- only get the latest record from the same source
  from {{ source('profitero__rr', 'brands') }} as r
),
latest_brand_group as (
    select 
        r.*
        , row_number() over (partition by 
                                        id
                            order by source_priority
                            ) as priority
    from brand_group r
    where rn=1
),
brand_priority as (
    select 
        r.*
    from latest_brand_group r
    where priority=1 -- pick the highest in priority order of sources
)
select * from brand_priority