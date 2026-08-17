/****** Object:  StoredProcedure [etl].[usp_LoadStarSchema]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*  Orthoma star-schema build - etl.usp_LoadStarSchema
    ------------------------------------------------------------------
    Transforms the stg landing tables into the dim / fact star.
    Assumes stg tables are already loaded (Post-Deployment does the
    BULK INSERT) and dim.Date is already populated.

    Steps:
      1. Clear facts (child first) and non-date dims; reseed identities.
      2. Upsert conformed dims from distinct staging values.
      3. Load fact.Visit, fact.ProviderDay, then fact.Claim (needs VisitKey).

    Idempotent: a full re-run reproduces identical output.
*/
CREATE   PROCEDURE [etl].[usp_LoadStarSchema]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRAN;

    ------------------------------------------------------------------
    -- 1. Clear (facts child-first, then dims) and reseed identities
    ------------------------------------------------------------------
    DELETE FROM fact.Claim;
    DELETE FROM fact.ProviderDay;
    DELETE FROM fact.Visit;
    DELETE FROM dim.ClaimStatus;
    DELETE FROM dim.VisitType;
    DELETE FROM dim.ServiceLine;
    DELETE FROM dim.PayerClass;
    DELETE FROM dim.Provider;
    DELETE FROM dim.Location;

    DBCC CHECKIDENT('fact.Claim',       RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT('fact.ProviderDay', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT('fact.Visit',       RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT('dim.ClaimStatus',  RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT('dim.VisitType',    RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT('dim.ServiceLine',  RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT('dim.PayerClass',   RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT('dim.Provider',     RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT('dim.Location',     RESEED, 0) WITH NO_INFOMSGS;

    ------------------------------------------------------------------
    -- 2. Conformed dimensions
    ------------------------------------------------------------------
    INSERT dim.Location (LocationName)
    SELECT DISTINCT LTRIM(RTRIM(Location))
    FROM (
        SELECT Location FROM stg.Visits
        UNION SELECT Location FROM stg.Claims
        UNION SELECT Location FROM stg.ProviderDays
    ) x
    WHERE NULLIF(LTRIM(RTRIM(Location)), '') IS NOT NULL;

    INSERT dim.Provider (ProviderName, ProviderType)
    SELECT ProviderName, MAX(ProviderType)
    FROM (
        SELECT LTRIM(RTRIM(Provider)) AS ProviderName, ProviderType FROM stg.Visits
        UNION ALL
        SELECT LTRIM(RTRIM(Provider)), ProviderType FROM stg.ProviderDays
    ) x
    WHERE NULLIF(ProviderName, '') IS NOT NULL
    GROUP BY ProviderName;

    INSERT dim.PayerClass (PayerClassName, OverviewPayerGroup)
    SELECT pc,
           CASE WHEN pc IN ('Medicare','Medicaid') THEN 'Government' ELSE pc END
    FROM (
        SELECT DISTINCT LTRIM(RTRIM(PayerClass)) AS pc
        FROM stg.Visits
        WHERE NULLIF(LTRIM(RTRIM(PayerClass)), '') IS NOT NULL
    ) x;

    INSERT dim.ServiceLine (ServiceLineName)
    SELECT DISTINCT LTRIM(RTRIM(ServiceLine))
    FROM stg.Visits
    WHERE NULLIF(LTRIM(RTRIM(ServiceLine)), '') IS NOT NULL;

    INSERT dim.VisitType (VisitTypeName)
    SELECT DISTINCT LTRIM(RTRIM(VisitType))
    FROM stg.Visits
    WHERE NULLIF(LTRIM(RTRIM(VisitType)), '') IS NOT NULL;

    INSERT dim.ClaimStatus (ClaimStatusName, IsUnresolved)
    SELECT DISTINCT LTRIM(RTRIM(ClaimStatus)),
           CASE WHEN LTRIM(RTRIM(ClaimStatus)) IN ('Open','Denied') THEN 1 ELSE 0 END
    FROM stg.Claims
    WHERE NULLIF(LTRIM(RTRIM(ClaimStatus)), '') IS NOT NULL;

    ------------------------------------------------------------------
    -- 3a. fact.Visit
    ------------------------------------------------------------------
    INSERT fact.Visit
        (VisitID, VisitDateKey, LocationKey, ProviderKey, PayerClassKey,
         ServiceLineKey, VisitTypeKey, PayerName, BodyPart, ReferralSource,
         ArrivalTime, ArrivalHour, MinutesToRoom, MinutesToProvider,
         VisitDurationMinutes, XrayPerformed, MRIOrdered, MRILocation,
         InjectionPerformed, ChargeAmount, AllowedAmount)
    SELECT
        TRY_CONVERT(int, v.VisitID),
        d.DateKey,
        l.LocationKey, p.ProviderKey, pc.PayerClassKey, sl.ServiceLineKey, vt.VisitTypeKey,
        NULLIF(LTRIM(RTRIM(v.PayerName)), ''),
        NULLIF(LTRIM(RTRIM(v.BodyPart)), ''),
        NULLIF(LTRIM(RTRIM(v.ReferralSource)), ''),
        TRY_CONVERT(time(0), v.ArrivalTime),
        TRY_CONVERT(tinyint, v.ArrivalHour),
        TRY_CONVERT(int, v.MinutesToRoom),
        TRY_CONVERT(int, v.MinutesToProvider),
        TRY_CONVERT(int, v.VisitDurationMinutes),
        CASE WHEN v.XrayPerformed = 'Yes' THEN 1 WHEN v.XrayPerformed = 'No' THEN 0 END,
        CASE WHEN v.MRIOrdered   = 'Yes' THEN 1 WHEN v.MRIOrdered   = 'No' THEN 0 END,
        NULLIF(LTRIM(RTRIM(v.MRILocation)), ''),
        CASE WHEN v.InjectionPerformed = 'Yes' THEN 1 WHEN v.InjectionPerformed = 'No' THEN 0 END,
        TRY_CONVERT(decimal(10,2), v.ChargeAmount),
        TRY_CONVERT(decimal(10,2), v.AllowedAmount)
    FROM stg.Visits v
    JOIN dim.Date        d  ON d.[Date]          = TRY_CONVERT(date, v.VisitDate)
    JOIN dim.Location    l  ON l.LocationName     = LTRIM(RTRIM(v.Location))
    JOIN dim.Provider    p  ON p.ProviderName     = LTRIM(RTRIM(v.Provider))
    JOIN dim.PayerClass  pc ON pc.PayerClassName  = LTRIM(RTRIM(v.PayerClass))
    JOIN dim.ServiceLine sl ON sl.ServiceLineName = LTRIM(RTRIM(v.ServiceLine))
    JOIN dim.VisitType   vt ON vt.VisitTypeName   = LTRIM(RTRIM(v.VisitType));

    ------------------------------------------------------------------
    -- 3b. fact.ProviderDay
    ------------------------------------------------------------------
    INSERT fact.ProviderDay
        (WorkDateKey, LocationKey, ProviderKey, ScheduledHours, WorkedHours)
    SELECT
        d.DateKey, l.LocationKey, p.ProviderKey,
        TRY_CONVERT(decimal(4,1), pd.ScheduledHours),
        TRY_CONVERT(decimal(4,1), pd.WorkedHours)
    FROM stg.ProviderDays pd
    JOIN dim.Date     d ON d.[Date]      = TRY_CONVERT(date, pd.WorkDate)
    JOIN dim.Location l ON l.LocationName = LTRIM(RTRIM(pd.Location))
    JOIN dim.Provider p ON p.ProviderName = LTRIM(RTRIM(pd.Provider));

    ------------------------------------------------------------------
    -- 3c. fact.Claim  (PaidDateKey -1 when unpaid; VisitKey via VisitID)
    ------------------------------------------------------------------
    INSERT fact.Claim
        (ClaimID, VisitID, VisitKey, ServiceDateKey, SubmitDateKey, PaidDateKey,
         LocationKey, PayerClassKey, ClaimStatusKey, PayerName,
         BilledAmount, AllowedAmount, PaidAmount, ClaimAgeDays, AgeBand)
    SELECT
        TRY_CONVERT(int, c.ClaimID),
        TRY_CONVERT(int, c.VisitID),
        fv.VisitKey,
        sd.DateKey,
        sub.DateKey,
        ISNULL(pdt.DateKey, -1),
        l.LocationKey, pcl.PayerClassKey, cs.ClaimStatusKey,
        NULLIF(LTRIM(RTRIM(c.PayerName)), ''),
        TRY_CONVERT(decimal(10,2), c.BilledAmount),
        TRY_CONVERT(decimal(10,2), c.AllowedAmount),
        TRY_CONVERT(decimal(10,2), c.PaidAmount),
        TRY_CONVERT(int, c.ClaimAgeDays),
        NULLIF(LTRIM(RTRIM(c.AgeBand)), '')
    FROM stg.Claims c
    JOIN      dim.Date       sd  ON sd.[Date]         = TRY_CONVERT(date, c.ServiceDate)
    JOIN      dim.Date       sub ON sub.[Date]        = TRY_CONVERT(date, c.SubmitDate)
    LEFT JOIN dim.Date       pdt ON pdt.[Date]        = TRY_CONVERT(date, NULLIF(LTRIM(RTRIM(c.PaidDate)), ''))
    JOIN      dim.Location   l   ON l.LocationName     = LTRIM(RTRIM(c.Location))
    JOIN      dim.PayerClass pcl ON pcl.PayerClassName = LTRIM(RTRIM(c.PayerClass))
    JOIN      dim.ClaimStatus cs ON cs.ClaimStatusName = LTRIM(RTRIM(c.ClaimStatus))
    LEFT JOIN fact.Visit     fv  ON fv.VisitID         = TRY_CONVERT(int, c.VisitID);

    COMMIT;
END

GO
