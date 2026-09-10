select * from ({{ primary_key_check('dim_promotion',['DIM_PROMOTION_KEY']) }})
UNION ALL
select * from ({{ primary_key_check('dim_promotion',['BASE_MATERIAL_BK','PROMOTION_ID','PROMOTION_BK','KEY_ACCOUNT_GROUP_BK','PROMOTION_START_DATE_KEY','PROMOTION_END_DATE_KEY']) }})
