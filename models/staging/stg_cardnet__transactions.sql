{{ config(materialized='incremental', unique_key='txn_hash') }}

WITH src AS (
    SELECT
        {{ rename_and_cast('cardnet', ref('raw__bank_txn')) }},
        load_ts,
        src_filename
    FROM {{ ref('raw__bank_txn') }}
)

SELECT
    txn_id,
    account_number,
    CAST(amount AS DECIMAL(18,2))   AS amount_usd,
    CONVERT_TIMEZONE('UTC', txn_dt) AS txn_ts,
    {{ dbt_utils.generate_surrogate_key(['txn_id','account_number']) }} AS txn_hash,
    load_ts,
    src_filename
FROM src
{% if is_incremental() %}
WHERE load_ts > (SELECT COALESCE(MAX(load_ts), '1900-01-01') FROM {{ this }})
{% endif %}
