---- SRC LAYER ----
WITH
SRC_a              AS ( SELECT * FROM {{ ref('v_psa_stg_ref_installer') }} AS SRC )

---- LOGIC LAYER ----

, LOGIC_a AS (
    SELECT
        INSTALLER_YA_TAG,
        INSTALLER_NAME
    FROM SRC_a
    WHERE COALESCE(PSA_DELETE_IND, 'N') = 'N'
)

---- FINAL LAYER ----

SELECT
    INSTALLER_YA_TAG,
    INSTALLER_NAME
FROM LOGIC_a
