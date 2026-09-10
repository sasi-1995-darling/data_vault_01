select * from ({{ data_exist('fact_app_active_user_period','US.ANDROID.TRACKS') }})
union all
select * from ({{ data_exist('fact_app_active_user_period','US.ANDROID_MOEN.TRACKS') }})
union all
select * from ({{ data_exist('fact_app_active_user_period','US.IOS.TRACKS') }})
union all
select * from ({{ data_exist('fact_app_active_user_period','US.IOS_MOEN.TRACKS') }})