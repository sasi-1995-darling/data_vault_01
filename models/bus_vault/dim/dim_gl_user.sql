---- SRC LAYER ----
WITH
SRC_PIT            as ( SELECT USER_NAME_HK, CLIENT, USER_NAME, FIRST_NAME, SECOND_NAME, REC_SRC, BKCC, IS_DELETED 
                        FROM {{ ref('pit_gl_user') }} as SRC  )

/*
SRC_PIT            as ( SELECT * FROM BUS_VAULT.PIT_GL_USER )
*/
---- LOGIC LAYER ----

, LOGIC_PIT as (
    SELECT
        USER_NAME_HK
      , CLIENT
      , USER_NAME
      , FIRST_NAME
      , SECOND_NAME
      , REC_SRC
      , BKCC
      , IS_DELETED
    FROM SRC_PIT
)
---- RENAME LAYER ----

, RENAME_PIT as (
    SELECT
        USER_NAME_HK
      , CLIENT
      , USER_NAME
      , FIRST_NAME
      , SECOND_NAME
      , REC_SRC
      , BKCC
      , IS_DELETED
    FROM LOGIC_PIT
)
---- FILTER LAYER ----

, FILTER_PIT as (
    SELECT *
    FROM RENAME_PIT
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PIT
)

---- FINAL LAYER ----
SELECT
        USER_NAME_HK
      , CLIENT
      , USER_NAME
      , FIRST_NAME
      , SECOND_NAME
      , REC_SRC
      , BKCC
      , IS_DELETED
FROM JOIN_RESULT
