{{ config( alias='fact_nps_score') }}
select  *
from {{ ref('fact_nps_score') }}