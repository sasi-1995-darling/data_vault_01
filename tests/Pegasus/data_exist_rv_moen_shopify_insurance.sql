select * from ({{ data_exist('hub_fulfillment','US.SHOPIFY_MOEN.FULFILLMENT') }})
union all
select * from ({{ data_exist('hub_product_variant','US.SHOPIFY_MOEN.PRODUCT_VARIANT') }})
union all
select * from ({{ data_exist('hub_refund','US.SHOPIFY_MOEN.REFUND') }})
union all
select * from ({{ data_exist('lnk_order_fulfillment','US.SHOPIFY_MOEN.FULFILLMENT') }})
union all
select * from ({{ data_exist('lnk_product_variant','US.SHOPIFY_MOEN.PRODUCT_VARIANT') }})
union all
select * from ({{ data_exist('lnk_order_refund','US.SHOPIFY_MOEN.REFUND') }})
union all
select * from ({{ data_exist('lsat_order_fulfillment__winn_shopify','US.SHOPIFY_MOEN.FULFILLMENT') }})
union all
select * from ({{ data_exist('lsat_product_variant__winn_shopify','US.SHOPIFY_MOEN.PRODUCT_VARIANT') }})
union all
select * from ({{ data_exist('lsat_order_refund__winn_shopify','US.SHOPIFY_MOEN.REFUND') }})
union all
select * from ({{ data_exist('msat_order_discount__winn_shopify','US.SHOPIFY_MOEN.DISCOUNT_APPLICATION') }})
union all
select * from ({{ data_exist('msat_order_tag__winn_shopify','US.SHOPIFY_MOEN.ORDER_TAG') }})