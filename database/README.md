# Database Status

The repository contains a **local SQL Server star-schema build** over the
synthetic Orthoma data. It is a development/prototype layer, not a
production or Azure SQL deployment, and it has not yet been verified by an
executed run against a live SQL Server instance in this repository.

All data remains synthetic. No real patient, visit, or claim data is used.

## What now exists

`database/Orthoma.Database/` holds a runnable dimensional model:

- `Tables/` — create-database, schemas, staging, 7 dimensions, 3 facts.
- `Stored Procedures/` — `etl.usp_PopulateDimDate`,
  `etl.usp_GenerateSyntheticData`, `etl.usp_LoadStarSchema`.
- `Views/` — `rpt` consumption views for Power BI and ad-hoc SQL.
- `Post-Deployment/` — generate-and-load script.
- `BUILD_AND_RUN.md` — schemas, model diagram, run order, sizing.

The default build **generates** a fresh synthetic dataset directly into the
star schema (target database `ortho`) via `etl.usp_GenerateSyntheticData` —
larger than the original CSVs (~200k+ visits over 2023-2026) but the same
shape. Integer surrogate keys replace the name-based Provider/Location
dimensions used by the current CSV-fed semantic model, and the aging-bucket
and outstanding-A/R rules move into the fact as persisted computed columns.

Loading the exact `data/source-csv` files instead remains an option through
the `stg` staging tables and `etl.usp_LoadStarSchema` (see `BUILD_AND_RUN.md`).

## Current implemented source (Power BI)

Power BI still reads the CSV files in `data/source-csv` through Power
Query. Repointing the semantic model at the `rpt` views is a documented
next step (see `BUILD_AND_RUN.md`), not yet done.

## Honesty boundary

- This build is written and reviewable in source control. It has **not**
  been proven by a captured, executed run here. Row-count targets in the
  seed script are the acceptance check to run in your own instance.
- It is SQL Server (local), not Azure SQL. Do not describe it as Azure SQL.
- `AllowedAmount` remains modeled expected reimbursement, not a contracted
  fee schedule or cash ledger.

See [SQL and data lineage](../docs/sql-and-data-lineage.md) for the
verified current-state lineage and evidence requirements.
