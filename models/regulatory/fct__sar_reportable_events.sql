{{ config(materialized='table') }}

SELECT
    l.txn_hash,
    l.txn_id,
    l.customer_id,
    l.amount_usd,
    l.amount_usd * dcur.usd_rate AS amount_local,
    l.txn_ts,
    'HIGH_VALUE'                AS sar_reason,
    CURRENT_TIMESTAMP()         AS sar_generated_ts
FROM {{ ref('fct__ledger') }} l
LEFT JOIN {{ ref('dim_currency') }} dcur
  ON DATE(l.txn_ts) = dcur.fx_date
WHERE l.amount_usd > 10000            -- FinCEN SAR threshold
  AND l.customer_id NOT IN (SELECT customer_id FROM {{ ref('dim_whitelisted_customers') }})
