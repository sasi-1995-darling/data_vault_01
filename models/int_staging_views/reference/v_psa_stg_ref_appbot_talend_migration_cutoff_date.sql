{{ config(materialized='ephemeral') }}
SELECT DATE '2026-01-31' AS CUTOFF_DT --Appbot Talend will be on or before this date. Any data from Fivetran would start on Feb 1st 2026