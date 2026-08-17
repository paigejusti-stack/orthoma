/****** Object:  Table [stg].[Visits]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [stg].[Visits](
	[VisitID] [nvarchar](20) NULL,
	[VisitDate] [nvarchar](20) NULL,
	[ArrivalTime] [nvarchar](20) NULL,
	[ArrivalHour] [nvarchar](10) NULL,
	[DayOfWeek] [nvarchar](20) NULL,
	[Location] [nvarchar](60) NULL,
	[Provider] [nvarchar](100) NULL,
	[ProviderType] [nvarchar](10) NULL,
	[PayerClass] [nvarchar](60) NULL,
	[PayerName] [nvarchar](80) NULL,
	[ServiceLine] [nvarchar](60) NULL,
	[BodyPart] [nvarchar](40) NULL,
	[VisitType] [nvarchar](40) NULL,
	[ReferralSource] [nvarchar](60) NULL,
	[MinutesToRoom] [nvarchar](10) NULL,
	[MinutesToProvider] [nvarchar](10) NULL,
	[VisitDurationMinutes] [nvarchar](10) NULL,
	[XrayPerformed] [nvarchar](5) NULL,
	[MRIOrdered] [nvarchar](5) NULL,
	[MRILocation] [nvarchar](20) NULL,
	[InjectionPerformed] [nvarchar](5) NULL,
	[ChargeAmount] [nvarchar](20) NULL,
	[AllowedAmount] [nvarchar](20) NULL
) ON [PRIMARY]
GO
