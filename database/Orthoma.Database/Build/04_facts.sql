USE ortho;
GO

/*  Orthoma star-schema build - 04 Facts
    ------------------------------------------------------------------
    Three business-process facts. Foreign keys point only at dimensions
    (and fact.Visit for the claim -> visit drill path). Aging bucket and
    outstanding A/R are persisted computed columns, so the business rule
    lives in the model instead of being re-derived in DAX on every page.
*/

-- fact.Visit ---------------------------------------------------------
-- Grain: one row per patient visit.
DROP TABLE IF EXISTS fact.Visit;
CREATE TABLE fact.Visit (
    VisitKey             int IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_Visit PRIMARY KEY,
    VisitID              int           NOT NULL,   -- business key (degenerate)
    VisitDateKey         int           NOT NULL,
    LocationKey          int           NOT NULL,
    ProviderKey          int           NOT NULL,
    PayerClassKey        int           NOT NULL,
    ServiceLineKey       int           NOT NULL,
    VisitTypeKey         int           NOT NULL,
    PayerName            varchar(80)   NULL,       -- detailed payer (degenerate)
    BodyPart             varchar(40)   NULL,
    ReferralSource       varchar(60)   NULL,
    ArrivalTime          time(0)       NULL,
    ArrivalHour          tinyint       NULL,
    MinutesToRoom        int           NULL,
    MinutesToProvider    int           NULL,       -- headline access metric
    VisitDurationMinutes int           NULL,
    XrayPerformed        bit           NULL,
    MRIOrdered           bit           NULL,
    MRILocation          varchar(20)   NULL,       -- In-House / Referred Out / NULL
    InjectionPerformed   bit           NULL,
    ChargeAmount         decimal(10,2) NULL,
    AllowedAmount        decimal(10,2) NULL,        -- expected reimbursement, not cash
    CONSTRAINT UQ_fact_Visit_VisitID UNIQUE (VisitID),
    CONSTRAINT FK_fact_Visit_Date        FOREIGN KEY (VisitDateKey)   REFERENCES dim.Date(DateKey),
    CONSTRAINT FK_fact_Visit_Location    FOREIGN KEY (LocationKey)    REFERENCES dim.Location(LocationKey),
    CONSTRAINT FK_fact_Visit_Provider    FOREIGN KEY (ProviderKey)    REFERENCES dim.Provider(ProviderKey),
    CONSTRAINT FK_fact_Visit_PayerClass  FOREIGN KEY (PayerClassKey)  REFERENCES dim.PayerClass(PayerClassKey),
    CONSTRAINT FK_fact_Visit_ServiceLine FOREIGN KEY (ServiceLineKey) REFERENCES dim.ServiceLine(ServiceLineKey),
    CONSTRAINT FK_fact_Visit_VisitType   FOREIGN KEY (VisitTypeKey)   REFERENCES dim.VisitType(VisitTypeKey)
);
CREATE INDEX IX_fact_Visit_DateKey       ON fact.Visit(VisitDateKey);
CREATE INDEX IX_fact_Visit_LocationKey   ON fact.Visit(LocationKey);
CREATE INDEX IX_fact_Visit_ProviderKey   ON fact.Visit(ProviderKey);
CREATE INDEX IX_fact_Visit_PayerClassKey ON fact.Visit(PayerClassKey);
GO

