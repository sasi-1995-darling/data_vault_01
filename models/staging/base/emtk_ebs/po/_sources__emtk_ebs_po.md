{% docs emtk_ebs_po__po_action_history %}

PO_ACTION_HISTORY contains information about the approval and
control history of your purchasing documents. There is one record
in this table for each approval or control action an employee takes
on a purchase order, purchase agreement, release, or requisition.
Each row includes references to the document itself, the employee
who acted on the document, the date of the action, the type of
action taken on the document, and a note each employee can leave
when taking an action on the document.

Oracle Purchasing uses this information to display history information
about documents and to forward documents in the approval process
to the appropriate employee.

{% enddocs %}

{% docs emtk_ebs_po__po_distributions_all %}

PO_DISTRIBUTIONS_ALL contains accounting distribution information for
a purchase order shipment line. You need one row for each distribution
line you attach to a purchase order shipment. There are four types of
documents using distributions in Oracle Purchasing:

- Standard Purchase Orders
- Planned Purchase Orders
- Planned Purchase Order Releases
- Blanket Purchase Order Releases

{% enddocs %}

{% docs emtk_ebs_po__po_headers_all %}

PO_HEADERS_ALL contains header information for your purchasing
documents.
You need one row for each document you create. There are six types of
documents that use PO_HEADERS_ALL:

- RFQs
- Quotations
- Standard purchase orders
- Planned purchase orders
- Blanket purchase orders
- Contracts

Each row contains buyer information, supplier
information, brief notes, foreign currency information, terms and
conditions information, and the status of the document.

Oracle Purchasing uses this information to record information that is
related to a complete document.

PO_HEADER_ID is the unique system-generated primary key and is
invisible to the user. SEGMENT1 is the system-assigned number you use
to identify the document in forms and reports. Oracle Purchasing
generates SEGMENT1 using the PO_UNIQUE_IDENTIFIER_CONT_ALL table if
you choose to let Oracle Purchasing generate document numbers for you.
SEGMENT1 is not unique for the entire table. Different document types
can share the same numbers. You can uniquely identify a row in
PO_HEADERS_ALL using ORG_ID, SEGMENT1, and TYPE_LOOKUP_CODE, or using
PO_HEADER_ID.

If APPROVED_FLAG is 'Y', the purchase order is approved. If your
document type is a blanket purchase order, contract purchase order,
RFQ, or quotation, Oracle Purchasing uses START_DATE and END_DATE to
store the valid date range for the document. Oracle Purchasing only
uses BLANKET_TOTAL_AMOUNT for blanket purchase orders or contract
purchase orders.

If you autocreate a quotation from an RFQ using the Copy Document window,
Oracle Purchasing stores the foreign key to your original RFQ in
FROM_HEADER_ID. Oracle Purchasing also uses FROM_TYPE_LOOKUP_CODE to
indicate that you copied the quotation from an RFQ.

Oracle Purchasing does not use SUMMARY_FLAG and ENABLED_FLAG. Because
future versions of Oracle Purchasing will use them, SUMMARY_FLAG and
ENABLED_FLAG should always be 'N' and 'Y' respectively.

You enter document header information in the Header region of the
Purchase Orders, RFQs, and Quotations windows.

{% enddocs %}



{% docs emtk_ebs_po__po_lines_all %}

PO_LINES_ALL stores current information about each purchase order
line. You need one row for each line you attach to a document. There
are five document types that use lines:
- RFQs
- Quotations
- Standard purchase orders
- Blanket purchase orders
- Planned purchase orders

Each row includes the line number, the item number and
category, unit, price, tax information, matching information, and
quantity ordered for the line. Oracle Purchasing uses this information
to record and update item and price information for purchase orders,
quotations, and RFQs.

PO_LINE_ID is the unique system-generated line number invisible to the
user. LINE_NUM is the number of the line on the purchase order.
Oracle Purchasing uses CONTRACT_ID to reference a contract purchase
order from a standard purchase order line. Oracle Purchasing uses
ALLOW_PRICE_OVERRIDE_FLAG, COMMITTED_AMOUNT, QUANTITY_COMMITTED,
MIN_RELEASE_AMOUNT only for blanket and planned purchase order lines.

