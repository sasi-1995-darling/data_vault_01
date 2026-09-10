---- SRC LAYER ----
WITH
SRC AS (
    SELECT
        MOEN_ORDER_NK,
        PSA_DELETE_IND
    FROM {{ ref('v_psa_stg_frontdoor_problem_orders_masking') }}
)

---- LOGIC LAYER ----

, LOGIC AS (
    SELECT
        MOEN_ORDER_NK
    FROM SRC
    WHERE COALESCE(PSA_DELETE_IND, 'N') = 'N'
)

---- FINAL LAYER ----
SELECT
    MOEN_ORDER_NK
FROM LOGIC
