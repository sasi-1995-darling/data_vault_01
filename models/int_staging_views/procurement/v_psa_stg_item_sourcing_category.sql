---- SRC LAYER ----
WITH
SRC_src            as ( SELECT BUSINESS_UNIT, CATEGORY_I, CATEGORY_II, CATEGORY_III, ITEM_MATERIAL_NUMBER, OP_CO, PSA_DELETE_IND, PSA_LOAD_DTS, PSA_RECORD_SOURCE, REQUESTOR, _FILE, _FIVETRAN_SYNCED, _LINE, _MODIFIED FROM {{ source('ff_direct_spend_src_ctg', 'ff_direct_spend_cat_src_incr') }} as SRC 
                        /*
                        The QUALIFY statement keeps only the latest record for each op_co and item.
                        Frequent inserts and deletes in the source CSV files change the _line field, which makes the PSA treat them as new records.
                        Since PSA stores history, we use ROW_NUMBER() (ordered by _fivetran_synced and psa_load_dts descending) to select the most recent version.
                        */
                        qualify  1= row_number() over(partition by upper(op_co), item_material_number order by _fivetran_synced desc, psa_load_dts desc) ),
SRC_ctg_ldr_xref   as ( SELECT CATEGORY_I, CATEGORY_II, CATEGORY_III, DIRECTOR, NEW_CATEGORY_OWNER FROM {{ source('ff_direct_spend_src_ctg', 'ff_item_src_cat_leader_xref') }} as SRC 
                        qualify 1= row_number() over(partition by hash(category_i, category_ii, category_iii) order by _fivetran_synced desc) ),
SRC_xref         as ( SELECT EMAIL, NAME FROM {{ source('ff_direct_spend_src_ctg', 'ff_direct_spend_email_name_xref') }} as SRC 
                        qualify 1= row_number() over(partition by email order by _fivetran_synced desc) )

/*
SRC_src            as ( SELECT * FROM ff_direct_spend_src_ctg.ff_direct_spend_cat_src_incr )
SRC_ctg_ldr_xref   as ( SELECT * FROM ff_direct_spend_src_ctg.ff_item_src_cat_leader_xref )
SRC_xref_d         as ( SELECT * FROM ff_direct_spend_src_ctg.ff_direct_spend_email_name_xref )
*/
---- LOGIC LAYER ----

, LOGIC_src as (
    SELECT
        OP_CO
      , ITEM_MATERIAL_NUMBER                                         as                                               ITEM
      , REQUESTOR                                                    as                                    REQUESTOR_EMAIL
      , CATEGORY_I                                                   as                                    FBIN_CATEGORY_I
      , CATEGORY_II                                                  as                                   FBIN_CATEGORY_II
      , CATEGORY_III                                                 as                                  FBIN_CATEGORY_III
      , BUSINESS_UNIT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _FILE
      , _LINE+2                                                      as                                              _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , CONVERT_TIMEZONE('UTC', _FIVETRAN_SYNCED)                    as                                           LOAD_DTS
      , HASH(FBIN_CATEGORY_I, FBIN_CATEGORY_II, FBIN_CATEGORY_III)   as                                           CAT_HASH
      , _LINE                                                        as                                           SRC_LINE
    FROM SRC_src
)

, LOGIC_ctg_ldr_xref as (
    SELECT
        DIRECTOR                                                     as                                     DIRECTOR_EMAIL
      , NEW_CATEGORY_OWNER                                           as                              CATEGORY_LEADER_EMAIL
      , HASH(CATEGORY_I, CATEGORY_II, CATEGORY_III)                  as                              CTG_LDR_XREF_CAT_HASH
      , CATEGORY_I
      , CATEGORY_II
      , CATEGORY_III
    FROM SRC_ctg_ldr_xref
)

, LOGIC_xref as (
    SELECT
        COALESCE(NAME, 'UPDATE CROSS REFERENCE')                     as                                      NAME
      , EMAIL                                                        as                                      EMAIL
    FROM SRC_xref
)

---- RENAME LAYER ----

, RENAME_src as (
    SELECT
        OP_CO
      , ITEM
      , REQUESTOR_EMAIL
      , FBIN_CATEGORY_I
      , FBIN_CATEGORY_II
      , FBIN_CATEGORY_III
      , BUSINESS_UNIT
      , PSA_LOAD_DTS
      , PSA_RECORD_SOURCE
      , PSA_DELETE_IND
      , _FILE
      , _LINE
      , _MODIFIED
      , _FIVETRAN_SYNCED
      , LOAD_DTS
      , CAT_HASH
      , SRC_LINE
    FROM LOGIC_src
)

, RENAME_ctg_ldr_xref as (
    SELECT
        DIRECTOR_EMAIL
      , CATEGORY_LEADER_EMAIL
      , CTG_LDR_XREF_CAT_HASH
      , CATEGORY_I
      , CATEGORY_II
      , CATEGORY_III
    FROM LOGIC_ctg_ldr_xref
)

, RENAME_xref as (
    SELECT
        NAME
      , EMAIL
    FROM LOGIC_xref
)

---- FILTER LAYER ----

, FILTER_src as (
    SELECT *
    FROM RENAME_src
)

, FILTER_ctg_ldr_xref as (
    SELECT *
    FROM RENAME_ctg_ldr_xref
)

, FILTER_xref as (
    SELECT *
    FROM RENAME_xref
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *, COALESCE(FILTER_xref_d.name, 'UPDATE CROSS REFERENCE') as DIRECTOR_NAME, COALESCE(FILTER_xref_c.name, 'UPDATE CROSS REFERENCE') as CATEGORY_LEADER_NAME
    FROM FILTER_src
    LEFT JOIN FILTER_ctg_ldr_xref
        ON FILTER_src.cat_hash = ctg_ldr_xref_cat_hash
    LEFT JOIN FILTER_xref as FILTER_xref_d  ON FILTER_ctg_ldr_xref.director_email = FILTER_xref_d.email
    LEFT JOIN FILTER_xref as FILTER_xref_c ON FILTER_ctg_ldr_xref.category_leader_email = FILTER_xref_c.email
)

---- FINAL LAYER ----
SELECT
          OP_CO
        , ITEM
        , REQUESTOR_EMAIL
        , DIRECTOR_EMAIL
        , DIRECTOR_NAME
        , CATEGORY_LEADER_EMAIL
        , CATEGORY_LEADER_NAME
        , FBIN_CATEGORY_I
        , FBIN_CATEGORY_II
        , FBIN_CATEGORY_III
        , BUSINESS_UNIT
        , PSA_LOAD_DTS
        , PSA_RECORD_SOURCE
        , PSA_DELETE_IND
        , _FILE
        , _LINE
        , _MODIFIED
        , _FIVETRAN_SYNCED
        , LOAD_DTS
FROM JOIN_RESULT
