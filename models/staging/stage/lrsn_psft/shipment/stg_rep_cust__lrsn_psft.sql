{%- set yaml_metadata -%}

source_model: 'base_rep_cust__lrsn_psft'
derived_columns:
    setid: 'setid'
    business_unit: 'business_unit'
    cust_id: 'cust_id'
    cust_name: UPPER(cust_name)
    sold_to_flg: 'sold_to_flg'
    ship_from_bu: 'ship_from_bu'
    route_cd: 'route_cd'
    store_number: 'store_number'
    corporate_cust_id: 'corporate_cust_id'
    l_corp_cust_name: UPPER(l_corp_cust_name)
    l_region: 'l_region'
    bill_to_cust_id: 'bill_to_cust_id'
    region_cd: 'region_cd'
    l_pb_email: 'l_pb_email'
    address1: UPPER(address1)
    address2: UPPER(address2)
    city: UPPER(city)
    state: UPPER(state)
    postal: 'postal'
    country: UPPER(country)
    rec_src: "!LRSN PSFT"
    brand: '!LRSN'
    load_dts: current_timestamp()
    customer_bk: cust_id
    location_bk:
        - address1
        - address2
        - city
        - state
        - postal
        - country
    customer_location_bk:
        - cust_id
        - address1
        - address2
        - city
        - state
        - postal
        - country
hashed_columns:
    customer_hk:
        - customer_bk
        - brand
    location_hk:
        - location_bk
        - brand
    customer_location_hk:
        - customer_location_bk
        - brand
    customer_hdiff:
        is_hashdiff: true
        columns:
            - 'setid'
            - 'business_unit'
            - 'cust_id'
            - 'cust_name'
            - 'sold_to_flg'
            - 'ship_from_bu'
            - 'route_cd'
            - 'store_number'
            - 'corporate_cust_id'
            - 'l_corp_cust_name'
            - 'l_region'
            - 'bill_to_cust_id'
            - 'region_cd'
            - 'l_pb_email'
            - 'address1'
            - 'address2'
            - 'city'
            - 'state'
            - 'postal'
            - 'country'
    location_hdiff: 
        is_hashdiff: true
        columns:
            - 'setid'
            - 'business_unit'
            - 'address1'
            - 'address2'
            - 'city'
            - 'state'
            - 'postal'
            - 'country'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=false,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}
