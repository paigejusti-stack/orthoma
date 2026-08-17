/****** Object:  Table [stg].[ProviderDays]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [stg].[ProviderDays](
	[WorkDate] [nvarchar](20) NULL,
	[Location] [nvarchar](60) NULL,
	[Provider] [nvarchar](100) NULL,
	[ProviderType] [nvarchar](10) NULL,
	[ScheduledHours] [nvarchar](10) NULL,
	[WorkedHours] [nvarchar](10) NULL
) ON [PRIMARY]
GO
