---- SRC LAYER ----
WITH
SRC_SPIML          as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__ml_ebs') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SPIMN          as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__moen_sap') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SITMN          as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_item_master__moen_sap') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SPILR          as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__lrsn_psft') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SITMLR         as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_item_master__lrsn_psft') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SPRDLR         as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_item_prod__lrsn_psft') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SITMFB         as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__fib_ocf') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SPITMTTE       as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__tt_e21') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SITMTTE        as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_item_master__tt_e21') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SPITTGP        as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__tt_gp') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SITMTTGP       as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_item_master__tt_gp') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SPIV           as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_item_version__winn_sap') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_BSIPML         as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_bom_structures__ml_ebs') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_CE1NEW4        as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_copa_sales__winn_sap') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_AZCOPA         as ( {% if not is_incremental() %} SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_copa_sales_history__winn_sap') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 {% endif %}
                        {% if is_incremental() %} SELECT * FROM {{ this }} WHERE FALSE {% endif %}
                         /*To improve efficiency and performance; scan and load historical SAP BW AZCOPA table only on initial run */ ),
SRC_ZSERVLEVEL     as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_service_levels__winn_sap') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SPIEMTK        as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_plant_item__emtk_ebs') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SIATTTE        as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_item_attribute__tt_e21') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 ),
SRC_SIATLR         as ( SELECT ITEM_HK, LOAD_DTS, PLANT_HK, PLANT_ITEM_HK, REC_SRC FROM {{ ref('v_psa_stg_item_attribute__lrsn_psft') }} as SRC 
                        QUALIFY ROW_NUMBER() OVER(PARTITION BY PLANT_ITEM_HK ORDER BY LOAD_DTS )=1 )

/*
SRC_SPIML          as ( SELECT * FROM STAGING.v_psa_stg_plant_item__ml_ebs )
SRC_SPIMN          as ( SELECT * FROM STAGING.v_psa_stg_plant_item__moen_sap )
SRC_SITMN          as ( SELECT * FROM STAGING.v_psa_stg_item_master__moen_sap )
SRC_SPILR          as ( SELECT * FROM STAGING.v_psa_stg_plant_item__lrsn_psft )
SRC_SITMLR         as ( SELECT * FROM STAGING.v_psa_stg_item_master__lrsn_psft )
SRC_SPRDLR         as ( SELECT * FROM STAGING.v_psa_stg_item_prod__lrsn_psft )
SRC_SITMFB         as ( SELECT * FROM STAGING.v_psa_stg_plant_item__fib_ocf )
SRC_SPITMTTE       as ( SELECT * FROM STAGING.v_psa_stg_plant_item__tt_e21 )
SRC_SITMTTE        as ( SELECT * FROM STAGING.v_psa_stg_item_master__tt_e21 )
SRC_SPITTGP        as ( SELECT * FROM STAGING.v_psa_stg_plant_item__tt_gp )
SRC_SITMTTGP       as ( SELECT * FROM STAGING.v_psa_stg_item_master__tt_gp )
SRC_SPIV           as ( SELECT * FROM STAGING.v_psa_stg_item_version__winn_sap )
SRC_BSIPML         as ( SELECT * FROM STAGING.v_psa_stg_bom_structures__ml_ebs )
SRC_CE1NEW4        as ( SELECT * FROM STAGING.v_psa_stg_copa_sales__winn_sap )
SRC_AZCOPA         as ( SELECT * FROM STAGING.v_psa_stg_copa_sales_history__winn_sap )
SRC_ZSERVLEVEL     as ( SELECT * FROM STAGING.v_psa_stg_service_levels__winn_sap )
SRC_SPIEMTK        as ( SELECT * FROM STAGING.v_psa_stg_plant_item__emtk_ebs )
SRC_SIATTTE        as ( SELECT * FROM STAGING.v_psa_stg_item_attribute__tt_e21 )
SRC_SIATLR         as ( SELECT * FROM STAGING.v_psa_stg_item_attribute__lrsn_psft )
*/
---- LOGIC LAYER ----

