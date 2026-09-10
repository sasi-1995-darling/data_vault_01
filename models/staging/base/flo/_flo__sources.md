{% docs flo__prod_account %}

Accounts can link to prod_account_subscription, prod_location, prod_user_account_role, and prod_user via its ID with their Account_ID cols

{% enddocs %}

{% docs flo__prod_account_subscription %}

Account sub can link to prod_account via its account_id with their id col

{% enddocs %}

{% docs flo__prod_location %}

Locations can link to prod_icd, prod_user_location_role via its location_id, and to prod_account via its account_id

{% enddocs %}

{% docs flo_prod_icd %}

Devices can link to location, and prod_account_subscription via its location_id, and to flo__prod_onboarding_log via its id

{% enddocs %}
{% docs flo__prod_onboarding_log %}

Onboarding logs can link to devices via its icd_id

{% enddocs %}
{% docs flo__prod_subscription %}

Subs can link to devices via its related_entity_id.

{% enddocs %}
{% docs flo__prod_user %}

Users can link to Accounts via its account_id, to prod_user_account_role, and prod_user_account_group_role via its ID

{% enddocs %}

{% docs flo__prod_alert_feedback %}

This is a record of customer feedback for critical alerts. You can join on INCIDENT_ID in the INCIDENT table. This is a subset of all alerts and only the critical alerts that customers opt to give us feedback on. This is how we can determine if alerts were true positives, false positives, and what the label provided by the customer is (irrigation system, toilet flapper, long shower, plumbing failure, etc.)

{% enddocs %}

{% docs flo__internal_devices %}

Contains known test cases for device

{% enddocs %}

{% docs flo__internal_locations %}

Contains known test cases for location

{% enddocs %}

{% docs flo__device_daily %}

Daily telemetry aggregations

{% enddocs %}

{% docs flo__device_info %}

Serial Number to MAC ID mapping

{% enddocs %}

{% docs flo__incident %}

Incidents for devices according to icd_id

{% enddocs %}

{% docs flo__alarm %}

description for incident transactions

{% enddocs %}