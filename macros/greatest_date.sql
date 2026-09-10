{%- macro greatest_date(fields) -%}
  {%- set placeholder_date = "'1900-01-01'" -%}
  {%- set nvl_fields = [] -%}
  {%- for field in fields -%}
    {% do nvl_fields.append("\n\tnvl(" ~ field ~ ", " ~ placeholder_date ~ ")") %}
  {%- endfor -%}
  nullif(greatest( {{ nvl_fields|join(', ') }}), {{ placeholder_date }} )
{%- endmacro -%}
