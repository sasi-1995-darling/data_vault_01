---- SRC LAYER ----
WITH
SRC_SQA            as ( SELECT * FROM {{ ref('v_psa_stg_quality_notifications_items') }} as SRC 
                         {% if is_incremental() %}
                         WHERE SRC.LOAD_DTS > (SELECT DATEADD('HOUR', '-1', MAX(LOAD_DTS)) FROM {{this}})
                         {% endif %}  )

/*
SRC_SQA            as ( SELECT * FROM STAGING.v_psa_stg_quality_notifications_items )
*/
---- LOGIC LAYER ----

, LOGIC_SQA as (
    SELECT
        QUALITY_ISSUE_HK
      , FENUM 
      , QMNUM
      , GLREQUEST
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , FETXT
      , FEKAT
      , FEGRP
      , FECOD
      , FEVER
      , OTKAT
      , OTGRP
      , OTEIL
      , OTVER
      , BAUTL
      , EBORT
      , INDTX
      , KZMLA
      , ERZEIT
      , AEZEIT
      , KZORG
      , WDFEH
      , FEQKLAS
      , FCOAUFNR
      , FMGFRD
      , FMGEIG
      , FMGEIN
      , ANZFEHLER
      , FEHLBEW
      , UNITFLBEW
      , FEART
      , PNLKN
      , MERKNR
      , PROBENR
      , PHYNR
      , PRUEFLINR
      , CROBJTY
      , ARBPL
      , ARBPLWERK
      , FENUMORG
      , KZSYSFE
      , KZLOESCH
      , POSNR
      , HERPOS
      , AUTKZ
      , MATNR
      , WERKS
      , EKORG
      , INFNR
      , KOSTL
      , LSTAR
      , PRZNR
      , MENGE
      , EQUNR
      , TPLNR
      , ZZFAILURE_MODE
      , ZZINSTALLDATE
      , ZZMANUFDATE
      , ZZPAFNO
      , ZZITEMKAT1
      , ZZITEMGRP1
      , ZZITEMCOD1
      , ZZITEMKAT2
      , ZZITEMGRP2
      , ZZITEMCOD2
      , ZZITEMDATE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , HASHDIFF
      , REC_SRC
      , BKCC
      , LOAD_DTS
      , PSA_DELETE_IND       
    FROM SRC_SQA
)
---- RENAME LAYER ----

, RENAME_SQA as (
    SELECT
        QUALITY_ISSUE_HK
        , FENUM 
        , QMNUM
      , GLREQUEST
      , ERNAM
      , ERDAT
      , AENAM
      , AEDAT
      , FETXT
      , FEKAT
      , FEGRP
      , FECOD
      , FEVER
      , OTKAT
      , OTGRP
      , OTEIL
      , OTVER
      , BAUTL
      , EBORT
      , INDTX
      , KZMLA
      , ERZEIT
      , AEZEIT
      , KZORG
      , WDFEH
      , FEQKLAS
      , FCOAUFNR
      , FMGFRD
      , FMGEIG
      , FMGEIN
      , ANZFEHLER
      , FEHLBEW
      , UNITFLBEW
      , FEART
      , PNLKN
      , MERKNR
      , PROBENR
      , PHYNR
      , PRUEFLINR
      , CROBJTY
      , ARBPL
      , ARBPLWERK
      , FENUMORG
      , KZSYSFE
      , KZLOESCH
      , POSNR
      , HERPOS
      , AUTKZ
      , MATNR
      , WERKS
      , EKORG
      , INFNR
      , KOSTL
      , LSTAR
      , PRZNR
      , MENGE
      , EQUNR
      , TPLNR
      , ZZFAILURE_MODE
      , ZZINSTALLDATE
      , ZZMANUFDATE
      , ZZPAFNO
      , ZZITEMKAT1
      , ZZITEMGRP1
      , ZZITEMCOD1
      , ZZITEMKAT2
      , ZZITEMGRP2
      , ZZITEMCOD2
      , ZZITEMDATE
      , GLDELFLAG
      , GLCHANGETIME
      , GLSOURCESYSTEM
      , HASHDIFF
      , REC_SRC
      , BKCC
      , LOAD_DTS
      , PSA_DELETE_IND
    FROM LOGIC_SQA
)
---- FILTER LAYER ----

, FILTER_SQA as (
    SELECT *
    FROM RENAME_SQA
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_SQA
)

