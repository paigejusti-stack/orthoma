/****** Object:  View [rpt].[DimDate]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
CREATE   VIEW [rpt].[DimDate] AS
SELECT DateKey, [Date], [Year], [Quarter], QuarterName, [Month], MonthName,
       MonthShort, MonthStart, MonthYear, MonthYearSort, [Day], DayOfWeekIso,
       DayName, DayShort, WeekStart, IsWeekend, IsClinicOpen
FROM dim.Date
WHERE DateKey <> -1;

GO
