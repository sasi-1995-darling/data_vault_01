    select * from ({{ data_exist('sat_paired_device__flo_dynamodb','US.FLO_DYNAMODB.PROD_ICD')}}) 
    union all
    select * from ({{ data_exist('sat_device_location_details__flo_dynamodb','US.FLO_DYNAMODB.PROD_LOCATION')}}) 
    union all
    select * from ({{ data_exist('sat_paired_device_event__flo_dynamodb','US.FLO_DYNAMODB.PROD_ONBOARDING_LOG')}}) 
    union all
    select * from ({{ data_exist('lnk_paired_device_location','US.FLO_DYNAMODB.PROD_ICD')}})
    union all
    select * from ({{ data_exist('hub_device_location','US.FLO_DYNAMODB.PROD_LOCATION')}})
    union all
    select * from ({{ data_exist('hub_device_v2','US.FLO_PG_DEVICE_SERVICE.DEVICES')}})
    union all
    select * from ({{ data_exist('hub_device_v2','US.DATA_PROD_DEVICE_INVENTORY_PUBLIC.DEVICE_INFO')}})
    union all
    select * from ({{ data_exist('hub_device_v2','US.FLO_TELEMETRY.FLODETECT_EVENTS_DEVICE_DAILY_AGG')}})
    union all
    select * from ({{ data_exist('hub_device_v2','US.FLO_TELEMETRY.FLO_DEVICE_DAILY')}})
    union all
    select * from ({{ data_exist('hub_paired_device','US.FLO_DYNAMODB.PROD_ICD')}})
    union all
    select * from ({{ data_exist('lnk_icd_device','US.FLO_DYNAMODB.PROD_ICD')}})
    union all
    select * from ({{ data_exist('hub_device_account','US.FLO_DYNAMODB.PROD_ACCOUNT') }})
    union all
    select * from ({{ data_exist('sat_device_account_details__flo_dynamodb','US.FLO_DYNAMODB.PROD_ACCOUNT') }})
    union all
    select * from ({{ data_exist('sat_device_account_subscription__flo_dynamodb','US.FLO_DYNAMODB.PROD_ACCOUNT_SUBSCRIPTION') }})
    union all
    select * from ({{ data_exist('sat_device_location_subscription__flo_dynamodb','US.FLO_DYNAMODB.PROD_SUBSCRIPTION') }})
    union all
    select * from ({{ data_exist('lnk_device_account_location','US.FLO_DYNAMODB.PROD_ACCOUNT_SUBSCRIPTION') }})
    union all
    select * from ({{ data_exist('hub_flo_user','US.FLO_DYNAMODB.PROD_USER') }})
    union all
    select * from ({{ data_exist('sat_flo_user_details__flo_dynamodb','US.FLO_DYNAMODB.PROD_USER') }})
    union all
    select * from ({{ data_exist('sat_flo_user_profile__flo_dynamodb','US.FLO_DYNAMODB.PROD_USER_DETAIL') }})
    union all
    select * from ({{ data_exist('sat_flo_user_account_group_role__flo_dynamodb','US.FLO_DYNAMODB.PROD_USER_ACCOUNT_GROUP_ROLE') }})
    union all
    select * from ({{ data_exist('lnk_user_account_role','US.FLO_DYNAMODB.PROD_USER_ACCOUNT_ROLE') }})
    union all
    select * from ({{ data_exist('lnk_user_location_role','US.FLO_DYNAMODB.PROD_USER_LOCATION_ROLE') }})
    union all
    select * from ({{ data_exist('sat_device_status__flo_service','US.FLO_PG_DEVICE_SERVICE.DEVICES') }})
    union all
    select * from ({{ data_exist('msat_flow_daily_agg__flodetect','US.FLO_TELEMETRY.FLODETECT_EVENTS_DEVICE_DAILY_AGG') }})