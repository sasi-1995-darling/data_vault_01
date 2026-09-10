{% docs emtk_ebs_common__ar_hz_contact_points %}
The HZ_CONTACT_POINTS table stores information about how to communicate to parties or party sites using electronic media or methods such as Electronic Data Interchange (EDI), e-mail, telephone, telex, and the Internet. For example, telephone-related data can include the type of
telephone line, a touch tone indicator, a country code, the area code, the telephone number, and an extension number to a specific handset. NOTE: Each media or method should be stored as a separate record in this table. For example, the attributes of a complete telephone connection should be stored in a record, while EDI information should be stored in a different record.

The primary key for this table is CONTACT_POINT_ID.
{% enddocs %}

{% docs emtk_ebs_common__mtl_categories_b %}

MTL_CATEGORIES_B is the code combinations table for item categories.
Items are grouped into categories within the context of a category set
to provide flexible grouping schemes.

The item category is a key flexfield with a flex code of MCAT. The
flexfield structure identifier is also stored in this table to support
the ability to define more than one flexfield structure (multi-flex).

Item categories now support multilingual category description. MLS is implemented with a pair of tables: MTL_CATEGORIES_B and MTL_CATEGORIES_TL. MTL_CATEGORIES_TL table holds translated Description for Categories.

{% enddocs %}

{% docs emtk_ebs_common__mtl_category_sets_b %}

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

{% docs emtk_ebs_common__mtl_item_categories %}

MTL_ITEM_CATEGORIES stores inventory item assignments to categories within a category set. For each category assignment, this table stores the item, the category set, and the category. Items always may be assigned to multiple category sets. However, depending on the Multiple Assignments Allowed attribute value in a given category set definition, an item can be assigned to either many or only one category in that category set.

This table may be populated through the Master Items and
Organization Items windows. It can also be populated by
performing item assignments when a category set is defined. It is
also populated when an item is transferred from engineering to
manufacturing. The table may also be populated through the Item Category Open Interface.

{% enddocs %}

{% docs emtk_ebs_common__mtl_system_items_b %}

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

{% docs emtk_ebs_common__bom_cst_item_costs %}
CST_ITEM_COSTS stores item cost control information by cost type.

For standard costing organizations, the item cost control information
for the Frozen cost type is created when you enter a new item. For
average cost organizations, item cost control information is created
when you transact the item for the first time.

You can use the Item Costs window to enter cost control
information.

{% enddocs %}

{% docs emtk_ebs_common__fnd_lookup_values %}
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