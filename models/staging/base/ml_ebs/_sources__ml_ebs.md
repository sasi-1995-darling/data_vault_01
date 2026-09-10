{% docs ml_ebs_product__mtl_system_items_b %}

mtl_system_items_b contains information about the attributes related to items, such as item codes, descriptions, units of measure, item categories, and other relevant details

{% enddocs %}

{% docs ml_ebs_product__mtl_system_items_tl %}

mtl_system_items_tl is a translation table which supports multilingual capabilities. Each record in this table corresponds to a specific language version of an item's information

{% enddocs %}

{% docs ml_ebs_product__mtl_item_categories %}

mtl_item_categories stores information about item categories. Item categories are used to classify and organize items based on common characteristics

{% enddocs %}

{% docs ml_ebs_product__mtl_categories_b %}

mtl_categories_b stores the category details. A category is used to manage the item categories hierarchy based on assigned categories catalog.

{% enddocs %}

{% docs ml_ebs_product__mtl_category_sets_tl %}

mtl_category_sets_tl is a translation table which stores translated information related to category sets

{% enddocs %}

{% docs ml_ebs_product__hr_all_organization_units %}

hr_all_organization_units stores information about organization units within an enterprise. Organization units can represent various entities within a company's structure, such as departments, divisions, and business units

{% enddocs %}

{% docs ml_ebs_shipment__hz_cust_accounts %}

hz_cust_accounts stores information about customer accounts and included account numbers, types, statuses, and other relevant details.

{% enddocs %}

{% docs ml_ebs_shipment__hz_cust_acct_sites_all %}

hz_cust_acct_sites_all stores information about customer account sites, which represent physical locations associated with customer accounts.

{% enddocs %}

{% docs ml_ebs_shipment__hz_cust_site_uses_all %}

hz_cust_site_uses_all stores information about the various uses of customer sites. It tracks the different purposes or uses associated with customer sites, such as billing addresses, shipping addresses, and other types of addresses. Each record in this table corresponds to a specific use of a customer site.

{% enddocs %}

{% docs ml_ebs_shipment__ra_customer_trx_all %}

ra_customer_trx_all stores information about customer transactions. It stores detailed information about customer transactions, including invoices, credit memos, debit memos, and other types of transactions. Each record in this table represents a single customer transaction.

{% enddocs %}

{% docs ml_ebs_shipment__ra_customer_trx_lines_all %}

ra_customer_trx_lines_all stores information about line-level information for customer transactions, such as invoices, credit memos, debit memos, and other types of transactions. Contains line-level details for customer transactions, allowing organizations to track individual items, charges, taxes, and other components associated with each transaction. Each record in this table represents a single line within a customer transaction.


{% enddocs %}

{% docs ml_ebs_shipment__ra_cust_trx_line_gl_dist_all %}

ra_cust_trx_line_gl_dist_all stores information about distribution information for revenue and accounting entries related to customer transactions. Table stores information about the distribution of revenue and accounting entries for customer transaction lines. 

{% enddocs %}

{% docs ml_ebs_shipment__hz_locations %}

hz_locations stores information about information about locations, such as addresses and geographical locations. Table stores information about various locations, such as offices, warehouses, stores, and other physical places. These locations can be associated with parties, such as customers, suppliers, or organizations, through other tables in the TCA module.

{% enddocs %}

{% docs ml_ebs_shipment__hz_parties %}

hz_parties stores information about parties, which represent individuals or organizations that engage in business activities. Table serves as a central repository for storing information about parties involved in business transactions, such as customers, suppliers, partners, and employees. Each record in this table represents a unique party.

{% enddocs %}

{% docs ml_ebs_shipment__hz_party_sites %}

hz_party_sites stores information about party sites, which represent physical locations associated with parties. Table stores information about physical locations associated with parties, such as customers, suppliers, or organizations. Each record in this table represents a unique party site.

{% enddocs %}

{% docs ml_ebs_shipment__ar_payment_schedules_all %}

ar_payment_schedules_all stores information about payments, installments, credit memos and invoice balances associated with customers.

{% enddocs %}

{% docs ml_ebs_shipment_oe_order_lines_all %}

ONT refers to the Order Management schema and OE_ORDER_LINES_ALL stores information about individual order lines.

{% enddocs %}

{% docs reference_tmlc_category_map %}

Item Category mapping table provided by MDM team

{% enddocs %}

{% docs ml_ebs_hz_parties %}

hz_parties contains information about the attributes related to parties - customer of one the type of a party . Party_id is the primary key to this table .

{% enddocs %}

{% docs ml_ebs_hz_cust_accounts %}

hz_cust_accounts contains information about accounts held by each party, Customer_account_id is the primary key to this table .

{% enddocs %}
