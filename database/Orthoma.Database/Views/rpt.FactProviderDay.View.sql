/****** Object:  View [rpt].[FactProviderDay]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [rpt].[FactProviderDay] AS
SELECT ProviderDayKey, WorkDateKey, LocationKey, ProviderKey,
       ScheduledHours, WorkedHours
FROM fact.ProviderDay;

GO