The QUANTITY field stores the total quantity of all purchase order
shipment lines (found in PO_LINE_LOCATIONS_ALL).

{% enddocs %}

{% docs emtk_ebs_po__po_line_locations_all %}

PO_LINE_LOCATIONS_ALL contains information about purchase order
shipment schedules and blanket agreement price breaks. You need one
row for each schedule or price break you attach to a document line.
There are seven types of documents that use shipment schedules:

- RFQs
- Quotations
- Standard purchase orders
- Planned purchase orders
- Planned purchase order releases
- Blanket purchase orders
- Blanket purchase order releases

Each row includes the location, quantity, and dates for
each shipment schedule. Oracle Purchasing uses this information to
record delivery schedule information for purchase orders, and price
break information for blanket purchase orders, quotations and RFQs.

PO_RELEASE_ID applies only to blanket purchase order release
shipments. PO_RELEASE_ID identifies the release on which you placed
this shipment.

SOURCE_SHIPMENT_ID applies only to planned purchase order release
shipments. It identifies the planned purchase order shipment you chose
to release from.

PRICE_OVERRIDE always equals the purchase order line price for
standard purchase order shipments. For blanket and planned purchase
orders, PRICE_OVERRIDE depends on the values of the
ALLOW_PRICE_OVERRIDE_FLAG and NOT_TO_EXCEED_PRICE in the corresponding
row in PO_LINES_ALL:

- If ALLOW_PRICE_OVERRIDE_FLAG is 'N', then PRICE_OVERRIDE
equals UNIT_PRICE in PO_LINES_ALL.
- If ALLOW_PRICE_OVERRIDE_FLAG is 'Y', the PRICE_OVERRIDE can
take any value that is smaller than NOT_TO_EXCEED_PRICE in
PO_LINES_ALL.

The QUANTITY field corresponds to the total quantity
ordered on all purchase order distribution lines (found in
PO_DISTRIBUTIONS_ALL).

Oracle Purchasing automatically updates QUANTITY_RECEIVED,
QUANTITY_ACCEPTED, and QUANTITY_REJECTED when you receive, return, or
inspect goods or services. Oracle Payables automatically updates
QUANTITY_BILLED when you match an invoice with a purchase order
shipment. Oracle Purchasing automatically updates QUANTITY_CANCELLED
when you cancel a purchase order shipment.

Oracle Purchasing sets APPROVED_FLAG to 'Y' when you approve the
corresponding purchase order if there are no problems associated with
the shipment and its related distributions.

Oracle Purchasing sets ENCUMBERED_FLAG to 'Y' and enters the
ENCUMBERED_DATE when you approve a purchase order if you use
encumbrance.

{% enddocs %}

{% docs emtk_ebs_po__rcv_transactions %}

RCV_TRANSACTIONS stores historical information about receiving
transactions that you have performed. When you enter a receiving
transaction and the receiving transaction processor processes your
transaction, the transaction is recorded in this table.

Once a row has been inserted into this table, it will never be
updated. When you correct a transaction, the net transaction quantity
is maintained in RCV_SUPPLY. The original transaction quantity does
not get updated. You can only delete rows from this table using the
Purge feature of Oracle Purchasing.

{% enddocs %}

{% docs emtk_ebs_po__ap_suppliers %}

AP_SUPPLIERS stores information about your supplier level attributes. Each row includes the purchasing, receiving, invoice, tax, classification, and general information. Oracle Purchasing uses this information to determine active suppliers. This table replaces the old PO_VENDORS table. The supplier name, legal identifiers of the supplier will be stored in TCA and a reference to the party created in TCA will be stored in AP_SUPPLIERS.PARTY_ID, to link the party record in TCA.

{% enddocs %}

