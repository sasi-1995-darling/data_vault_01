-- Invariant: the HASHDIFF normalization pipeline must keep a BOOLEAN delete flag's
-- distinct states (TRUE / FALSE / NULL) as DISTINCT tokens. If Snowflake's BOOLEAN→TEXT
-- coercion -- or a future formula edit (e.g. swapping ::text for CAST(... AS VARCHAR), or
-- adding NULLIF(...,'')) -- ever folds two states to the same token, a logically-deleted
-- row and a live row would share a HASHDIFF and the delete would be silently missed.
-- Structural tests (B5/B6) prove the flag is IN the concat; only this runtime test proves
-- two distinct source values survive normalization as two distinct strings.

with delete_flag_states as (
    -- genuinely BOOLEAN-typed (NOT string 'true'/'false', which sidesteps the CAST path)
    select cast(true  as boolean) as delete_flag, 'deleted'      as state_label
    union all
    select cast(false as boolean) as delete_flag, 'not_deleted'  as state_label
    union all
    select cast(null  as boolean) as delete_flag, 'unknown_null' as state_label
),

tokenized as (
    select
        state_label,
        delete_flag,
        -- EXACT per-column treatment the generator emits (build.py build_final_layer):
        --   IFNULL(TRIM(col::text), '^^')  under the block's outer UPPER()
        upper(ifnull(trim(delete_flag::text), '^^')) as hashdiff_token
    from delete_flag_states
)

-- FAIL (return rows) if any two DISTINCT states share a token == value-collapse
select
    a.state_label  as state_a,
    b.state_label  as state_b,
    a.delete_flag  as flag_a,
    b.delete_flag  as flag_b,
    a.hashdiff_token as shared_token
from tokenized a
join tokenized b
    on a.hashdiff_token = b.hashdiff_token
   and a.state_label < b.state_label
