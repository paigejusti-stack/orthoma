/****** Object:  View [rpt].[FactClaim]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [rpt].[FactClaim] AS
SELECT ClaimKey, ClaimID, VisitID, VisitKey, ServiceDateKey, SubmitDateKey,
       PaidDateKey, LocationKey, PayerClassKey, ClaimStatusKey, PayerName,
       BilledAmount, AllowedAmount, PaidAmount, OutstandingAR,
       ClaimAgeDays, AgeBand, AgingBucket, AgingBucketSort
FROM fact.Claim;

GO
