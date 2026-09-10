{% macro concatenate_fields( fields ) %}
    {%- for field in fields %}
        {%- if loop.first %}
        rtrim( trim( 
            nvl2( nullif( trim( {{field}} ),''), {{field}}||' x ','') ||
        {%- else %}
            nvl2( nullif( trim( {{field}} ),''), {{field}}||' x ','') {{-" || "  if not loop.last }}
        {%- endif %}
    {%- endfor %}
        ), 'x')
{% endmacro %}