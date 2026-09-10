{% docs emtk_ebs_sales__fnd_lookup_values %}

FND_LOOKUP_VALUES stores Oracle Application Object Library QuickCode
values. Each row includes the QuickCode lookup type, the QuickCode
itself, its meaning, and additional description, as well as values
that indicate whether this QuickCode is currently valid. Each row
also includes a language code that indicates what language the
information is in. You need one row for each QuickCode in each of
the languages installed at your site. Oracle Application Object
Library uses this information to display LOVs for Oracle
Application Object Library forms and other forms.

{% enddocs %}

{% docs emtk_ebs_sales__cst_item_costs %}

CST_ITEM_COSTS stores item cost control information by cost type.

For standard costing organizations, the item cost control information
for the Frozen cost type is created when you enter a new item. For
average cost organizations, item cost control information is created
when you transact the item for the first time.

You can use the Item Costs window to enter cost control
information.

{% enddocs %}

{% docs emtk_ebs_sales__hz_cust_accounts %}

The HZ_CUST_ACCOUNTS table stores information about customer accounts , 
or business relationships that the deploying company establishes with 
a party of type Organization or Person. 

This table focuses on business relationships and how transactions are 
conducted in the relationship. Since a party can have multiple customer 
accounts, this table might contain several records for a single party. 

For example, an individual person can establish a personal account, 
family account, and a professional account for a consulting practice.

{% enddocs %}

{% docs emtk_ebs_sales__hz_cust_acct_sites_all %}

The HZ_CUST_ACCT_SITES_ALL table stores all customer account sites across 
all operating units. Customer account sites are customer account addresses 
with which the deploying company does business. One customer account can 
have multiple customer account sites, and customer account sites for one 
customer account can belong to multiple operating units.

{% enddocs %}

{% docs emtk_ebs_sales__hz_cust_site_uses_all %}

The HZ_CUST_SITE_USES_ALL table stores business purposes assigned to 
customer account sites, for example Bill-To, Ship-To, and Statements. 
Each customer account site can have one or more purposes. This table 
is a child of the HZ_CUST_ACCT_SITES_ALL table, with the foreign key 
CUST_ACCT_SITE_ID. The HZ_CUST_SITE_USES_ALL table also stores operating 
unit identifier, though the HZ_CUST_ACCT_SITES_ALL table itself stores 
the operating unit for customer account sites.

{% enddocs %}

{% docs emtk_ebs_sales__hz_locations %}

The HZ_LOCATIONS table stores information about a delivery or postal 
address such as building number, street address, postal code, and directions 
to a location. This table provides physical location information about 
parties (organizations and people) and customer accounts. For example, 
this table store a physical location such as Building 300, 500 Oracle Parkway, CA, US 94065. 
Records in the HZ_LOCATIONS table can store delivery and postal 
information about a location through columns such as the LOCATION_DIRECTIONS, 
POST_OFFICE and TIME_ZONE columns. One can also use the HZ_LOCATIONS 
table to store latitude and longitude information. Data in the HZ_LOCATIONS 
table is also used to determine the appropriate tax rates for sales tax 
and VAT calculations.

{% enddocs %}

{% docs emtk_ebs_sales__hz_parties %}

The HZ_PARTIES table stores basic information about parties. Although 
a record in the HZ_PARTIES table represents a unique party, multiple 
parties can have the same name. The parties can be one of three types: 
Organization(for example, Oracle Corporation), Person(for example, Jane Doe), 
Group(for example, World Wide Web Consortium) Party reocrds can be created 
or updated using third party data sources such as Dun & Bradstreet's Global 
Data Products. The HZ_PARTIES table contains denormalized information from 
the HZ_LOCATIONS, HZ_PERSON_PROFILES, HZ_CONTACT_POINTS< HZ_ORGANIZATION_PROFILES< 
and HZ_PERSON_LANGUAGE tables. The identifying address contained in the HZ_PARTIES 
table is denormalized from the HZ_LOCATIONS table

{% enddocs %}

{% docs emtk_ebs_sales__ra_cust_trx_types_all %}

