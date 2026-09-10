    select * from ({{ data_exist('fact_app_user_engagement_event','US.ANDROID_MOEN.SCREENS')}}) 
    union all
    select * from ({{ data_exist('fact_app_user_engagement_event','US.IOS_MOEN.TRACKS')}}) 
    union all
    select * from ({{ data_exist('fact_app_user_engagement_event','US.IOS_MOEN.SCREENS')}}) 
    union all
    select * from ({{ data_exist('fact_app_user_engagement_event','US.ANDROID_MOEN.TRACKS')}}) 