, LOGIC_SPIML as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPIML
)

, LOGIC_SPIMN as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPIMN
)

, LOGIC_SITMN as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMN
)

, LOGIC_SPILR as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPILR
)

, LOGIC_SITMLR as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMLR
)

, LOGIC_SPRDLR as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPRDLR
)

, LOGIC_SITMFB as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMFB
)

, LOGIC_SPITMTTE as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPITMTTE
)

, LOGIC_SITMTTE as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMTTE
)

, LOGIC_SPITTGP as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPITTGP
)

, LOGIC_SITMTTGP as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SITMTTGP
)

, LOGIC_SPIV as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPIV
)

, LOGIC_BSIPML as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_BSIPML
)

, LOGIC_CE1NEW4 as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_CE1NEW4
)

, LOGIC_AZCOPA as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_AZCOPA
)

, LOGIC_ZSERVLEVEL as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_ZSERVLEVEL
)

, LOGIC_SPIEMTK as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SPIEMTK
)

, LOGIC_SIATTTE as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SIATTTE
)

, LOGIC_SIATLR as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM SRC_SIATLR
)
---- RENAME LAYER ----

, RENAME_SPIML as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPIML
)

, RENAME_SPIMN as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPIMN
)

, RENAME_SITMN as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMN
)

, RENAME_SPILR as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPILR
)

, RENAME_SITMLR as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMLR
)

, RENAME_SPRDLR as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPRDLR
)

, RENAME_SITMFB as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMFB
)

, RENAME_SPITMTTE as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPITMTTE
)

, RENAME_SITMTTE as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMTTE
)

, RENAME_SPITTGP as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPITTGP
)

, RENAME_SITMTTGP as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SITMTTGP
)

, RENAME_SPIV as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPIV
)

, RENAME_BSIPML as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_BSIPML
)

, RENAME_CE1NEW4 as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_CE1NEW4
)

, RENAME_AZCOPA as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_AZCOPA
)

, RENAME_ZSERVLEVEL as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_ZSERVLEVEL
)

, RENAME_SPIEMTK as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SPIEMTK
)

, RENAME_SIATTTE as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SIATTTE
)

, RENAME_SIATLR as (
    SELECT
        PLANT_ITEM_HK
      , PLANT_HK
      , ITEM_HK
      , LOAD_DTS
      , REC_SRC
    FROM LOGIC_SIATLR
)
---- FILTER LAYER ----

, FILTER_SPIML as (
    SELECT *
    FROM RENAME_SPIML
)

, FILTER_SPIMN as (
    SELECT *
    FROM RENAME_SPIMN
)

, FILTER_SITMN as (
    SELECT *
    FROM RENAME_SITMN
)

, FILTER_SPILR as (
    SELECT *
    FROM RENAME_SPILR
)

, FILTER_SITMLR as (
    SELECT *
    FROM RENAME_SITMLR
)

, FILTER_SPRDLR as (
    SELECT *
    FROM RENAME_SPRDLR
)

, FILTER_SITMFB as (
    SELECT *
    FROM RENAME_SITMFB
)

, FILTER_SPITMTTE as (
    SELECT *
    FROM RENAME_SPITMTTE
)

, FILTER_SITMTTE as (
    SELECT *
    FROM RENAME_SITMTTE
)

, FILTER_SPITTGP as (
    SELECT *
    FROM RENAME_SPITTGP
)

, FILTER_SITMTTGP as (
    SELECT *
    FROM RENAME_SITMTTGP
)

, FILTER_SPIV as (
    SELECT *
    FROM RENAME_SPIV
)

, FILTER_BSIPML as (
    SELECT *
    FROM RENAME_BSIPML
)

, FILTER_CE1NEW4 as (
    SELECT *
    FROM RENAME_CE1NEW4
)

, FILTER_AZCOPA as (
    SELECT *
    FROM RENAME_AZCOPA
)

, FILTER_ZSERVLEVEL as (
    SELECT *
    FROM RENAME_ZSERVLEVEL
)