-- fact.Claim ---------------------------------------------------------
-- Grain: one current-state row per claim (cash/self-pay visits generate
-- no claim). PaidDateKey = -1 when unpaid. OutstandingAR / AgingBucket
-- are persisted so aging is a stored, indexable attribute.
DROP TABLE IF EXISTS fact.Claim;
CREATE TABLE fact.Claim (
    ClaimKey        int IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_Claim PRIMARY KEY,
    ClaimID         int           NOT NULL,   -- business key (degenerate)
    VisitID         int           NOT NULL,   -- degenerate, for reference
    VisitKey        int           NULL,       -- surrogate drill path to fact.Visit
    ServiceDateKey  int           NOT NULL,
    SubmitDateKey   int           NOT NULL,
    PaidDateKey     int           NOT NULL,   -- -1 = unpaid
    LocationKey     int           NOT NULL,
    PayerClassKey   int           NOT NULL,
    ClaimStatusKey  int           NOT NULL,
    PayerName       varchar(80)   NULL,
    BilledAmount    decimal(10,2) NULL,
    AllowedAmount   decimal(10,2) NULL,
    PaidAmount      decimal(10,2) NULL,
    OutstandingAR   AS (CONVERT(decimal(10,2), ISNULL(AllowedAmount,0) - ISNULL(PaidAmount,0))) PERSISTED,
    ClaimAgeDays    int           NULL,
    AgeBand         varchar(20)   NULL,
    AgingBucketSort AS (CASE WHEN ClaimAgeDays < 0   THEN NULL
                             WHEN ClaimAgeDays <= 60  THEN 1
                             WHEN ClaimAgeDays <= 90  THEN 2
                             WHEN ClaimAgeDays <= 120 THEN 3
                             ELSE 4 END) PERSISTED,
    AgingBucket     AS (CASE WHEN ClaimAgeDays < 0   THEN NULL
                             WHEN ClaimAgeDays <= 60  THEN '0-60'
                             WHEN ClaimAgeDays <= 90  THEN '61-90'
                             WHEN ClaimAgeDays <= 120 THEN '91-120'
                             ELSE '121+' END) PERSISTED,
    CONSTRAINT UQ_fact_Claim_ClaimID UNIQUE (ClaimID),
    CONSTRAINT FK_fact_Claim_SvcDate    FOREIGN KEY (ServiceDateKey) REFERENCES dim.Date(DateKey),
    CONSTRAINT FK_fact_Claim_SubDate    FOREIGN KEY (SubmitDateKey)  REFERENCES dim.Date(DateKey),
    CONSTRAINT FK_fact_Claim_PaidDate   FOREIGN KEY (PaidDateKey)    REFERENCES dim.Date(DateKey),
    CONSTRAINT FK_fact_Claim_Location   FOREIGN KEY (LocationKey)    REFERENCES dim.Location(LocationKey),
    CONSTRAINT FK_fact_Claim_PayerClass FOREIGN KEY (PayerClassKey)  REFERENCES dim.PayerClass(PayerClassKey),
    CONSTRAINT FK_fact_Claim_Status     FOREIGN KEY (ClaimStatusKey) REFERENCES dim.ClaimStatus(ClaimStatusKey),
    CONSTRAINT FK_fact_Claim_Visit      FOREIGN KEY (VisitKey)       REFERENCES fact.Visit(VisitKey)
);
CREATE INDEX IX_fact_Claim_SvcDateKey  ON fact.Claim(ServiceDateKey);
CREATE INDEX IX_fact_Claim_PaidDateKey ON fact.Claim(PaidDateKey);
CREATE INDEX IX_fact_Claim_PayerClass  ON fact.Claim(PayerClassKey);
CREATE INDEX IX_fact_Claim_Status      ON fact.Claim(ClaimStatusKey);
CREATE INDEX IX_fact_Claim_AgingSort   ON fact.Claim(AgingBucketSort);
GO

-- fact.ProviderDay ---------------------------------------------------
-- Grain: one row per provider per working day. This is the grain the
-- Page 2 load-vs-wait scatter should actually plot.
DROP TABLE IF EXISTS fact.ProviderDay;
CREATE TABLE fact.ProviderDay (
    ProviderDayKey int IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_ProviderDay PRIMARY KEY,
    WorkDateKey    int          NOT NULL,
    LocationKey    int          NOT NULL,
    ProviderKey    int          NOT NULL,
    ScheduledHours decimal(4,1) NULL,
    WorkedHours    decimal(4,1) NULL,
    CONSTRAINT FK_fact_PD_Date     FOREIGN KEY (WorkDateKey) REFERENCES dim.Date(DateKey),
    CONSTRAINT FK_fact_PD_Location FOREIGN KEY (LocationKey) REFERENCES dim.Location(LocationKey),
    CONSTRAINT FK_fact_PD_Provider FOREIGN KEY (ProviderKey) REFERENCES dim.Provider(ProviderKey)
);
CREATE INDEX IX_fact_PD_DateKey ON fact.ProviderDay(WorkDateKey);
CREATE UNIQUE INDEX UX_fact_PD_grain ON fact.ProviderDay(WorkDateKey, LocationKey, ProviderKey);
GO
