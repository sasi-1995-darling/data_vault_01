{% docs profitero__products_master %}

Master records contain unique ids to link across the tables

{% enddocs %}

{% docs profitero__rating %}

contains rating records

{% enddocs %}

{% docs profitero__review %}

contains review records

{% enddocs %}

{% docs profitero__customer_products %}

links to review and ratings via customer_product_id

{% enddocs %}

{% docs profitero__retailers %}

links to review and ratings via retailer_id

{% enddocs %}

{% docs profitero__brands %}

links to customer_products via brand_id

{% enddocs %}

{% docs profitero__price_availability_history %}

Provided by profitero, it contains price history of products across brands

{% enddocs %}