/****** Object:  Table [stg].[Claims]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [stg].[Claims](
	[ClaimID] [nvarchar](20) NULL,
	[VisitID] [nvarchar](20) NULL,
	[ServiceDate] [nvarchar](20) NULL,
	[SubmitDate] [nvarchar](20) NULL,
	[Location] [nvarchar](60) NULL,
	[PayerClass] [nvarchar](60) NULL,
	[PayerName] [nvarchar](80) NULL,
	[BilledAmount] [nvarchar](20) NULL,
	[AllowedAmount] [nvarchar](20) NULL,
	[PaidAmount] [nvarchar](20) NULL,
	[ClaimStatus] [nvarchar](20) NULL,
	[PaidDate] [nvarchar](20) NULL,
	[ClaimAgeDays] [nvarchar](10) NULL,
	[AgeBand] [nvarchar](20) NULL
) ON [PRIMARY]
GO
