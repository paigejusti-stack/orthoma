USE ortho;
GO

/*  Orthoma star-schema build - 10 Generate and load
    ------------------------------------------------------------------
    Generates a fresh synthetic dataset straight into the star schema.
    No CSV files required. Run AFTER 01-04, the three etl procs, and the
    rpt views exist.

    The generator rebuilds dim.Date, seeds the reference dimensions, and
    populates the three facts. Defaults span 2023-01-01 .. 2026-12-31 at
    scale 1.00 (~200k+ visits, about 2x the original CSVs).

    To make it bigger or change the window, pass parameters, e.g.:
        EXEC etl.usp_GenerateSyntheticData
             @StartDate = '2022-01-01', @EndDate = '2026-12-31',
             @VisitScale = 1.50;
*/
SET NOCOUNT ON;

EXEC etl.usp_GenerateSyntheticData
     @StartDate  = '2023-01-01',
     @EndDate    = '2026-12-31',
     @VisitScale = 1.00;

------------------------------------------------------------------
-- Row counts (values vary per run; all should exceed the CSV totals)
------------------------------------------------------------------
SELECT 'dim.Date'          AS TableName, COUNT(*) AS Rows FROM dim.Date
UNION ALL SELECT 'dim.Location',          COUNT(*) FROM dim.Location
UNION ALL SELECT 'dim.Provider',          COUNT(*) FROM dim.Provider
UNION ALL SELECT 'dim.PayerClass',        COUNT(*) FROM dim.PayerClass
UNION ALL SELECT 'fact.Visit',            COUNT(*) FROM fact.Visit
UNION ALL SELECT 'fact.Claim',            COUNT(*) FROM fact.Claim
UNION ALL SELECT 'fact.ProviderDay',      COUNT(*) FROM fact.ProviderDay;

------------------------------------------------------------------
-- Sanity checks: the patterns the report relies on
------------------------------------------------------------------
-- Payer mix by visit share (expect ~ Commercial 44 / MVA 18 / Cash 12 ...)
SELECT pc.PayerClassName,
       COUNT(*)                                          AS Visits,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS decimal(5,1)) AS PctOfVisits
FROM fact.Visit v
JOIN dim.PayerClass pc ON pc.PayerClassKey = v.PayerClassKey
GROUP BY pc.PayerClassName
ORDER BY Visits DESC;

-- Open-claim share by payer (expect MVA high, Commercial low)
SELECT pc.PayerClassName,
       CAST(100.0 * SUM(CASE WHEN cs.ClaimStatusName = 'Open' THEN 1 ELSE 0 END)
            / COUNT(*) AS decimal(5,1)) AS PctOpen
FROM fact.Claim c
JOIN dim.PayerClass  pc ON pc.PayerClassKey  = c.PayerClassKey
JOIN dim.ClaimStatus cs ON cs.ClaimStatusKey = c.ClaimStatusKey
GROUP BY pc.PayerClassName
ORDER BY PctOpen DESC;

-- Door-to-provider distribution (expect median low-30s, P90 low-50s)
SELECT
    MedianD2P = (SELECT DISTINCT PERCENTILE_CONT(0.50)
                 WITHIN GROUP (ORDER BY CAST(MinutesToProvider AS float)) OVER () FROM fact.Visit),
    P90D2P    = (SELECT DISTINCT PERCENTILE_CONT(0.90)
                 WITHIN GROUP (ORDER BY CAST(MinutesToProvider AS float)) OVER () FROM fact.Visit);

-- First 6 months of the visit + revenue trend
SELECT TOP (6) MonthYear, Visits, NetRevenue, AvgDoorToProviderMin
FROM rpt.MonthlyVisitTrend
ORDER BY MonthYearSort;
GO