{% docs emtk_ebs_po__ap_supplier_sites_all %}

AP_SUPPLIER_SITES_ALL stores information about your supplier site level attributes. You need a row for unique combination of supplier address, operating unit and the business relationship that you have with the supplier. This table relplaces the old PO_VENDOR_SITES_ALL table. The supplier address information is not maintained in this table and is maintained in TCA. The reference to the internal identifier of address in TCA will be stored in AP_SUPPLIER_SITES_ALL.LOCATION_ID, to link the address record in TCA. Each row includes the supplier reference, purchasing, invoice, and general information.

{% enddocs %}

{% docs emtk_ebs_po__financials_system_params_all %}

FINANCIALS_SYSTEM_PARAMETERS_ALL contains options and
defaults you share between your Oracle Payables
application, and your Oracle Purchasing and Oracle Assets
applications.
You can define these options and defaults
according to the way you run your business.
This table corresponds to the Financials Options
window.

{% enddocs %}

{% docs emtk_ebs_po__fnd_lookup_values %}

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

{% docs emtk_ebs_po__cst_item_costs %}

CST_ITEM_COSTS stores item cost control information by cost type.

For standard costing organizations, the item cost control information
for the Frozen cost type is created when you enter a new item. For
average cost organizations, item cost control information is created
when you transact the item for the first time.

You can use the Item Costs window to enter cost control
information.

{% enddocs %}

{% docs emtk_ebs_po__gl_code_combinations %}

GL_CODE_COMBINATIONS stores valid account combinations for each Accounting Flexfield structure within your Oracle General Ledger application. Associated with each account are certain codes and flags, including whether the account is enabled, whether detail posting or detail budgeting is allowed, and others.
Segment values are stored in the SEGMENT columns. Note that each Accounting Flexfield structure may use different SEGMENT columns within the table to store the flexfield value combination. Moreover, the SEGMENT columns that are used are not guaranteed to be in any order.
The Oracle Application Object Library table FND_ID_FLEX_SEGMENTS stores information about which column in this table is used for each segment of each Accounting Flexfield structure. Summary accounts have SUMMARY_FLAG = 'Y' and TEMPLATE_ID not NULL. Detail accounts have SUMMARY_FLAG = 'N' and TEMPLATE_ID NULL.

{% enddocs %}

{% docs emtk_ebs_po__hr_all_organization_units %}

HR_ALL_ORGANIZATION_UNITS holds the definitions that identify business
groups and the organization units within a single business group.
Additional information about classifications and information types for
each organization is held in HR_ORGANIZATION_INFORMATION.

{% enddocs %}

{% docs emtk_ebs_po__hr_locations_all %}

HR_LOCATIONS_ALL holds the work location definitions. 

{% enddocs %}

{% docs emtk_ebs_po__per_all_people_f %}

PER_ALL_PEOPLE_F is the DateTracked table that holds personal
information for employees, applicants, ex-employees, ex-applicants,
contacts and other people. The columns START_DATE,
EFFECTIVE_START_DATE and EFFECTIVE_END_DATE are all maintained
by DateTrack. The START_DATE is the date when the first record for
this person was created. The earliest EFFECTIVE_START_DATE for a
person is equal to the START_DATE.
NOTE: Users must not enter information into the Developer Descriptive
Flexfield columns. These are reserved for the use of localization and
verticalization teams, for entry and maintenance of legislative or
industry-specific data.

{% enddocs %}

{% docs emtk_ebs_po__mtl_categories_b %}

MTL_CATEGORIES_B is the code combinations table for item categories.
Items are grouped into categories within the context of a category set
to provide flexible grouping schemes.

The item category is a key flexfield with a flex code of MCAT. The
flexfield structure identifier is also stored in this table to support
the ability to define more than one flexfield structure (multi-flex).

Item categories now support multilingual category description. MLS is implemented with a pair of tables: MTL_CATEGORIES_B and MTL_CATEGORIES_TL. MTL_CATEGORIES_TL table holds translated Description for Categories.

