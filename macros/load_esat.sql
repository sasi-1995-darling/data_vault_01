{% macro load_esat(linkpk, hkdk, hkfk, stg_tbl) %}
    {# this jinja template creates satellites off of links with driving key relationships. it will track the most up-to-date version of that key for a link #}
    {# the code can be re-used for any link as long as the parameters below are edited #}
    {# define variables based on the column names of the link #}

    with 
    {# if the table does not yet exist, this logic will cause a failure. All "this" logic wrapped in if statement #}
    {% if is_incremental() -%}
    max_eff as (
        -- get the most recent record for each linkpk
        select 
            max(load_dts) as max_eff
            , {{ linkpk }}
        from {{ this }}
        group by
            {{ linkpk }}
    )

    , curr_records as (
        -- join the most recent record to itself to get all of the columns. Limit to only active records
        -- active records are defined as those with an end-date of '9999-12-31'
        select sat.*
        from {{ this }} sat
        inner join max_eff me
        on me.max_eff = sat.load_dts
        and me.{{ linkpk }} = sat.{{ linkpk }}
        where end_date = CONVERT_TIMEZONE('UTC', '9999-12-31')::TIMESTAMP_TZ(9) -- only active records
    )

    , stg_changed as (
        -- if a record has changed the new version is inserted into the target table
        -- a change is determined when the driving key exists in the target and the stage, but the stage FK's have changed
        select 
            stg.{{ linkpk }}
            , stg.{{ hkdk }}
            {%- for hk in hkfk %}
            , stg.{{ hk }}
            {%- endfor %}
            , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_TZ(9) as load_dts
            , stg.rec_src
            , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_TZ(9) as start_date
            , CONVERT_TIMEZONE('UTC', '9999-12-31')::TIMESTAMP_TZ(9) as end_date
        from {{stg_tbl}} stg
        inner join curr_records sat
        on stg.{{ hkdk }} = sat.{{ hkdk }}
        and (

            {%- for hk in hkfk -%}
            {%- if not loop.first -%} 
            or {% endif %} stg.{{ hk }} <> sat.{{ hk }}
            {% endfor -%}

        )
    )

    , stg_old_record_eff as (
        -- when a change occurs, the old record must be closed out (end_date = current_timestamp())
        -- however, we only insert into this table. we leave the original and insert a new record with the same details
        -- the only difference between this record and the previous is a new end_date. BV logic is needed to eliminate the dup
        select 
            sat.{{ linkpk }}
            , sat.{{ hkdk }}
            {%- for hk in hkfk %}
            , sat.{{ hk }}
            {%- endfor %}
            , sat.load_dts
            , sat.rec_src
            , sat.start_date
            , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_TZ(9) as end_date
        from {{stg_tbl}} stg
        inner join curr_records sat
        on stg.{{ hkdk }} = sat.{{ hkdk }}
        and (

            {%- for hk in hkfk -%}
            {%- if not loop.first -%} 
            or {% endif %} stg.{{ hk }} <> sat.{{ hk }}
            {% endfor -%}

        )
    )

    , {% endif -%}
    stg_new as (
        -- new records are identified as any driving key that exists in the stg but not in the tgt
        select 
            stg.{{ linkpk }}
            , stg.{{ hkdk }}
            {%- for hk in hkfk %}
            , stg.{{ hk }}
            {%- endfor %}
            , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_TZ(9) as load_dts
            , stg.rec_src
            , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_TZ(9) as start_date
            , CONVERT_TIMEZONE('UTC', '9999-12-31')::TIMESTAMP_TZ(9) as end_date
        from {{stg_tbl}} stg
        {% if is_incremental() %}
        where not exists (
            select 1
            from {{ this }} tgt
            where stg.{{ linkpk }} = tgt.{{ linkpk }}
        )
        {% endif %}
    )

    {% if is_incremental() %}
    select *
    from stg_changed

    union all

    select *
    from stg_old_record_eff

    union all
    {% endif %}

    select *
    from stg_new
{% endmacro %}