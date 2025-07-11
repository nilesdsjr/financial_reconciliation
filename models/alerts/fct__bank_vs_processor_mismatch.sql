WITH deltas AS (
      SELECT batch_id, SUM(amount_usd) AS net_amount
      FROM {{ ref('stg_processor__transactions') }}
      GROUP BY 1
      UNION ALL
      SELECT batch_id, -SUM(amount_usd)
      FROM {{ ref('stg_cardnet__transactions') }}
      GROUP BY 1
)
SELECT batch_id, SUM(net_amount) AS delta
FROM deltas
GROUP BY 1
HAVING ABS(delta) > 0.01;      -- tolerance
