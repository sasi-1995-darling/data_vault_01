---- SRC LAYER ----
WITH
SRC_SBT            as ( SELECT * FROM {{ ref('stg_planning_buffer_tracking__moen_o8') }} as SRC 
                        {% if is_incremental() %}
                        WHERE src.load_dts > (SELECT DATEADD('MINUTE','-1',MAX(LOAD_DTS)) FROM {{ this }})
                        {% endif %}  )

/*
SRC_SBT            as ( SELECT * FROM staging.stg_planning_buffer_tracking__moen_o8 )
*/
---- LOGIC LAYER ----

, LOGIC_SBT as (
    SELECT
        pls_bk                                                      
      , pls_hk                                                      
      , plsd_bk                                                     
      , plsd_hk                                                     
      , hashdiff                                                    
      , base_part_number                                            
      , location                                                    
      , supplier                                                    
      , buffer_date                                                 
      , _file                                                       
      , _line                                                       
      , _modified                                                   
      , load_dts                                                    
      , date                                                        
      , rule                                                        
      , stock                                                       
      , orders                                                      
      , strat_buffer                                                
      , yellow_zone                                                 
      , red_zone                                                    
      , sys_date                                                    
      , green_zone                                                  
      , brand                                                       
      , rec_src                                                     
    FROM SRC_SBT
)
---- RENAME LAYER ----

, RENAME_SBT as (
    SELECT
        pls_bk
      , pls_hk
      , plsd_bk
      , plsd_hk
      , hashdiff
      , base_part_number
      , location
      , supplier
      , buffer_date
      , _file
      , _line
      , _modified
      , load_dts
      , date
      , rule
      , stock
      , orders
      , strat_buffer
      , yellow_zone
      , red_zone
      , sys_date
      , green_zone
      , brand
      , rec_src
    FROM LOGIC_SBT
)
---- FILTER LAYER ----

, FILTER_SBT as (
    SELECT *
    FROM RENAME_SBT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SBT
)

---- FINAL LAYER ----
SELECT
          PLS_BK
        , PLS_HK
        , PLSD_BK
        , PLSD_HK
        , BASE_PART_NUMBER
        , LOCATION
        , SUPPLIER
        , BUFFER_DATE
        , _FILE
        , _LINE
        , _MODIFIED
        , LOAD_DTS
        , DATE
        , RULE
        , STOCK
        , ORDERS
        , STRAT_BUFFER
        , YELLOW_ZONE
        , RED_ZONE
        , SYS_DATE
        , GREEN_ZONE
        , BRAND
        , REC_SRC
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.plsd_hk = join_result.plsd_hk AND existing.LOAD_DTS = join_result.load_dts
)
{% endif %}