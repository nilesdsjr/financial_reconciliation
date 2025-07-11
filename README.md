# Finance Pipeline (CSV ➜ Snowflake ➜ dbt)

End‑to‑end template for landing pipe‑delimited CSVs from S3, standardising schemas
across multiple payment vendors, reconciling balances, and surfacing SAR
(regulatory) events.

```bash
# bootstrap Snowflake objects (stage, raw table, snowpipe)
snowsql -f scripts/snowflake/bootstrap_raw_zone.sql

# install deps & run models
dbt deps
dbt run -s staging+
dbt run -s marts+
dbt test
dbt docs generate
open target/index.html        # lineage docs


finance-pipeline/                     # ⬅ root of the dbt + Snowflake project
│
├── dbt_project.yml                   # dbt config: model paths, default materializations
├── packages.yml                      # dbt package dependencies (dbt_utils, etc.)
├── README.md                         # quick-start instructions + CI badge
│
├── scripts/                          # infra as code (Snowflake DDL, bash helpers)
│   └── snowflake/
│       └── bootstrap_raw_zone.sql    # creates FILE FORMAT, STAGE, RAW TABLE, Snowpipe
│
├── mappings/                         # metadata that drives schema normalization
│   └── column_map.yml                # vendor-header → canonical-column map
│
├── macros/                           # Jinja helpers reused across models
│   └── rename_and_cast.sql           # uses column_map.yml to standardize raw columns
│
├── models/
│   ├── staging/                      # “stg_” models – cast + rename, nothing more
│   │   ├── stg_bank__transactions.sql
│   │   ├── stg_cardnet__transactions.sql
│   │   └── stg_processor__transactions.sql
│   │
│   ├── marts/                        # business-ready fact/dim models
│   │   └── fct__ledger.sql           # unified incremental ledger (union of all stg tables)
│   │
│   ├── alerts/                       # views + tests that surface reconciliation breaks
│   │   └── fct__bank_vs_processor_mismatch.sql
│   │
│   ├── regulatory/                   # compliance outputs (e.g., SAR filings)
│   │   └── fct__sar_reportable_events.sql
│   │
│   └── tests/                        # YAML-style model tests beyond defaults
│       └── reconciliation.yml        # equality test: mismatch view must be empty
│
├── snapshots/                        # slowly-changing tables for audit trails
│   └── snap__customer_profile.sql
│
└── target/                           # dbt build artifacts (auto-generated, git-ignored)
