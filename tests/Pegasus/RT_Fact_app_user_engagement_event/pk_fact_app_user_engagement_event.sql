select * from ({{ primary_key_check('fact_app_user_engagement_event',['CONSUMER_BK','EVENT', 'EVENT_TRACKING_ID','EVENT_TRAIT_ID','PLATFORM']) }}) 
