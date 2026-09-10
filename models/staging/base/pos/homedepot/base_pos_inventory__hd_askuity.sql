select * from {{ source('homedepot_pos_askuity', 'hd_askuity_inventory') }}
where home_depot_account like any ('Masterlock', 'Moen%','Larson', 'SentrySafe')
