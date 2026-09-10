select * from ({{ data_exist('hub_sns_category','US.PROFITERO_WINN.SALES') }})
union all
select * from ({{ data_exist('hub_sns_category','US.PROFITERO_SHARE_MOEN.DIM_AMZ_CATEGORY') }})
union all
select * from ({{ data_exist('hub_sns_category','US.PROFITERO_SECURITY.SALES') }})
union all
select * from ({{ data_exist('hub_sns_category','US.PROFITERO_SECURITY.SNS_CATEGORIES') }})
union all
select * from ({{ data_exist('hub_sns_category','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_CATEGORY') }})
union all
select * from ({{ data_exist('hub_sns_category','US.PROFITERO_WINN.SNS_CATEGORIES') }})
union all
select * from ({{ data_exist('hub_sns_category','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT_SALE') }})
union all
select * from ({{ data_exist('hub_asin','US.PROFITERO_SECURITY.SNS_PRODUCTS') }})
union all
select * from ({{ data_exist('hub_asin','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('hub_asin','US.PROFITERO_SECURITY.SALES') }})
union all
select * from ({{ data_exist('hub_asin','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_PRODUCT_SALE') }})
union all
select * from ({{ data_exist('hub_asin','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('hub_asin','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT_SALE') }})
union all
select * from ({{ data_exist('hub_asin','US.PROFITERO_WINN.SNS_PRODUCTS') }})
union all
select * from ({{ data_exist('hub_asin','US.PROFITERO_WINN.SALES') }})
union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_FIBERON.PRICING_AVAILABILITY_HISTORY') }})
union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('hub_product_v2','US.PROFITERO_THERMATRU.PRICING_AVAILABILITY_HISTORY') }})
union all
select * from ({{ data_exist('hub_brand_v2','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('hub_brand_v2','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('lnk_asin_sns_categories','US.PROFITERO_SECURITY.SALES') }})
union all
select * from ({{ data_exist('lnk_asin_sns_categories','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_PRODUCT_SALE') }})
union all
select * from ({{ data_exist('lnk_asin_sns_categories','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT_SALE') }})
union all
select * from ({{ data_exist('lnk_asin_sns_categories','US.PROFITERO_WINN.SALES') }})
union all
select * from ({{ data_exist('lnk_product_asin','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('lnk_product_asin','US.PROFITERO_WINN.SNS_PRODUCTS') }})
union all
select * from ({{ data_exist('lnk_product_asin','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('lnk_product_asin','US.PROFITERO_SECURITY.SNS_PRODUCTS') }})
union all
select * from ({{ data_exist('lnk_product_brand','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('lnk_product_brand','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('sat_amz_category__winn_profitero_share','US.PROFITERO_SHARE_MOEN.DIM_AMZ_CATEGORY') }})
union all
select * from ({{ data_exist('sat_amz_category__security_profitero_share','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_CATEGORY') }})
union all
select * from ({{ data_exist('sat_amz_product__winn_profitero_share','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('sat_amz_product__security_profitero_share','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_PRODUCT') }})
union all
select * from ({{ data_exist('lsat_amz_product_sale__winn_profitero_share','US.PROFITERO_SHARE_MOEN.DIM_AMZ_PRODUCT_SALE') }})
union all
select * from ({{ data_exist('lsat_amz_product_sale__security_profitero_share','US.PROFITERO_SHARE_MASTER_LOCK.DIM_AMZ_PRODUCT_SALE') }})