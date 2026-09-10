---- SRC LAYER ----
WITH
SRC_H              as ( SELECT * FROM {{ ref('hub_co_activity_type') }} as SRC  ),
SRC_SAT_WINN       as ( SELECT * FROM {{ ref('sat_co_activity_type__winn_sap') }} as SRC 
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY CO_ACTIVITY_TYPE_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_H              as ( SELECT * FROM RAW_VAULT.HUB_CO_ACTIVITY_TYPE )
, SRC_SAT_WINN       as ( SELECT * FROM RAW_VAULT.SAT_CO_ACTIVITY_TYPE__WINN_SAP )
*/
---- LOGIC LAYER ----

, LOGIC_H as (
    SELECT
        'PIT_GL_ACTIVITY_TYPE'                                       as                                        PIT_REC_SRC
      , CURRENT_DATE                                                 as                                       SNAPSHOTDATE
      , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as                                       PIT_LOAD_DTS
      , CO_ACTIVITY_TYPE_HK
	  , ACTIVITY_TYPE_BK
      , VALID_DATE_BK
      , CONTROLLING_AREA_BK
      , BKCC
      , REC_SRC
    FROM SRC_H
)

, LOGIC_SAT_WINN as (
	SELECT
		DATBI
		, DATAB
		, LEINH
		, LATYP
		, ERSDA
		, USNAM
		, AUSEH
		, AUSFK
		, VKSTA
		, SPRKZ
		, HRKFT
		, TARKZ
		, YRATE
		, TARKZ_I
		, CO_ACTIVITY_TYPE_HK                           
		, PSA_DELETE_IND
		, REC_SRC 
    FROM SRC_SAT_WINN
)
---- RENAME LAYER ----

, RENAME_H as (
    SELECT
        PIT_REC_SRC
      , SNAPSHOTDATE
      , PIT_LOAD_DTS
      , CO_ACTIVITY_TYPE_HK													 as													GL_ACTIVITY_TYPE_HK
	  , ACTIVITY_TYPE_BK
      , CAST(VALID_DATE_BK AS INTEGER)									     as											       VALID_DATE__YYYYMMDD
      , CONTROLLING_AREA_BK														
      , BKCC
      , REC_SRC																 as														    HUB_REC_SRC
    FROM LOGIC_H
)

, RENAME_SAT_WINN as (
    SELECT
      CO_ACTIVITY_TYPE_HK													 as											    SAT_GL_ACTIVITY_TYPE_HK
				, CAST(DATBI AS INTEGER)                                     as                                		        VALID_TO_DATE__YYYYMMDD
				, CAST(DATAB AS INTEGER)                                     as                                		      VALID_FROM_DATE__YYYYMMDD
				, LEINH                                                      as                                					 	  ACTIVITY_UNIT
				, LATYP                                                      as                                					  ACTIVITY_CATEGORY
				, CAST(ERSDA AS INTEGER)                                     as                                				  CREATE_DATE__YYYYMMDD
				, USNAM                                                      as                                							 ENTERED_BY
				, AUSEH                                                      as                                						    OUTPUT_UNIT
				, AUSFK                                                      as                                						  OUTPUT_FACTOR
				, VKSTA                                                      as                                				     ALLOCATION_ELEMENT
				, SPRKZ                                                      as                                					          LOCK_FLAG
				, HRKFT                                                      as                                						   ORIGIN_GROUP
				, TARKZ                                                      as                                			       ALLOCATION_PRICE_IND
				, YRATE                                                      as                                		          PRICE_CALCULATION_IND
				, TARKZ_I                                                    as                                	            ACTUAL_PRICE_ALLOCATION                        
				, PSA_DELETE_IND
				, REC_SRC													 as														    SAT_REC_SRC  
    FROM LOGIC_SAT_WINN
)
---- FILTER LAYER ----

, FILTER_H as (
    SELECT *
    FROM RENAME_H
    WHERE HUB_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT_WINN as (
    SELECT *
    FROM RENAME_SAT_WINN
		WHERE SAT_REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_H
    LEFT JOIN FILTER_SAT_WINN
        ON FILTER_SAT_WINN.SAT_GL_ACTIVITY_TYPE_HK = FILTER_H.GL_ACTIVITY_TYPE_HK
)

---- FINAL LAYER ----
SELECT
		GL_ACTIVITY_TYPE_HK
		, CONTROLLING_AREA_BK
		, ACTIVITY_TYPE_BK
		, VALID_DATE__YYYYMMDD
		, VALID_TO_DATE__YYYYMMDD
		, VALID_FROM_DATE__YYYYMMDD
		, ACTIVITY_UNIT
		, ACTIVITY_CATEGORY
		, CREATE_DATE__YYYYMMDD
		, ENTERED_BY
		, OUTPUT_UNIT
		, OUTPUT_FACTOR
		, ALLOCATION_ELEMENT
		, LOCK_FLAG
		, ORIGIN_GROUP
		, ALLOCATION_PRICE_IND
		, PRICE_CALCULATION_IND
		, ACTUAL_PRICE_ALLOCATION
		, PSA_DELETE_IND
		, SAT_REC_SRC
        , BKCC
        , COALESCE(SAT_REC_SRC, HUB_REC_SRC) as REC_SRC
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND END as IS_DELETED
FROM JOIN_RESULT
