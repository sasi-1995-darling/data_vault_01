{{ config(materialized='ephemeral') }}
select date '2026-03-28' as cutoff_dt --Saturday as condition is based of the report_end_date which goes well with Inventory weekly report Sun-Sat