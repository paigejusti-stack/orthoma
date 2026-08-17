/****** Object:  Table [fact].[Claim]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [fact].[Claim](
	[ClaimKey] [int] IDENTITY(1,1) NOT NULL,
	[ClaimID] [int] NOT NULL,
	[VisitID] [int] NOT NULL,
	[VisitKey] [int] NULL,
	[ServiceDateKey] [int] NOT NULL,
	[SubmitDateKey] [int] NOT NULL,
	[PaidDateKey] [int] NOT NULL,
	[LocationKey] [int] NOT NULL,
	[PayerClassKey] [int] NOT NULL,
	[ClaimStatusKey] [int] NOT NULL,
	[PayerName] [varchar](80) NULL,
	[BilledAmount] [decimal](10, 2) NULL,
	[AllowedAmount] [decimal](10, 2) NULL,
	[PaidAmount] [decimal](10, 2) NULL,
	[OutstandingAR]  AS (CONVERT([decimal](10,2),isnull([AllowedAmount],(0))-isnull([PaidAmount],(0)))) PERSISTED,
	[ClaimAgeDays] [int] NULL,
	[AgeBand] [varchar](20) NULL,
	[AgingBucketSort]  AS (case when [ClaimAgeDays]<(0) then NULL when [ClaimAgeDays]<=(60) then (1) when [ClaimAgeDays]<=(90) then (2) when [ClaimAgeDays]<=(120) then (3) else (4) end) PERSISTED,
	[AgingBucket]  AS (case when [ClaimAgeDays]<(0) then NULL when [ClaimAgeDays]<=(60) then '0-60' when [ClaimAgeDays]<=(90) then '61-90' when [ClaimAgeDays]<=(120) then '91-120' else '121+' end) PERSISTED,
 CONSTRAINT [PK_fact_Claim] PRIMARY KEY CLUSTERED 
(
	[ClaimKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_fact_Claim_ClaimID] UNIQUE NONCLUSTERED 
(
	[ClaimID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
GO
/****** Object:  Index [IX_fact_Claim_AgingSort]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_Claim_AgingSort] ON [fact].[Claim]
(
	[AgingBucketSort] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_fact_Claim_PaidDateKey]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_Claim_PaidDateKey] ON [fact].[Claim]
(
	[PaidDateKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_fact_Claim_PayerClass]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_Claim_PayerClass] ON [fact].[Claim]
(
	[PayerClassKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_fact_Claim_Status]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_Claim_Status] ON [fact].[Claim]
(
	[ClaimStatusKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_fact_Claim_SvcDateKey]    Script Date: 8/16/2026 12:23:18 PM ******/
CREATE NONCLUSTERED INDEX [IX_fact_Claim_SvcDateKey] ON [fact].[Claim]
(
	[ServiceDateKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [fact].[Claim]  WITH CHECK ADD  CONSTRAINT [FK_fact_Claim_Location] FOREIGN KEY([LocationKey])
REFERENCES [dim].[Location] ([LocationKey])
GO
ALTER TABLE [fact].[Claim] CHECK CONSTRAINT [FK_fact_Claim_Location]
GO
ALTER TABLE [fact].[Claim]  WITH CHECK ADD  CONSTRAINT [FK_fact_Claim_PaidDate] FOREIGN KEY([PaidDateKey])
REFERENCES [dim].[Date] ([DateKey])
GO
ALTER TABLE [fact].[Claim] CHECK CONSTRAINT [FK_fact_Claim_PaidDate]
GO
ALTER TABLE [fact].[Claim]  WITH CHECK ADD  CONSTRAINT [FK_fact_Claim_PayerClass] FOREIGN KEY([PayerClassKey])
REFERENCES [dim].[PayerClass] ([PayerClassKey])
GO
ALTER TABLE [fact].[Claim] CHECK CONSTRAINT [FK_fact_Claim_PayerClass]
GO
ALTER TABLE [fact].[Claim]  WITH CHECK ADD  CONSTRAINT [FK_fact_Claim_Status] FOREIGN KEY([ClaimStatusKey])
REFERENCES [dim].[ClaimStatus] ([ClaimStatusKey])
GO
ALTER TABLE [fact].[Claim] CHECK CONSTRAINT [FK_fact_Claim_Status]
GO
ALTER TABLE [fact].[Claim]  WITH CHECK ADD  CONSTRAINT [FK_fact_Claim_SubDate] FOREIGN KEY([SubmitDateKey])
REFERENCES [dim].[Date] ([DateKey])
GO
ALTER TABLE [fact].[Claim] CHECK CONSTRAINT [FK_fact_Claim_SubDate]
GO
ALTER TABLE [fact].[Claim]  WITH CHECK ADD  CONSTRAINT [FK_fact_Claim_SvcDate] FOREIGN KEY([ServiceDateKey])
REFERENCES [dim].[Date] ([DateKey])
GO
ALTER TABLE [fact].[Claim] CHECK CONSTRAINT [FK_fact_Claim_SvcDate]
GO
ALTER TABLE [fact].[Claim]  WITH CHECK ADD  CONSTRAINT [FK_fact_Claim_Visit] FOREIGN KEY([VisitKey])
REFERENCES [fact].[Visit] ([VisitKey])
GO
ALTER TABLE [fact].[Claim] CHECK CONSTRAINT [FK_fact_Claim_Visit]
GO
