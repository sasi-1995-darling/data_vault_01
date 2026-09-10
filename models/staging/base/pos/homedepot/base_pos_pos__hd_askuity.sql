select * from {{ source('homedepot_pos_askuity', 'hd_askuity_pos') }}
where home_depot_account like any ('Masterlock', 'Moen%','Larson','SentrySafe')
    and sales is not null