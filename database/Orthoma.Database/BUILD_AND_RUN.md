# Orthoma star-schema build

A SQL Server dimensional model for the Orthoma analytics. A T-SQL
generator produces a fresh synthetic dataset directly into a star schema
(7 dimensions, 3 facts) that Power BI consumes through `rpt` views. No CSV
files are required.

All data is synthetic. This is a local prototype layer, not a production
or Azure SQL deployment.

## Data source: generated, not CSV

The default build calls `etl.usp_GenerateSyntheticData`, which fabricates a
larger dataset than the original CSVs (~200k+ visits over 2023-2026) while
keeping the same shape: peaked walk-in hours, Monday-heavy / Sunday-closed /
Saturday-thin staffing, fall-sports seasonality, door-to-provider rising
with load, the payer mix, MVA-mostly-open vs commercial-mostly-paid with
collection climbing by claim age, and Ardmore referring MRI out. Row counts
vary per run because the data is randomized.

The CSV path still exists as an option: `stg` staging tables plus
`etl.usp_LoadStarSchema` can BULK INSERT the `data/source-csv` files
instead. It is not used by the default run order below.

## Schemas

| Schema | Purpose |
|---|---|
| `stg`  | Raw text landing for the optional CSV load |
| `dim`  | Conformed dimensions, integer surrogate keys |
| `fact` | Facts (Visit, Claim, ProviderDay), foreign keys to dims |
| `rpt`  | Consumption views for Power BI / ad-hoc SQL |
| `etl`  | Generator and load procedures |

## Model

```
dim.Date ----+-- fact.Visit --+-- dim.Location
dim.Location  |                +-- dim.Provider
dim.Provider  |                +-- dim.PayerClass
dim.PayerClass|                +-- dim.ServiceLine
...           |                +-- dim.VisitType
              +-- fact.Claim --+-- dim.Date (Service / Submit / Paid)
              |                +-- dim.ClaimStatus
              +-- fact.ProviderDay
```

Grains: `fact.Visit` = one visit; `fact.Claim` = one current-state claim;
`fact.ProviderDay` = one provider per working day.

Business rules moved out of DAX and into the model:
- `fact.Claim.AgingBucket` / `AgingBucketSort` (persisted computed).
- `fact.Claim.OutstandingAR` = Allowed - Paid (persisted computed).
- `dim.ClaimStatus.IsUnresolved` = Open or Denied.
- `dim.PayerClass.OverviewPayerGroup` = Medicare/Medicaid rolled to Government.

## Run order

Target database is `ortho`. `00_create_database.sql` creates it, and every
other file starts with `USE ortho;`, so they run in the right database
whether you use sqlcmd or SSMS.

```bash
sqlcmd -S localhost -i "Tables/00_create_database.sql"
sqlcmd -S localhost -i "Tables/01_schemas.sql"
sqlcmd -S localhost -i "Tables/02_staging.sql"
sqlcmd -S localhost -i "Tables/03_dimensions.sql"
sqlcmd -S localhost -i "Tables/04_facts.sql"
sqlcmd -S localhost -i "Stored Procedures/etl.usp_PopulateDimDate.sql"
sqlcmd -S localhost -i "Stored Procedures/etl.usp_GenerateSyntheticData.sql"
sqlcmd -S localhost -i "Stored Procedures/etl.usp_LoadStarSchema.sql"
sqlcmd -S localhost -i "Views/rpt_reporting_views.sql"
sqlcmd -S localhost -i "Post-Deployment/10_generate_and_load.sql"
```

Or open each file in SSMS in the same order and execute (run
`00_create_database.sql` first). `etl.usp_LoadStarSchema.sql` is only
needed if you use the optional CSV load; it is otherwise inert.

## Expected result

`10_generate_and_load.sql` prints row counts and pattern checks. Because
the data is randomized, exact counts vary but should be roughly:

| Table | Rows (approx) |
|---|---|
| `fact.Visit` | ~210,000 |
| `fact.Claim` | ~185,000 |
| `fact.ProviderDay` | ~10,000 |
| `dim.Date` | 1,462 (2023-2026 + Unknown -1) |

The same script also prints payer-mix %, open-claim % by payer, and a
median/P90 door-to-provider check so you can confirm the shape.

## Sizing and reloading

Change volume or the date window via parameters (the generator is fully
idempotent, so a re-run rebuilds everything):

```sql
EXEC etl.usp_GenerateSyntheticData
     @StartDate = '2022-01-01', @EndDate = '2026-12-31', @VisitScale = 1.50;
```

## Optional: load the original CSVs instead

If you want the exact CSV data rather than generated data, run the staging
BULK INSERT + `etl.usp_LoadStarSchema` path (SQL Server 2017+, and the
service account must be able to read the CSV folder). That path is not
included in the default run order.

## Repointing Power BI

In Power Query, change each table's source from `Csv.Document(...)` to the
matching `rpt` view via `Sql.Database(server, "ortho")`. Keep the
existing surrogate-key relationships; the Aging Bucket calculated columns
in the model can then be removed because the fact now supplies them.

## Trending straight from SQL

```sql
SELECT MonthYear, Visits, NetRevenue, AvgDoorToProviderMin
FROM rpt.MonthlyVisitTrend
ORDER BY MonthYearSort;
```
