{%- set source_model = ['stg_customer_account__ml_ebs','stg_link_customer_account__tt_e21'] %}
{%- set src_pk = "account_hk" -%}
{%- set src_fk = ["customer_hk", "account_hk"] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                    src_source=src_source, source_model=source_model) }}
