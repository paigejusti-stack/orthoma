/****** Object:  View [rpt].[MonthlyVisitTrend]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Analytic: monthly visit + revenue trend (trending demo) ------------
CREATE   VIEW [rpt].[MonthlyVisitTrend] AS
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
