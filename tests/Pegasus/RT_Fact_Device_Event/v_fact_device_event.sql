SELECT * FROM (
    {{ validity_check(
        'fact_device_event',
        'EVENT',
        'BKCC',
        ["'Leaking_Water'"],
        "NOT IN (1, 4, 0, -2, -1, 3, 2)"
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ validity_check(
        'fact_device_event',
        'EVENT_DESCRIPTION',
        'BKCC',
        ["'Leaking_Water'"],
        "NOT IN ('PAIRED', 'UNKNOWN', 'LEARNING OFF', 'UNPAIRED', 'INSTALLED')"
    ) }}
)
UNION ALL
SELECT * FROM (
    {{ validity_check(
        'fact_device_event',
        'SOURCE',
        'BKCC',
        ["'Leaking_Water'"],
        "NOT IN ('FLO')"
    ) }}
)