---- FINAL LAYER ----
SELECT
          QUALITY_ISSUE_HK
        , FENUM 
        , QMNUM
        , GLREQUEST
        , ERNAM
        , ERDAT
        , AENAM
        , AEDAT
        , FETXT
        , FEKAT
        , FEGRP
        , FECOD
        , FEVER
        , OTKAT
        , OTGRP
        , OTEIL
        , OTVER
        , BAUTL
        , EBORT
        , INDTX
        , KZMLA
        , ERZEIT
        , AEZEIT
        , KZORG
        , WDFEH
        , FEQKLAS
        , FCOAUFNR
        , FMGFRD
        , FMGEIG
        , FMGEIN
        , ANZFEHLER
        , FEHLBEW
        , UNITFLBEW
        , FEART
        , PNLKN
        , MERKNR
        , PROBENR
        , PHYNR
        , PRUEFLINR
        , CROBJTY
        , ARBPL
        , ARBPLWERK
        , FENUMORG
        , KZSYSFE
        , KZLOESCH
        , POSNR
        , HERPOS
        , AUTKZ
        , MATNR
        , WERKS
        , EKORG
        , INFNR
        , KOSTL
        , LSTAR
        , PRZNR
        , MENGE
        , EQUNR
        , TPLNR
        , ZZFAILURE_MODE
        , ZZINSTALLDATE
        , ZZMANUFDATE
        , ZZPAFNO
        , ZZITEMKAT1
        , ZZITEMGRP1
        , ZZITEMCOD1
        , ZZITEMKAT2
        , ZZITEMGRP2
        , ZZITEMCOD2
        , ZZITEMDATE
        , GLDELFLAG
        , GLCHANGETIME
        , GLSOURCESYSTEM
        , LOAD_DTS
        , REC_SRC
        , BKCC
        , PSA_DELETE_IND
        , HASHDIFF
FROM JOIN_RESULT
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 
    FROM {{ this }} existing
    WHERE existing.QUALITY_ISSUE_HK= JOIN_RESULT.QUALITY_ISSUE_HK
    AND existing.HASHDIFF = JOIN_RESULT.HASHDIFF
)
{% endif %} 
{% if not is_incremental() %}
/*the following qualify is to restrict multiple loads of touched records during the initial build. Ex: multiple row per hk, hashdiff */
qualify 1= row_number()over(partition by QUALITY_ISSUE_HK, HASHDIFF order by LOAD_DTS)
union all
    SELECT 
      MD5_BINARY(GR.VALUE) AS QUALITY_ISSUE_HK
    , NULL AS FENUM
    , NULL AS QMNUM
    , NULL AS GLREQUEST
    , NULL AS ERNAM
    , NULL AS ERDAT
    , NULL AS AENAM
    , NULL AS AEDAT
    , NULL AS FETXT
    , NULL AS FEKAT
    , NULL AS FEGRP
    , NULL AS FECOD
    , NULL AS FEVER
    , NULL AS OTKAT
    , NULL AS OTGRP
    , NULL AS OTEIL
    , NULL AS OTVER
    , NULL AS BAUTL
    , NULL AS EBORT
    , NULL AS INDTX
    , NULL AS KZMLA
    , NULL AS ERZEIT
    , NULL AS AEZEIT
    , NULL AS KZORG
    , NULL AS WDFEH
    , NULL AS FEQKLAS
    , NULL AS FCOAUFNR
    , NULL AS FMGFRD
    , NULL AS FMGEIG
    , NULL AS FMGEIN
    , NULL AS ANZFEHLER
    , NULL AS FEHLBEW
    , NULL AS UNITFLBEW
    , NULL AS FEART
    , NULL AS PNLKN
    , NULL AS MERKNR
    , NULL AS PROBENR
    , NULL AS PHYNR
    , NULL AS PRUEFLINR
    , NULL AS CROBJTY
    , NULL AS ARBPL
    , NULL AS ARBPLWERK
    , NULL AS FENUMORG
    , NULL AS KZSYSFE
    , NULL AS KZLOESCH
    , NULL AS POSNR
    , NULL AS HERPOS
    , NULL AS AUTKZ
    , NULL AS MATNR
    , NULL AS WERKS
    , NULL AS EKORG
    , NULL AS INFNR
    , NULL AS KOSTL
    , NULL AS LSTAR
    , NULL AS PRZNR
    , NULL AS MENGE
    , NULL AS EQUNR
    , NULL AS TPLNR
    , NULL AS ZZFAILURE_MODE
    , NULL AS ZZINSTALLDATE
    , NULL AS ZZMANUFDATE
    , NULL AS ZZPAFNO
    , NULL AS ZZITEMKAT1
    , NULL AS ZZITEMGRP1
    , NULL AS ZZITEMCOD1
    , NULL AS ZZITEMKAT2
    , NULL AS ZZITEMGRP2
    , NULL AS ZZITEMCOD2
    , NULL AS ZZITEMDATE
    , NULL AS GLDELFLAG
    , NULL AS GLCHANGETIME
    , NULL AS GLSOURCESYSTEM
    , CONVERT_TIMEZONE('UTC','1900-01-01') AS LOAD_DTS
    ,'USAZET.SNOWFLAKE.FBIN.DERIVED' AS REC_SRC
    , DECODE(GR.VALUE, 0, 'GHOST RECORD-SYSTEM', -1, 'GHOST RECORD-nullkey-required', -2, 'GHOST RECORD-nullkey-optional') AS BKCC
    , NULL AS PSA_DELETE_IND
    , ''::BINARY as HASHDIFF FROM TABLE(strtok_split_to_table('0|-1|-2', '|')) AS GR
{% endif %}