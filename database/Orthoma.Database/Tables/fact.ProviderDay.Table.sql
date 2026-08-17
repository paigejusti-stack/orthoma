/****** Object:  Table [fact].[ProviderDay]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [fact].[ProviderDay](
	[ProviderDayKey] [int] IDENTITY(1,1) NOT NULL,
	[WorkDateKey] [int] NOT NULL,
	[LocationKey] [int] NOT NULL,
	[ProviderKey] [int] NOT NULL,
	[ScheduledHours] [decimal](4, 1) NULL,
	[WorkedHours] [decimal](4, 1) NULL,
 CONSTRAINT [PK_fact_ProviderDay] PRIMARY KEY CLUSTERED 
(
	[ProviderDayKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [IX_fact_PD_DateKey]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_PD_DateKey] ON [fact].[ProviderDay]
(
	[WorkDateKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_fact_PD_grain]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_fact_PD_grain] ON [fact].[ProviderDay]
(
	[WorkDateKey] ASC,
	[LocationKey] ASC,
	[ProviderKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [fact].[ProviderDay]  WITH CHECK ADD  CONSTRAINT [FK_fact_PD_Date] FOREIGN KEY([WorkDateKey])
REFERENCES [dim].[Date] ([DateKey])
GO
ALTER TABLE [fact].[ProviderDay] CHECK CONSTRAINT [FK_fact_PD_Date]
GO
ALTER TABLE [fact].[ProviderDay]  WITH CHECK ADD  CONSTRAINT [FK_fact_PD_Location] FOREIGN KEY([LocationKey])
REFERENCES [dim].[Location] ([LocationKey])
GO
ALTER TABLE [fact].[ProviderDay] CHECK CONSTRAINT [FK_fact_PD_Location]
GO
ALTER TABLE [fact].[ProviderDay]  WITH CHECK ADD  CONSTRAINT [FK_fact_PD_Provider] FOREIGN KEY([ProviderKey])
REFERENCES [dim].[Provider] ([ProviderKey])
GO
ALTER TABLE [fact].[ProviderDay] CHECK CONSTRAINT [FK_fact_PD_Provider]
GO
