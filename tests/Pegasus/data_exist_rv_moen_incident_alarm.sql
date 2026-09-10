select * from ({{ data_exist('hub_alarm','US.REFERENCE.ALARM')}}) 
union all
select * from ({{ data_exist('hub_incident','US.NOTIFICATION_API.CLEANED_FLO_PROD_NOTIFICATION_API_INCIDENT')}}) 
union all
select * from ({{ data_exist('lnk_incident_alarm_device','US.NOTIFICATION_API.CLEANED_FLO_PROD_NOTIFICATION_API_INCIDENT')}}) 
union all
select * from ({{ data_exist('sat_alarm_definition__flo_prod','US.REFERENCE.ALARM')}}) 
union all
select * from ({{ data_exist('sat_incident_details__flo_prod','US.NOTIFICATION_API.CLEANED_FLO_PROD_NOTIFICATION_API_INCIDENT')}}) 