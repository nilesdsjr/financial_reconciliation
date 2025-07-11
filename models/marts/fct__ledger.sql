{{ config(materialized='incremental', unique_key='txn_hash') }}

WITH unioned AS (
    SELECT * FROM {{ ref('stg_bank__transactions') }}
    UNION ALL
    SELECT * FROM {{ ref('stg_cardnet__transactions') }}
    UNION ALL
    SELECT * FROM {{ ref('stg_processor__transactions') }}
)

SELECT
    u.txn_hash,
    u.txn_id,
    u.account_number,
    u.amount_usd,
    u.txn_ts,
    dacct.customer_id,
    dcur.usd_rate,
    u.amount_usd * dcur.usd_rate         AS amount_local,
    u.load_ts
FROM unioned                         u
LEFT JOIN {{ ref('dim_accounts') }}  dacct ON u.account_number = dacct.account_number
LEFT JOIN {{ ref('dim_currency') }}  dcur  ON DATE(u.txn_ts)   = dcur.fx_date
{% if is_incremental() %}
WHERE u.load_ts > (SELECT COALESCE(MAX(load_ts), '1900-01-01') FROM {{ this }})
{% endif %}
