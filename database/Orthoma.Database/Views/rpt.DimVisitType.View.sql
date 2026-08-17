/****** Object:  View [rpt].[DimVisitType]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW [rpt].[DimVisitType] AS
SELECT VisitTypeKey, VisitTypeName FROM dim.VisitType;

GO
