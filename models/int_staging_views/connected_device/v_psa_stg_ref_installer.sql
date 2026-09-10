---- SRC LAYER ----
WITH
SRC_src            AS ( SELECT * FROM {{ source('reference', 'ref_installer') }} AS SRC
                        QUALIFY ROW_NUMBER() OVER (PARTITION BY INSTALLER_YA_TAG ORDER BY PSA_LOAD_DTS DESC) = 1 ),
SRC_BKCC           AS ( SELECT BKCC, REC_SRC FROM {{ ref('ref_business_key_collision') }} AS SRC
                        WHERE REC_SRC = 'US.REFERENCE.REF_INSTALLER' )

---- LOGIC LAYER ----

, LOGIC_src AS (
    SELECT
        INSTALLER_YA_TAG,
        INSTALLER_NAME,
        CONVERT_TIMEZONE('UTC', PSA_LOAD_DTS) AS LOAD_DTS,
        PSA_RECORD_SOURCE,
        PSA_DELETE_IND
    FROM SRC_src
)

---- JOIN LAYER ----

, JOIN_RESULT AS (
    SELECT
        LOGIC_src.*,
        SRC_BKCC.BKCC,
        SRC_BKCC.REC_SRC
    FROM LOGIC_src
    INNER JOIN SRC_BKCC
        ON '1' = '1'
)

---- FINAL LAYER ----
SELECT *
FROM JOIN_RESULT
