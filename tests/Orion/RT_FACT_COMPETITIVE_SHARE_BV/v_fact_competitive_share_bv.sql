select *
from (
    {{
        validity_check(
            'fact_competitive_share_weekly',
            'DATE',
            'SOURCE',
            ["'PROFITERO'","'DATAVATIONS'"],
            "NOT BETWEEN DATE '1899-01-01' AND DATE '2100-12-31'"
        )
    }}
)