, FILTER_SPIEMTK as (
    SELECT *
    FROM RENAME_SPIEMTK
)

, FILTER_SIATTTE as (
    SELECT *
    FROM RENAME_SIATTTE
)

, FILTER_SIATLR as (
    SELECT *
    FROM RENAME_SIATLR
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_SPIML
    UNION ALL
    SELECT * FROM FILTER_SPIMN
    UNION ALL
    SELECT * FROM FILTER_SITMN
    UNION ALL
    SELECT * FROM FILTER_SPILR
    UNION ALL
    SELECT * FROM FILTER_SITMLR
    UNION ALL
    SELECT * FROM FILTER_SPRDLR
    UNION ALL
    SELECT * FROM FILTER_SITMFB
    UNION ALL
    SELECT * FROM FILTER_SPITMTTE
    UNION ALL
    SELECT * FROM FILTER_SITMTTE
    UNION ALL
    SELECT * FROM FILTER_SPITTGP
    UNION ALL
    SELECT * FROM FILTER_SITMTTGP
    UNION ALL
    SELECT * FROM FILTER_SPIV
    UNION ALL
    SELECT * FROM FILTER_BSIPML
    UNION ALL
    SELECT * FROM FILTER_CE1NEW4
    UNION ALL
    SELECT * FROM FILTER_AZCOPA
    UNION ALL
    SELECT * FROM FILTER_ZSERVLEVEL
    UNION ALL
    SELECT * FROM FILTER_SPIEMTK
    UNION ALL
    SELECT * FROM FILTER_SIATTTE
    UNION ALL
    SELECT * FROM FILTER_SIATLR
)

---- FINAL LAYER ----
SELECT
          PLANT_ITEM_HK
        , PLANT_HK
        , ITEM_HK
        , LOAD_DTS
        , REC_SRC
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.PLANT_ITEM_HK = JOIN_RESULT.PLANT_ITEM_HK
)
{% endif %}
/*To select items that do not exist in the plant but exist elsewhere*/
QUALIFY 1= RANK () OVER (PARTITION BY PLANT_ITEM_HK ORDER BY DECODE(REC_SRC, 'USOHMA.ORCL.E21PRD.WHSPRMSTR', 1,'USOHMA.ORCL.E21PRD.PARTMSTR', 2, 'USSDBR.ORCL.PSFTPRD.PS_BU_ITEMS_INV', 3
                                                , 'USSDBR.ORCL.PSFTPRD.PS_MASTER_ITEM_TBL', 4, 'USSDBR.ORCL.PSFTPRD.PS_PROD_ITEM', 5, 'USOHNO.SAP.ECCPRD.Z_MARC', 6, 'USOHNO.SAP.ECCPRD.Z_MARA' , 7
                                                , 'USOHMA.MSSQL.GPPRD.DBO_IV00102', 8, 'USOHMA.MSSQL.GPPRD.DBO_IV00101', 9, 'USWIOC.ORCL.EBSPRD.BOM_STRUCTURES_B', 10, 'USOHNO.SAP.ECCPRD.Z_MKAL', 11 
                                                , 'USOHNO.SAP.ECCPRD.CE1NEW4', 12,  'USOHNO.SAP_BW.AZ_COPA', 13, 'USOHNO.SAP.ECCPRD.Z_ZSERVLEVEL', 14, 'USOHMA.ORCL.E21PRD.INVITEM', 15, 'USSDBR.ORCL.PSFTPRD.PS_PL_ITEM_ATTRIB', 16, 17))
                                                
{% if not is_incremental() %}
union all
SELECT 
MD5_BINARY(GR.VALUE) as PLANT_ITEM_HK
, MD5_BINARY(GR.VALUE) as PLANT_HK
, MD5_BINARY(GR.VALUE) as ITEM_HK
, CONVERT_TIMEZONE('UTC','1900-01-01'::TIMESTAMP)  AS LOAD_DTS
, 'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
FROM
TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}