USE ortho;
GO

/*  Orthoma star-schema build - 01 Schemas
    ------------------------------------------------------------------
    Creates the landing (stg), dimensional (dim / fact) and reporting
    (rpt) schemas, plus an etl schema for the load procedures.

    Layer contract:
      stg   raw text landing, one table per CSV, no typing
      dim   conformed dimensions, integer surrogate keys
      fact  business-process facts, foreign keys to dims only
      rpt   consumption views for Power BI / ad-hoc SQL
      etl   load and maintenance procedures

    Idempotent: safe to re-run.
    Run order: 01 -> 02 -> 03 -> 04 -> procs -> views -> Post-Deployment.
*/
IF SCHEMA_ID('stg')  IS NULL EXEC ('CREATE SCHEMA stg');
IF SCHEMA_ID('dim')  IS NULL EXEC ('CREATE SCHEMA dim');
IF SCHEMA_ID('fact') IS NULL EXEC ('CREATE SCHEMA fact');
IF SCHEMA_ID('rpt')  IS NULL EXEC ('CREATE SCHEMA rpt');
IF SCHEMA_ID('etl')  IS NULL EXEC ('CREATE SCHEMA etl');
GO
