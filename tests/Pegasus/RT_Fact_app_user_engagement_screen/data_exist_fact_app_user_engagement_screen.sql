    select * from ({{ data_exist('fact_app_user_engagement_screen','US.ANDROID_MOEN.SCREENS')}}) 
    union all
    select * from ({{ data_exist('fact_app_user_engagement_screen','US.IOS_MOEN.TRACKS')}}) 
    union all
    select * from ({{ data_exist('fact_app_user_engagement_screen','US.IOS_MOEN.SCREENS')}}) 
    union all
    select * from ({{ data_exist('fact_app_user_engagement_screen','US.ANDROID_MOEN.TRACKS')}}) 