{% enddocs %}

{% docs emtk_ebs_po__mtl_category_sets_b %}

MTL_CATEGORY_SETS_B contains the entity definition for category sets. A category set is a categorization scheme for a group of items. Items
may be assigned to different categories in different category sets to
represent the different groupings of items used for different
purposes. An item may be assigned to only one category within a
category set, however.

STRUCTURE_ID identifies the flexfield structure associated with the
category set. Only categories with the same flexfield structure may
be grouped into a category set.

CONTROL_LEVEL defines whether the category set is controlled at the
item or the item/organization level. When an item is assigned to an
item level category set within the item master organization, the
category set assignment is propagated to all other organizations to
which the item is assigned.

VALIDATE_FLAG defines whether a list of valid categories is used to
validate category usage within the set. Validated category sets will
not allow item assignment to the category set in categories that are
not in a predefined list of valid categories.

Category Sets now support multilingual category set name and description. MLS is implemented with a pair of tables: MTL_CATEGORY_SETS_B and MTL_CATEGORY_SETS_TL. MTL_CATEGORY_SETS_TL table holds translated Name and Description for Category Sets.


{% enddocs %}

{% docs emtk_ebs_po__mtl_item_categories %}

MTL_ITEM_CATEGORIES stores inventory item assignments to categories within a category set. For each category assignment, this table stores the item, the category set, and the category. Items always may be assigned to multiple category sets. However, depending on the Multiple Assignments Allowed attribute value in a given category set definition, an item can be assigned to either many or only one category in that category set.

This table may be populated through the Master Items and
Organization Items windows. It can also be populated by
performing item assignments when a category set is defined. It is
also populated when an item is transferred from engineering to
manufacturing. The table may also be populated through the Item Category Open Interface.

{% enddocs %}

{% docs emtk_ebs_po__mtl_system_items_b %}

MTL_SYSTEM_ITEMS_B is the definition table for items. This table holds
the definitions for inventory items, engineering items, and purchasing
items. You can specify item-related information in fields such as:
Bill of Material, Costing, Purchasing, Receiving, Inventory, Physical attributes, General Planning, MPS/MRP Planning, Lead times, Work in Process, Order Management, and Invoicing.

You can set up the item with multiple segments, since it is
implemented as a flexfield. Use the standard 'System Items' flexfield
that is shipped with the product to configure your item flexfield.
The flexfield code is MSTK.

The primary key for an item is the INVENTORY_ITEM_ID and ORGANIZATION_ID. Therefore, the same item can be defined in more than one organization.

Each item is initially defined in an item master organization. The
user then assigns the item to other organizations that need to
recognize this item. A row is inserted for each new organization
the item is assigned to. Many columns such as MTL_TRANSACTIONS_ENABLED_FLAG and
BOM_ENABLED_FLAG correspond to item attributes defined in the
MTL_ITEM_ATTRIBUTES table. The attributes that are available to the
user depend on which Oracle applications are installed. The table
MTL_ATTR_APPL_DEPENDENCIES maintains the relationships between item
attributes and Oracle applications.

Two unit of measure columns are stored in MTL_SYSTEM_ITEMS_B table. PRIMARY_UOM_CODE is the 3-character unit that is used throughout Oracle Manufacturing. PRIMARY_UNIT_OF_MEASURE is the 25-character Unit of Measure that is used throughout Oracle Purchasing. Unlike the PRIMARY_UOM_CODE, the Unit of Measure is language-dependent attribute, however, PRIMARY_UNIT_OF_MEASURE column stores value in the installation base language only.

Items now support multilingual description. MLS is implemented with a pair of tables: MTL_SYSTEM_ITEMS_B and MTL_SYSTEM_ITEMS_TL. Translations table (MTL_SYSTEM_ITEMS_TL) holds item Description and Long Description in multiple languages. DESCRIPTION column in the base table (MTL_SYSTEM_ITEMS_B) is for backward compatibility and is maintained in the installation base language only.

{% enddocs %}
