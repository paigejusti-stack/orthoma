/****** Object:  View [rpt].[FactVisit]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Facts --------------------------------------------------------------
CREATE   VIEW [rpt].[FactVisit] AS
SELECT VisitKey, VisitID, VisitDateKey, LocationKey, ProviderKey, PayerClassKey,
       ServiceLineKey, VisitTypeKey, PayerName, BodyPart, ReferralSource,
       ArrivalTime, ArrivalHour, MinutesToRoom, MinutesToProvider,
       VisitDurationMinutes, XrayPerformed, MRIOrdered, MRILocation,
       InjectionPerformed, ChargeAmount, AllowedAmount
FROM fact.Visit;

GO
