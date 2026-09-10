---- SRC LAYER ----
WITH
SRC_HUB            as ( SELECT USER_NAME_HK, USER_NAME_BK, BKCC, REC_SRC  FROM {{ ref('hub_gl_user') }} as SRC  ),
SRC_SAT            as ( SELECT BNAME, KOSTL, LAND1, MANDT, NAME1, NAME2, ORT02, PFACH, PSA_DELETE_IND, PSTL2, PSTLZ, REGIO, ROONR, TEL02, TELPR, TELTX, TELX1, TZONE, USER_NAME_HK 
                        FROM {{ ref('sat_gl_user__winn_sap') }} as SRC
                        QUALIFY 1= ROW_NUMBER() OVER(PARTITION BY USER_NAME_HK ORDER BY LOAD_DTS DESC) )

/*
SRC_HUB            as ( SELECT * FROM RAW_VAULT.hub_gl_user )
SRC_SAT            as ( SELECT * FROM RAW_VAULT.sat_gl_user__winn_sap )
*/
---- LOGIC LAYER ----

, LOGIC_HUB as (
    SELECT
        USER_NAME_HK
      , USER_NAME_BK
      , BKCC
      , REC_SRC
    FROM SRC_HUB
)

, LOGIC_SAT as (
    SELECT
        USER_NAME_HK
      , MANDT                                                        as                                             CLIENT
      , BNAME                                                        as                                          USER_NAME
      , NAME1                                                        as                                         FIRST_NAME
      , NAME2                                                        as                                        SECOND_NAME                                      
      , KOSTL                                                        as                                        COST_CENTER                                  
      , ROONR                                                        as                                        ROOM_NUMBER                           
      , PFACH                                                        as                                             PO_BOX
      , PSTLZ                                                        as                                        POSTAL_CODE                                               
      , REGIO                                                        as                                             REGION
      , LAND1                                                        as                                        COUNTRY_KEY                                       
      , TELPR                                                        as                           TELEPHONE_NUMBER_PRIVATE                                
      , TEL02                                                        as                                 TELEPHONE_NUMBER_2
      , TELX1                                                        as                                       TELEX_NUMBER                                        
      , TELTX                                                        as                                     TELETEX_NUMBER
      , ORT02                                                        as                                           DISTRICT
      , PSTL2                                                        as                               DISTRICT_POSTAL_CODE
      , TZONE                                                        as                                          TIME_ZONE
      , PSA_DELETE_IND
    FROM SRC_SAT
)
---- RENAME LAYER ----

, RENAME_HUB as (
    SELECT
        USER_NAME_HK
      , USER_NAME_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HUB
)

, RENAME_SAT as (
    SELECT
        USER_NAME_HK                                                 as                                   SAT_USER_NAME_HK
      , CLIENT
      , USER_NAME
      , FIRST_NAME
      , SECOND_NAME
      , COST_CENTER
      , ROOM_NUMBER
      , PO_BOX
      , POSTAL_CODE
      , REGION
      , COUNTRY_KEY
      , TELEPHONE_NUMBER_PRIVATE
      , TELEPHONE_NUMBER_2
      , TELEX_NUMBER
      , TELETEX_NUMBER
      , DISTRICT
      , DISTRICT_POSTAL_CODE
      , TIME_ZONE
      , PSA_DELETE_IND
    FROM LOGIC_SAT
)
---- FILTER LAYER ----

, FILTER_HUB as (
    SELECT *
    FROM RENAME_HUB
    WHERE REC_SRC <> 'USAZET.SNOWFLAKE.FBIN.DERIVED'   /* This filter is to exclude the ghost records */
)

, FILTER_SAT as (
    SELECT *
    FROM RENAME_SAT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HUB
    LEFT JOIN FILTER_SAT
        ON FILTER_HUB.USER_NAME_HK = FILTER_SAT.SAT_USER_NAME_HK
)

---- FINAL LAYER ----
SELECT
          'PIT_GL_USER'                                                as PIT_REC_SRC
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , USER_NAME_HK
        , USER_NAME_BK
        , BKCC
        , REC_SRC
        , CLIENT
        , USER_NAME
        , FIRST_NAME
        , SECOND_NAME
        , COST_CENTER
        , ROOM_NUMBER
        , PO_BOX
        , POSTAL_CODE
        , REGION
        , COUNTRY_KEY
        , TELEPHONE_NUMBER_PRIVATE
        , TELEPHONE_NUMBER_2
        , TELEX_NUMBER
        , TELETEX_NUMBER
        , DISTRICT
        , DISTRICT_POSTAL_CODE
        , TIME_ZONE
        , CASE BKCC WHEN 'Hiding_Tiger' THEN PSA_DELETE_IND
          END as IS_DELETED
FROM JOIN_RESULT
