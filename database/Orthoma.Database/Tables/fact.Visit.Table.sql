/****** Object:  Table [fact].[Visit]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [fact].[Visit](
	[VisitKey] [int] IDENTITY(1,1) NOT NULL,
	[VisitID] [int] NOT NULL,
	[VisitDateKey] [int] NOT NULL,
	[LocationKey] [int] NOT NULL,
	[ProviderKey] [int] NOT NULL,
	[PayerClassKey] [int] NOT NULL,
	[ServiceLineKey] [int] NOT NULL,
	[VisitTypeKey] [int] NOT NULL,
	[PayerName] [varchar](80) NULL,
	[BodyPart] [varchar](40) NULL,
	[ReferralSource] [varchar](60) NULL,
	[ArrivalTime] [time](0) NULL,
	[ArrivalHour] [tinyint] NULL,
	[MinutesToRoom] [int] NULL,
	[MinutesToProvider] [int] NULL,
	[VisitDurationMinutes] [int] NULL,
	[XrayPerformed] [bit] NULL,
	[MRIOrdered] [bit] NULL,
	[MRILocation] [varchar](20) NULL,
	[InjectionPerformed] [bit] NULL,
	[ChargeAmount] [decimal](10, 2) NULL,
	[AllowedAmount] [decimal](10, 2) NULL,
 CONSTRAINT [PK_fact_Visit] PRIMARY KEY CLUSTERED 
(
	[VisitKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_fact_Visit_VisitID] UNIQUE NONCLUSTERED 
(
	[VisitID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [IX_fact_Visit_DateKey]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_Visit_DateKey] ON [fact].[Visit]
(
	[VisitDateKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_fact_Visit_LocationKey]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_Visit_LocationKey] ON [fact].[Visit]
(
	[LocationKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_fact_Visit_PayerClassKey]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_Visit_PayerClassKey] ON [fact].[Visit]
(
	[PayerClassKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_fact_Visit_ProviderKey]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_Visit_ProviderKey] ON [fact].[Visit]
(
	[ProviderKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [fact].[Visit]  WITH CHECK ADD  CONSTRAINT [FK_fact_Visit_Date] FOREIGN KEY([VisitDateKey])
REFERENCES [dim].[Date] ([DateKey])
GO
ALTER TABLE [fact].[Visit] CHECK CONSTRAINT [FK_fact_Visit_Date]
GO
ALTER TABLE [fact].[Visit]  WITH CHECK ADD  CONSTRAINT [FK_fact_Visit_Location] FOREIGN KEY([LocationKey])
REFERENCES [dim].[Location] ([LocationKey])
GO
ALTER TABLE [fact].[Visit] CHECK CONSTRAINT [FK_fact_Visit_Location]
GO
ALTER TABLE [fact].[Visit]  WITH CHECK ADD  CONSTRAINT [FK_fact_Visit_PayerClass] FOREIGN KEY([PayerClassKey])
REFERENCES [dim].[PayerClass] ([PayerClassKey])
GO
ALTER TABLE [fact].[Visit] CHECK CONSTRAINT [FK_fact_Visit_PayerClass]
GO
ALTER TABLE [fact].[Visit]  WITH CHECK ADD  CONSTRAINT [FK_fact_Visit_Provider] FOREIGN KEY([ProviderKey])
REFERENCES [dim].[Provider] ([ProviderKey])
GO
ALTER TABLE [fact].[Visit] CHECK CONSTRAINT [FK_fact_Visit_Provider]
GO
ALTER TABLE [fact].[Visit]  WITH CHECK ADD  CONSTRAINT [FK_fact_Visit_ServiceLine] FOREIGN KEY([ServiceLineKey])
REFERENCES [dim].[ServiceLine] ([ServiceLineKey])
GO
ALTER TABLE [fact].[Visit] CHECK CONSTRAINT [FK_fact_Visit_ServiceLine]
GO
ALTER TABLE [fact].[Visit]  WITH CHECK ADD  CONSTRAINT [FK_fact_Visit_VisitType] FOREIGN KEY([VisitTypeKey])
REFERENCES [dim].[VisitType] ([VisitTypeKey])
GO
ALTER TABLE [fact].[Visit] CHECK CONSTRAINT [FK_fact_Visit_VisitType]
GO
