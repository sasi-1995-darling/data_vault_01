{% docs moen_sap_product__z_mara %}

z_mara contains data about material; including unique item numbers as well as lookup keys for item descriptions, item categories or classifications, attributes or characteristics, unit of measure, pricing information and other critical data about items

{% enddocs %}

{% docs moen_sap_product__z_makt %}

z_makt is a lookup table that stores information about material description. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_zrmarea %}

z_zrmarea is a lookup table that stores information about room/area description

{% enddocs %}

{% docs moen_sap_product__z_zptgkt %}

z_zptgkt is a lookup table that stores information about product group (item group) description. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_zpltt %}

z_zpltt is a lookup table that stores information about platform description. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_zptypt %}

z_zptypt is a lookup table that stores information about price type (item line) description. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_zrepcatgt %}

z_zrepcatgt is a lookup table that contains information on reporting category description. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_zarcht %}

z_zarcht is a lookup table that stores information about architecture. It also includes a language key

{% enddocs %}
{% docs moen_sap_product__z_zptk %}

z_zptk is a lookup table that stores information about product type (item type) subgroup description

{% enddocs %}

{% docs moen_sap_product__z_zpfint %}

z_zpfint is a lookup table that stores information about product finish description. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_zcmpfamt %}

z_zcmpfamt is a lookup table that stores information about competitor product family description/price band. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_zptgt %}

z_zptgt is a lookup table that stores information about price type group (item price) description. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_zpbusownert %}

z_zpbusownert is a lookup table that stores information about business segment owner. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_zbusinessunitt %}

z_zbusinessunitt is a lookup table that stores information about business unit. It also includes a language key

{% enddocs %}

{% docs moen_sap_product__z_ausp %}

z_ausp stores data for characteristic values. This use case is taking a specific ATINN to pull the characteristic values for brand.

{% enddocs %}

{% docs moen_sap_shipment__z_ce1new4 %}

z_ce1new4 is a table that stores data for COPA (control parameters) - Moen Operating Concern, which is the raw sales/shipment data from SAP

{% enddocs %}

{% docs moen_sap_shipment__z_kna1 %}

z_kna1 is a table that stores data for customer, i.e. general customer master data such as name, address, group/group key and other attributes

{% enddocs %}

{% docs moen_sap_shipment__z_knvv %}

z_knvv is a table that stores customer master sales data such as sales area, organization, sales office and other attributes 

{% enddocs %}

{% docs moen_sap_shipment__z_adrc %}

z_adrc is a table that stores data for addresses, i.e. general address information on various entities/parties such as customers, vendors, and business partners

{% enddocs %}

{% docs moen_sap_input__z_zdw_s600 %}

z_zdw_s600 is a table that stores data for sales/input - It is derived from two main SAP tables VBAK which stores header information for sales documents 
and VBAP which stores line item details for each sales document

{% enddocs %}

{% docs moen_sap_input__z_t001w %}

z_t001w is a table that stores plant data and their associated details

{% enddocs %}

{% docs moen_sap_input__z_tvagt %}

z_tvagt is a table that stores descriptive texts for reasons why a sales document may be rejected, i.e. sales document rejection reasons. It also includes a language key

{% enddocs %}

{% docs moen_sap_input__z_tvakt %}

z_tvakt is a table that stores descriptive texts for sales document types, such as orders, quotations, contracts, etc. It also includes a language key

{% enddocs %}

{% docs moen_sap_input__z_t25a0 %}

z_t25a0 is a table that contains descriptive texts for the reasons why items in a sales order might be marked for deletion/returned. It also includes a language key

{% enddocs %}

{% docs moen_sap_input__z_t25a1 %}

z_t25a1 is a table that stores descriptive texts for reasons for deleting individual items from a sales document, such as a sales order. It also includes a language key

{% enddocs %}

{% docs reference__winn_virtual_bundles %}

winn_virtual_bundles contains moen bundles mapping for home depot, amazon, lowes and wayfair

{% enddocs %}

{% docs moen_sap_bw_shipment__azcopa %}

azcopa is one time load table of historic shipments data from SAP BW(2019-2023)

{% enddocs %}

{% docs moen_sap_bw_shipment_inputs__azinput %}

azinput is one time load table of historic inputs data from SAP BW(2019-2024)

{% enddocs %}

{% docs hofr_sap_shipment_inputs__hofr_us_sales %}

hofr_us_sales is one time load table of historic shipments data from eclipse(2019-2023)

{% enddocs %}

{% docs hofr_sap_shipment_inputs__eclipse_sap_cust_xref %}

eclipse_sap_cust_xref is a cross-reference table for eclipse customer_id to sap customer_id for legacy house of rohl eclipse data

{% enddocs %}

{% docs moen_sap_sales__z_vbak %}

z_vbak is an Moen SAP table that contains sales header records

{% enddocs %}

{% docs moen_sap_sales__z_vbap %}

z_vbap is an Moen SAP table that contains sales lines records

{% enddocs %}
