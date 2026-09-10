select * from ({{ primary_key_check('fact_promotion_effectiveness',['LNK_ACCOUNT_BASE_MATERIAL_PROMOTION_HK','PROMOTION_ID','PROMOTION_START_DATE_KEY','PROMOTION_END_DATE_KEY']) }})
UNION ALL
select * from ({{ primary_key_check('fact_promotion_effectiveness',['BASE_MATERIAL_BK','PROMOTION_ID','PROMOTION_BK','KEY_ACCOUNT_GROUP_BK','PROMOTION_START_DATE_KEY','PROMOTION_END_DATE_KEY']) }})
