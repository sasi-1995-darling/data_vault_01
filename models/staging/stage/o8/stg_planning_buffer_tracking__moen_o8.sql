
{{
  config(
    materialized='incremental', 
    incremental_strategy='append',
    incremental_predicates = [
      "DBT_INTERNAL_DEST.LOAD_DTS >= dateadd(day, -7, current_date)"
    ]
  )
}}

---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT * FROM {{ source('o8__winn', 'part_buffer_tracking') }} as SRC 
                        where base_part_number<> 'FLOW'
                        {% if is_incremental() %}
                        and src._fivetran_synced > (select dateadd('minute','-1',max(load_dts)) from {{ this }})
                        {% endif %} )

/*
SRC_PB             as ( SELECT * FROM o8__winn.part_buffer_tracking )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        _file                                                       
      , _line                                                       
      , _modified                                                   
      , _fivetran_synced                                             as                                           load_dts
      , base_part_number                                            
      , location                                                    
      , date                                                        
      , rule                                                        
      , stock                                                       
      , orders                                                      
      , strat_buffer                                                
      , yellow_zone                                                 
      , red_zone                                                    
      , supplier                                                    
      , sys_date                                                    
      , green_zone                                                  
      , try_to_date(sys_date,'dd-mm-yyyy')                                  as                                        buffer_date
      , '!MOEN'                                                      as                                              brand
      , '!O8'                                                        as                                            rec_src
      , CONCAT_WS('||',
            COALESCE(base_part_number::TEXT, ''),
            COALESCE(location::TEXT, ''),
            COALESCE(supplier::TEXT, '')
        )                                                            as                                             pls_bk
      , CAST(MD5_BINARY(NULLIF(CONCAT(IFNULL(NULLIF(UPPER(TRIM(CAST(pls_bk AS VARCHAR))), ''), '^^'), '||',IFNULL(NULLIF(UPPER(TRIM(CAST(brand AS VARCHAR))), ''), '^^')), '^^||^^')) AS BINARY(16)) as                                             pls_hk
      , CONCAT_WS('||',
            COALESCE(base_part_number::TEXT, ''),
            COALESCE(location::TEXT, ''),
            COALESCE(supplier::TEXT, ''),
            COALESCE(date::TEXT, '')
        )                                                            as                                            plsd_bk
      , CAST(MD5_BINARY(NULLIF(CONCAT(IFNULL(NULLIF(UPPER(TRIM(CAST(plsd_bk AS VARCHAR))), ''), '^^'), '||',IFNULL(NULLIF(UPPER(TRIM(CAST(brand AS VARCHAR))), ''), '^^')), '^^||^^')) AS BINARY(16)) as                                            plsd_hk
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        _file
      , _line
      , _modified
      , load_dts
      , base_part_number
      , location
      , date
      , rule
      , stock
      , orders
      , strat_buffer
      , yellow_zone
      , red_zone
      , supplier
      , sys_date
      , green_zone
      , buffer_date
      , brand
      , rec_src
      , pls_bk
      , pls_hk
      , plsd_bk
      , plsd_hk
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
)

---- FINAL LAYER ----
SELECT
          _FILE
        , _LINE
        , _MODIFIED
        , LOAD_DTS
        , BASE_PART_NUMBER
        , LOCATION
        , DATE
        , RULE
        , STOCK
        , ORDERS
        , STRAT_BUFFER
        , YELLOW_ZONE
        , RED_ZONE
        , SUPPLIER
        , SYS_DATE
        , GREEN_ZONE
        , BUFFER_DATE
        , BRAND
        , REC_SRC
        , PLS_BK
        , PLS_HK
        , PLSD_BK
        , PLSD_HK
        , CAST(MD5_BINARY(NULLIF(CONCAT(
              
            IFNULL(NULLIF(UPPER(TRIM(_FILE::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(_LINE::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(_MODIFIED::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(BASE_PART_NUMBER::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(LOCATION::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(DATE::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(RULE::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(STOCK::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(ORDERS::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(STRAT_BUFFER::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(YELLOW_ZONE::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(RED_ZONE::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(SUPPLIER::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(SYS_DATE::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(GREEN_ZONE::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(BUFFER_DATE::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(BRAND::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(REC_SRC::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PLS_BK::text)), ''), '^^')  , '||', IFNULL(NULLIF(UPPER(TRIM(PLS_HK::text)), ''), '^^') 
          ), '^^||^^')) AS BINARY(16)) as HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
where not exists (
select 1 
   from {{ this }} existing
  where existing._file = join_result._file and existing.pls_bk = join_result.pls_bk and existing.load_dts = join_result.load_dts
    )
    {% endif %}