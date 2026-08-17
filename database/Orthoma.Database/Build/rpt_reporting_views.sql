USE ortho;
GO

/*  Orthoma star-schema build - rpt reporting views
    ------------------------------------------------------------------
    Stable consumption contract for Power BI (repoint Power Query at
    these) and for ad-hoc SQL. Dimensions and facts are exposed cleanly;
    two analytic views (ClaimAging, MonthlyVisitTrend) demonstrate
    trending straight from SQL.

    rpt.DimDate excludes the Unknown (-1) member so it can be marked as
    a Power BI date table. Unpaid claims (PaidDateKey = -1) therefore
    show blank on the paid-date relationship, which is correct.
*/

-- Dimensions ---------------------------------------------------------
CREATE OR ALTER VIEW rpt.DimDate AS
SELECT DateKey, [Date], [Year], [Quarter], QuarterName, [Month], MonthName,
       MonthShort, MonthStart, MonthYear, MonthYearSort, [Day], DayOfWeekIso,
       DayName, DayShort, WeekStart, IsWeekend, IsClinicOpen
FROM dim.Date
WHERE DateKey <> -1;
GO

CREATE OR ALTER VIEW rpt.DimLocation AS
SELECT LocationKey, LocationName FROM dim.Location;
GO

CREATE OR ALTER VIEW rpt.DimProvider AS
SELECT ProviderKey, ProviderName, ProviderType FROM dim.Provider;
GO

CREATE OR ALTER VIEW rpt.DimPayerClass AS
SELECT PayerClassKey, PayerClassName, OverviewPayerGroup FROM dim.PayerClass;
GO

CREATE OR ALTER VIEW rpt.DimServiceLine AS
SELECT ServiceLineKey, ServiceLineName FROM dim.ServiceLine;
GO

CREATE OR ALTER VIEW rpt.DimVisitType AS
SELECT VisitTypeKey, VisitTypeName FROM dim.VisitType;
GO

CREATE OR ALTER VIEW rpt.DimClaimStatus AS
SELECT ClaimStatusKey, ClaimStatusName, IsUnresolved FROM dim.ClaimStatus;
GO

-- Facts --------------------------------------------------------------
CREATE OR ALTER VIEW rpt.FactVisit AS
SELECT VisitKey, VisitID, VisitDateKey, LocationKey, ProviderKey, PayerClassKey,
       ServiceLineKey, VisitTypeKey, PayerName, BodyPart, ReferralSource,
       ArrivalTime, ArrivalHour, MinutesToRoom, MinutesToProvider,
       VisitDurationMinutes, XrayPerformed, MRIOrdered, MRILocation,
       InjectionPerformed, ChargeAmount, AllowedAmount
FROM fact.Visit;
GO

CREATE OR ALTER VIEW rpt.FactClaim AS
SELECT ClaimKey, ClaimID, VisitID, VisitKey, ServiceDateKey, SubmitDateKey,
       PaidDateKey, LocationKey, PayerClassKey, ClaimStatusKey, PayerName,
       BilledAmount, AllowedAmount, PaidAmount, OutstandingAR,
       ClaimAgeDays, AgeBand, AgingBucket, AgingBucketSort
FROM fact.Claim;
GO

CREATE OR ALTER VIEW rpt.FactProviderDay AS
SELECT ProviderDayKey, WorkDateKey, LocationKey, ProviderKey,
       ScheduledHours, WorkedHours
FROM fact.ProviderDay;
GO

-- Analytic: denormalized claim aging (rule-encapsulation) -------------
CREATE OR ALTER VIEW rpt.ClaimAging AS
SELECT
    c.ClaimID,
    d.[Date]            AS ServiceDate,
    loc.LocationName,
    pc.PayerClassName,
    pc.OverviewPayerGroup,
    cs.ClaimStatusName,
    cs.IsUnresolved,
    c.AllowedAmount,
    c.PaidAmount,
    c.OutstandingAR,
    c.ClaimAgeDays,
    c.AgingBucket,
    c.AgingBucketSort
FROM fact.Claim       c
JOIN dim.Date         d   ON d.DateKey        = c.ServiceDateKey
JOIN dim.Location     loc ON loc.LocationKey  = c.LocationKey
JOIN dim.PayerClass   pc  ON pc.PayerClassKey = c.PayerClassKey
JOIN dim.ClaimStatus  cs  ON cs.ClaimStatusKey = c.ClaimStatusKey;
GO

-- Analytic: monthly visit + revenue trend (trending demo) ------------
CREATE OR ALTER VIEW rpt.MonthlyVisitTrend AS
SELECT
    d.MonthYearSort,
    d.MonthYear,
    d.[Year],
    d.[Month],
    COUNT(*)                                                  AS Visits,
    CAST(SUM(fv.AllowedAmount) AS decimal(14,2))              AS NetRevenue,
    CAST(AVG(CAST(fv.AllowedAmount AS float)) AS decimal(10,2)) AS AvgAllowedPerVisit,
    CAST(AVG(CAST(fv.MinutesToProvider AS float)) AS decimal(6,1)) AS AvgDoorToProviderMin
FROM fact.Visit fv
JOIN dim.Date   d ON d.DateKey = fv.VisitDateKey
WHERE fv.MinutesToProvider >= 0
GROUP BY d.MonthYearSort, d.MonthYear, d.[Year], d.[Month];
GO
