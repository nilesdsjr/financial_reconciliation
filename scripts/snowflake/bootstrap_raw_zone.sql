-- Description: This script sets up the raw zone in Snowflake for financial data ingestion.
/* ---------- FILE FORMAT ---------- */
CREATE OR REPLACE FILE FORMAT finance.fmt_pipe_delim_csv
  TYPE            = CSV
  FIELD_DELIMITER = '|'
  SKIP_HEADER     = 1
  NULL_IF         = ('', 'NULL');

/* ---------- EXTERNAL STAGE ---------- */
CREATE OR REPLACE STAGE finance.stage_fin_raw
  URL                 = 's3://fin-raw/'           -- TODO: your bucket
  STORAGE_INTEGRATION = aws_fin_raw_int           -- TODO: your storage int
  FILE_FORMAT         = finance.fmt_pipe_delim_csv;

/* ---------- RAW TABLE ---------- */
CREATE OR REPLACE TABLE finance.raw__bank_txn (
  "Transaction ID" STRING,
  "Acct Num"       STRING,
  "Amount (USD)"   STRING,
  "Date"           STRING,
  load_ts          TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
  src_filename     STRING,
  src_source       STRING
);

/* ---------- SNOWPIPE ---------- */
CREATE OR REPLACE PIPE finance.pipe_raw_bank_txn
  AUTO_INGEST = TRUE
AS
COPY INTO finance.raw__bank_txn
FROM (
  SELECT
      $1, $2, $3, $4,
      CURRENT_TIMESTAMP(),
      METADATA$FILENAME,
      SPLIT_PART(METADATA$FILENAME,'source=',2)
  FROM @finance.stage_fin_raw
  PATTERN = '.*source=bank/.*[.]csv'
);