The RA_CUST_TRX_TYPES_ALL table stores information about each transaction 
type used for invoices, bills receivable, and credit memos. Each row includes 
AutoAccounting information as well as standard defaults for the transaction 
that results. The POST_TO_GL column stores Y or N to indicate if this 
transaction can post to your General Ledger. The ACCOUNTING_AFFECT_FLAG 
column stores Y or N to indicate if this transaction can update your open 
receivables balances. If the ACCOUNTING_AFFECT_FLAG column is Y, 
the transaction will appear in aging. The TYPE column contains values: 
INV for Invoice, CM for Credit Memo, and DM for Debit Memo. 
If AutoAccounting is based on transaction type, the GL_ID_REV, GL_ID_FREIGHT, 
and GL_ID_REC columns store the default revenue, freight, and receivables accounts. 
The STATUS and CREDIT_MEMO_TYPE_ID columns are required even though they are null allowed. 
The primary key for this table is CUST_TRX_TYPE_ID

{% enddocs %}

{% docs emtk_ebs_sales__ra_customer_trx_all %}

This table contains invoice, debit memo, bills receivable, and credit memo 
header information. Each row in this table includes general invoice information 
such as customer, transaction type, and printing instructions. One row exists 
for each invoice, debit memo, bill receivable, and credit memo. 
Invoices, debit memos, credit memos, and bills receivable are 
distinguished by their associated transaction types stored in the this table.

{% enddocs %}

{% docs emtk_ebs_sales__ra_customer_trx_lines_all %}

The RA_CUSTOMER_TRX_LINES_ALL table stores line information about 
invoices, debit memos, credit memos, and bills receivable. 
For example, an invoice can have one line for Product A and 
another line for Product B. Each line requires one row in this table. 
Invoices, debit memos, credit memos, and bills receivable 
distinguished by the transaction type of the corresponding row 
in the RA_CUSTOMER_TRX_ALL table. Credit memos must also have 
a value in the PREVIOUS_CUSTOMER_TRX_LINE_ID column. 
On-account credits, which are not related to specific invoices or 
invoice lines when they are created, will not have values in this column. 
The QUANTITY_ORDERED column stores the amount of product that was ordered. 
The QUANTITY_INVOICED column stores the amount of product that was invoiced. 
For manually entered invoices, the QUANTITY_ORDERED and QUANTITY_INVOICED 
columns must be the same. For invoices that were imported through 
AutoInvoice, the QUANTITY_ORDERED and QUANTITY_INVOICED columns can be different. 
If you enter a credit memo, the QUANTITY_CREDITED column stores 
the amount of product that was credited. The UOM_CODE column stores 
the unit of measure code as defined in the INV_UNITS_OF_MEASURE table. 
The UNIT_STANDARD_PRICE column stores the list price per unit for this transaction line. 
The UNIT_SELLING_PRICE column stores the selling price per unit for this transaction line. 
For transactions that were imported through AutoInvoice, 
the UNIT_STANDARD_PRICE and UNIT_SELLING_PRICE columns can be different. 
The DESCRIPTION, TAXING_RULE, QUANTITY_ORDERED, UNIT_STANDARD_PRICE, 
UOM_CODE, and UNIT_SELLING_PRICE columns are required even though they 
are null allowed. Receivables uses the LINE_TYPE column to distinguish 
between the different types of lines. LINE represents regular invoice 
lines that normally refer to an item. TAX represents a tax line. 
The LINK_TO_CUST_TRX_LINE_ID column references the invoice line that is 
associated with the row that holds the TAX line type. FREIGHT is similar 
to TAX, but you can have at most one freight line per invoice line. 
You can also have one freight line that has a null LINK_TO_CUST_TRX_LINE_ID 
column. An invoice that has one freight line with a null LINK_TO_CUST_TRX_LINE_ID 
column has header-level freight. CB represents a chargeback line. 
For every row in this table that belongs to a completed postable 
or nonpostable transaction, where the RA_CUSTOMER_TRX.COMPLETE_FLAG is Y, 
there must be at least one row in the RA_CUST_TRX_LINE_GL_DIST 
table that stores accounting information. There must be at least one row 
in this table even for nonpostable transactions. 
The primary key for this table is CUSTOMER_TRX_LINE_ID.

{% enddocs %}

{% docs emtk_ebs_sales__ra_salesrep_territories %}

