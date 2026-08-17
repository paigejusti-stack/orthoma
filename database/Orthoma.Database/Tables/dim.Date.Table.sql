/****** Object:  Table [dim].[Date]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dim].[Date](
	[DateKey] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[Year] [smallint] NOT NULL,
	[Quarter] [tinyint] NOT NULL,
	[QuarterName] [varchar](6) NOT NULL,
	[Month] [tinyint] NOT NULL,
	[MonthName] [varchar](10) NOT NULL,
	[MonthShort] [varchar](3) NOT NULL,
	[MonthStart] [date] NOT NULL,
	[MonthYear] [varchar](8) NOT NULL,
	[MonthYearSort] [int] NOT NULL,
	[Day] [tinyint] NOT NULL,
	[DayOfWeekIso] [tinyint] NOT NULL,
	[DayName] [varchar](10) NOT NULL,
	[DayShort] [varchar](3) NOT NULL,
	[WeekStart] [date] NOT NULL,
	[IsWeekend] [bit] NOT NULL,
	[IsClinicOpen] [bit] NOT NULL,
 CONSTRAINT [PK_dim_Date] PRIMARY KEY CLUSTERED 
(
	[DateKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
