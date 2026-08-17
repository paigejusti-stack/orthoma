/****** Object:  View [rpt].[ClaimAging]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Analytic: denormalized claim aging (rule-encapsulation) -------------
CREATE   VIEW [rpt].[ClaimAging] AS
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