The RA_SALESREP_TERRITORIES table stores territory information for your salespeople. 
Territories let you track business information by region. 
You can assign a territory to a customer, salesperson, invoice, or commitment.
The primary key for this table is SALESREP_TERRITORY_ID.

{% enddocs %}

{% docs emtk_ebs_sales__ra_territories %}

It's a view?

{% enddocs %}

{% docs emtk_ebs_sales__ra_batch_sources_all %}

The RA_BATCH_SOURCES_ALL table stores information about the sources of your invoices, 
credit memos, and commitments. Each row includes information about invoice, 
batch, and credit memo numbering. Oracle Receivables creates one row for 
each batch source that you define. Receivables uses batch sources 
to default a transaction type during invoice entry and to determine 
invoice, batch, and credit memo numbering. 
The BATCH_SOURCE_TYPE column stores INV for manual batches or FOREIGN 
for imported batches. The STATUS, CREDIT_MEMO_BATCH_SOURCE_ID, 
AUTO_BATCH_NUMBERING, and AUTO_TRX_NUMBERING columns are required even 
though they are null allowed. The primary key for this table is BATCH_SOURCE_ID.

{% enddocs %}

{% docs emtk_ebs_sales__hz_party_sites %}

The HZ_PARTUY_SITES table stores all the addresses associated to a party. 
If the address does not exist as a location, then a new location is created 
and the associated between the location and party, along with the 
location-specific party information such as MAILSTOP and ADDRESSEE, 
is stored in this table. One party can have one or more party sites 
and alternatively, an address could be associated to multiple parties 
or accounts. For example, 500 Oracle Parway, Redwood City, CA can be 
specified as a party site for Oracle Corporation. 
This party site can also be used for multiple accounts created for Oracle Corporation.

{% enddocs %}

{% docs emtk_ebs_sales__jtf_rs_group_members %}

This table stores the resources who are assigned to be 
Resource Organization members. Primary key is Group_member_id.

{% enddocs %}

{% docs emtk_ebs_sales__jtf_rs_resource_extns %}

This is table stores all important information about Resources. 
These Resources are coming from HR or HZ or Vonder table etc. 
Primary key is resource_id. 
Resource_number, user_id sre also unique keys.

{% enddocs %}

{% docs emtk_ebs_sales__jtf_rs_resource_extns_tl %}
{% enddocs %}

{% docs emtk_ebs_sales__jtf_rs_groups_tl %}
{% enddocs %}

{% docs emtk_ebs_sales__jtf_rs_groups_b %}
{% enddocs %}

{% docs emtk_ebs_sales__jtf_rs_salesreps %}

A multi-org view which will retrive data for your current operating unit and ignore data in other operating units.
This view stores information about salesreps for a particular organization.

{% enddocs %}


{% docs emtk_ebs_sales__oe_sales_credit_types %}
{% enddocs %}

{% docs emtk_ebs_sales__oe_order_header_all %}

OE_ORDER_HEADERS_ALL stores header information for orders in Order Management.

{% enddocs %}
        
{% docs emtk_ebs_sales__oe_order_lines_all %}

OE_ORDER_LINES_ALL stores information for all order lines in Oracle Order Management.

{% enddocs %}
        
{% docs emtk_ebs_sales__oe_order_sources %}

This tables stores the names of feeder systems from which you import sales 
order data(order headers, order lines, sales credits) into Order Management.

{% enddocs %}
        
{% docs emtk_ebs_sales__oe_transaction_types_tl %}

This is a mult-lingual table for OE_TRANSACTION_TYPES_ALL table.

{% enddocs %}


{% docs emtk_ebs_sales__financials_system_params_all %}

Oracle Financials system parameters and defaults

{% enddocs %}

{% docs emtk_ebs_sales__cst_cost_types %}

CST_COST_TYPES stores cost type definitions. 
The table is seeded with three cost types: Frozen, Average, and Pending. 
The Frozen cost type is used in standard costing organizations.
The average cost type is used in average costing organizations. 
All costs reference a cost type.

{% enddocs %}

{% docs emtk_ebs_sales__jtf_rs_group_members_vl %}

This VIEW stores the resources who are assigned to be Resource Organization members

{% enddocs %}