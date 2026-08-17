USE ortho;
GO

/*  Orthoma star-schema build - etl.usp_GenerateSyntheticData
    ------------------------------------------------------------------
    Generates a NEW synthetic dataset directly into the star schema
    (no CSV dependency). Larger than the source CSVs but shaped the same,
    so the report's trends still hold.

    Patterns reproduced:
      - Walk-in hours 8am-5pm, peaked mornings + late afternoon.
      - Monday heaviest, Sunday closed, Saturday thin coverage + longer waits.
      - Seasonality: fall-sports spike (Aug-Oct), spring bump, December dip.
      - Door-to-provider rises with per-provider daily load (median low-30s,
        long right tail).
      - Payer mix ~ Commercial 44 / MVA 18 / Cash 12 / Medicare 11 / WC 8 /
        Medicaid 7.
      - MVA claims mostly Open; commercial mostly Paid. MVA paid share
        climbs with claim age. Cash/Self-Pay generates no claim.
      - Ardmore refers MRI out (no in-house MRI).

    Parameters:
      @StartDate   first service date         (default 2023-01-01)
      @EndDate     last service date          (default 2026-12-31)
      @VisitScale  volume multiplier          (default 1.00)

    Row counts vary per run because values are randomized. Defaults
    produce roughly 200k+ visits (about 2x the CSV). Re-running rebuilds
    everything from scratch.
*/
CREATE OR ALTER PROCEDURE etl.usp_GenerateSyntheticData
    @StartDate  date          = '2023-01-01',
    @EndDate    date          = '2026-12-31',
    @VisitScale decimal(5,2)  = 1.00
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Through date = @EndDate;   -- data-through / as-of date

    ------------------------------------------------------------------
    -- 1. Clear facts (child first) and dims; reseed identities
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

    -- Rebuild the date dimension for the requested range.
    EXEC etl.usp_PopulateDimDate @StartDate = @StartDate, @EndDate = @EndDate;

    ------------------------------------------------------------------
    -- 2. Reference dimensions (fixed lists)
    ------------------------------------------------------------------
    -- Locations with a per-open-day base volume and an MRI-refers-out flag.
    DROP TABLE IF EXISTS #loc;
    CREATE TABLE #loc (LocationName varchar(60), BaseVisits int, IsArdmore bit);
    INSERT #loc VALUES
        ('Oklahoma City', 70, 0),
        ('Edmond',        60, 0),
        ('Ardmore',       38, 1);

    INSERT dim.Location (LocationName)
    SELECT LocationName FROM #loc;

    -- Provider roster; prn = on-duty rank within the location (Saturdays
    -- staff prn = 1 only).
    DROP TABLE IF EXISTS #prov;
    CREATE TABLE #prov (LocationName varchar(60), ProviderName varchar(100),
                        ProviderType varchar(10), prn int);
    INSERT #prov VALUES
        ('Oklahoma City','Dr. A. Whitfield','MD',1),
        ('Oklahoma City','Dr. M. Okonkwo','MD',2),
        ('Oklahoma City','Dr. S. Lindqvist','MD',3),
        ('Oklahoma City','K. Barlow, NP','NP',4),
        ('Edmond','Dr. P. Raman','MD',1),
        ('Edmond','Dr. H. Castellano','MD',2),
        ('Edmond','J. Alvarez, PA','PA',3),
        ('Ardmore','Dr. E. Novak','MD',1),
        ('Ardmore','R. Kim, NP','NP',2);

    INSERT dim.Provider (ProviderName, ProviderType)
    SELECT ProviderName, ProviderType FROM #prov;

    INSERT dim.PayerClass (PayerClassName, OverviewPayerGroup) VALUES
        ('Commercial','Commercial'),
        ('Motor Vehicle Accident','Motor Vehicle Accident'),
        ('Cash / Self-Pay','Cash / Self-Pay'),
        ('Medicare','Government'),
        ('Medicaid','Government'),
        ('Workers'' Compensation','Workers'' Compensation');

    INSERT dim.ServiceLine (ServiceLineName) VALUES
        ('General Orthopedic'),('Sports Medicine'),('MVA Injury Care'),
        ('Joint Replacement'),('Spine'),('Hand/Wrist'),('Foot/Ankle');

    INSERT dim.VisitType (VisitTypeName) VALUES
        ('Walk-In New'),('Walk-In Established'),('Scheduled Follow-Up');

    INSERT dim.ClaimStatus (ClaimStatusName, IsUnresolved) VALUES
        ('Paid',0),('Denied',1),('Open',1);

    ------------------------------------------------------------------
    -- 3. Tally (visits per day-location expander)
    ------------------------------------------------------------------
    DROP TABLE IF EXISTS #tally;
    ;WITH e1(n) AS (SELECT 1 FROM (VALUES(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) v(n)),
          e2(n) AS (SELECT 1 FROM e1 a CROSS JOIN e1 b),
          e3(n) AS (SELECT 1 FROM e2 a CROSS JOIN e1 b)
    SELECT TOP (500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    INTO #tally
    FROM e3;

    ------------------------------------------------------------------
    -- 4. Open-day calendar with season / weekday multipliers
    ------------------------------------------------------------------
    DROP TABLE IF EXISTS #cal;
    SELECT
        d.DateKey,
        d.[Date],
        d.DayOfWeekIso AS dow,
        CAST(CASE WHEN d.DayOfWeekIso = 6 THEN 1 ELSE 0 END AS bit) AS isSat,
        CASE d.[Month]
            WHEN 8 THEN 1.25 WHEN 9 THEN 1.30 WHEN 10 THEN 1.20
            WHEN 3 THEN 1.10 WHEN 4 THEN 1.10
            WHEN 12 THEN 0.80 WHEN 11 THEN 0.95 WHEN 1 THEN 0.95 WHEN 2 THEN 0.95
            ELSE 1.00 END AS SeasonMult,
        CASE d.DayOfWeekIso
            WHEN 1 THEN 1.25 WHEN 2 THEN 1.05 WHEN 3 THEN 1.00
            WHEN 4 THEN 1.00 WHEN 5 THEN 1.05 WHEN 6 THEN 0.65 ELSE 0 END AS WeekdayMult
    INTO #cal
    FROM dim.Date d
    WHERE d.DateKey <> -1
      AND d.IsClinicOpen = 1;   -- excludes Sundays; keeps Saturdays

    ------------------------------------------------------------------
    -- 5. fact.ProviderDay  (one row per provider per open day)
    ------------------------------------------------------------------
    INSERT fact.ProviderDay (WorkDateKey, LocationKey, ProviderKey, ScheduledHours, WorkedHours)
    SELECT
        c.DateKey,
        loc.LocationKey,
        p.ProviderKey,
        CASE WHEN c.dow = 6 THEN 6.0 ELSE 9.0 END,
        CAST(CASE WHEN c.dow = 6 THEN 6.0 ELSE 9.0 END
             - (ABS(CHECKSUM(NEWID())) % 6) / 10.0 AS decimal(4,1))
    FROM #cal c
    JOIN #prov pr        ON 1 = 1
    JOIN dim.Location loc ON loc.LocationName = pr.LocationName
    JOIN dim.Provider p   ON p.ProviderName  = pr.ProviderName
    WHERE c.dow <= 5
       OR (c.dow = 6 AND pr.prn = 1);

    -- On-duty roster ranked per day-location, plus a count.
    DROP TABLE IF EXISTS #onduty;
    SELECT
        pdF.WorkDateKey AS DateKey,
        pdF.LocationKey,
        pdF.ProviderKey,
        ROW_NUMBER() OVER (PARTITION BY pdF.WorkDateKey, pdF.LocationKey
                           ORDER BY pdF.ProviderKey) AS rn
    INTO #onduty
    FROM fact.ProviderDay pdF;

    DROP TABLE IF EXISTS #cnt;
    SELECT DateKey, LocationKey, COUNT(*) AS cnt
    INTO #cnt
    FROM #onduty
    GROUP BY DateKey, LocationKey;

    ------------------------------------------------------------------
    -- 6. Day plan: target visit count per day-location
    ------------------------------------------------------------------
    DROP TABLE IF EXISTS #dayplan;
    SELECT
        c.DateKey,
        c.[Date],
        c.isSat,
        loc.LocationKey,
        l.IsArdmore,
        ct.cnt,
        CAST(ROUND(l.BaseVisits * c.SeasonMult * c.WeekdayMult * @VisitScale
                   * (0.90 + (ABS(CHECKSUM(NEWID())) % 200) / 1000.0), 0) AS int) AS targetVisits
    INTO #dayplan
    FROM #cal c
    JOIN #loc l          ON 1 = 1
    JOIN dim.Location loc ON loc.LocationName = l.LocationName
    JOIN #cnt ct          ON ct.DateKey = c.DateKey AND ct.LocationKey = loc.LocationKey;

    ------------------------------------------------------------------
    -- 7. fact.Visit
    ------------------------------------------------------------------
    INSERT fact.Visit
        (VisitID, VisitDateKey, LocationKey, ProviderKey, PayerClassKey,
         ServiceLineKey, VisitTypeKey, PayerName, BodyPart, ReferralSource,
         ArrivalTime, ArrivalHour, MinutesToRoom, MinutesToProvider,
         VisitDurationMinutes, XrayPerformed, MRIOrdered, MRILocation,
         InjectionPerformed, ChargeAmount, AllowedAmount)
    SELECT
        100000 + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
        dp.DateKey,
        dp.LocationKey,
        od.ProviderKey,
        pc.PayerClassKey,
        sl.ServiceLineKey,
        vtd.VisitTypeKey,
        CASE p.PayerClassName
            WHEN 'Commercial' THEN CASE WHEN r.rPn < 0.30 THEN 'BlueCross'
                                        WHEN r.rPn < 0.55 THEN 'UnitedHealthcare'
                                        WHEN r.rPn < 0.80 THEN 'Aetna' ELSE 'Cigna' END
            WHEN 'Motor Vehicle Accident' THEN CASE WHEN r.rPn < 0.50 THEN 'MVA - Third Party Liability'
                                                    WHEN r.rPn < 0.80 THEN 'MVA - Attorney Lien'
                                                    ELSE 'MVA - Med Pay' END
            WHEN 'Medicare' THEN 'Medicare'
            WHEN 'Medicaid' THEN 'SoonerCare'
            WHEN 'Workers'' Compensation' THEN 'WC Carrier'
            ELSE 'Self-Pay' END,
        CASE CAST(r.rBody * 10 AS int)
            WHEN 0 THEN 'Knee' WHEN 1 THEN 'Shoulder' WHEN 2 THEN 'Back'
            WHEN 3 THEN 'Ankle' WHEN 4 THEN 'Wrist' WHEN 5 THEN 'Hip'
            WHEN 6 THEN 'Elbow' WHEN 7 THEN 'Neck' WHEN 8 THEN 'Hand' ELSE 'Foot' END,
        CASE WHEN p.PayerClassName = 'Motor Vehicle Accident' AND r.rRef < 0.60 THEN 'Attorney Referral'
             WHEN r.rRef2 < 0.25 THEN 'Google Search'
             WHEN r.rRef2 < 0.45 THEN 'Physician Referral'
             WHEN r.rRef2 < 0.60 THEN 'Insurance Directory'
             WHEN r.rRef2 < 0.75 THEN 'Returning Patient'
             WHEN r.rRef2 < 0.88 THEN 'Employer / WC'
             ELSE 'Friend / Family' END,
        TIMEFROMPARTS(h.ArrivalHour, ABS(CHECKSUM(NEWID())) % 60, 0, 0, 0),
        h.ArrivalHour,
        CAST(ROUND(mp.MinutesToProvider * 0.4 + (ABS(CHECKSUM(NEWID())) % 8), 0) AS int),
        mp.MinutesToProvider,
        20 + CAST(r.rV * 45 AS int),
        CASE WHEN r.rX   < 0.55 THEN 1 ELSE 0 END,
        CASE WHEN r.rMRI < 0.12 THEN 1 ELSE 0 END,
        CASE WHEN r.rMRI >= 0.12 THEN NULL
             WHEN dp.IsArdmore = 1 THEN 'Referred Out'
             WHEN r.rMRIloc < 0.85 THEN 'In-House' ELSE 'Referred Out' END,
        CASE WHEN r.rInj < 0.15 THEN 1 ELSE 0 END,
        ch.ChargeAmount,
        CAST(ROUND(ch.ChargeAmount * af.f * (0.90 + 0.20 * r.rAmt2), 2) AS decimal(10,2))
    FROM #dayplan dp
    JOIN #tally  t  ON t.n <= dp.targetVisits
    JOIN #onduty od ON od.DateKey = dp.DateKey
                   AND od.LocationKey = dp.LocationKey
                   AND od.rn = ((t.n - 1) % dp.cnt) + 1
    CROSS APPLY (SELECT
            rP    = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rS    = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rH    = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rVT   = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rBody = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rRef  = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rRef2 = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rMRI  = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rMRIloc = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rX    = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rInj  = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rAmt  = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rAmt2 = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rTail = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rV    = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0,
            rPn   = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0) r
    CROSS APPLY (SELECT PayerClassName =
            CASE WHEN r.rP < 0.44 THEN 'Commercial'
                 WHEN r.rP < 0.62 THEN 'Motor Vehicle Accident'
                 WHEN r.rP < 0.74 THEN 'Cash / Self-Pay'
                 WHEN r.rP < 0.85 THEN 'Medicare'
                 WHEN r.rP < 0.93 THEN 'Workers'' Compensation'
                 ELSE 'Medicaid' END) p
    CROSS APPLY (SELECT ArrivalHour =
            CASE WHEN r.rH < 0.12 THEN 8  WHEN r.rH < 0.28 THEN 9
                 WHEN r.rH < 0.42 THEN 10 WHEN r.rH < 0.52 THEN 11
                 WHEN r.rH < 0.60 THEN 12 WHEN r.rH < 0.68 THEN 13
                 WHEN r.rH < 0.76 THEN 14 WHEN r.rH < 0.85 THEN 15
                 WHEN r.rH < 0.95 THEN 16 ELSE 17 END) h
    CROSS APPLY (SELECT ServiceLineName =
            CASE WHEN p.PayerClassName = 'Motor Vehicle Accident' AND r.rS < 0.80 THEN 'MVA Injury Care'
                 WHEN r.rS < 0.40 THEN 'General Orthopedic'
                 WHEN r.rS < 0.65 THEN 'Sports Medicine'
                 WHEN r.rS < 0.77 THEN 'Joint Replacement'
                 WHEN r.rS < 0.87 THEN 'Spine'
                 WHEN r.rS < 0.94 THEN 'Hand/Wrist'
                 ELSE 'Foot/Ankle' END) s
    CROSS APPLY (SELECT VisitTypeName =
            CASE WHEN r.rVT < 0.35 THEN 'Walk-In New'
                 WHEN r.rVT < 0.75 THEN 'Walk-In Established'
                 ELSE 'Scheduled Follow-Up' END) vt
    CROSS APPLY (SELECT BaseCharge =
            CASE s.ServiceLineName
                WHEN 'General Orthopedic' THEN 320 WHEN 'Sports Medicine' THEN 360
                WHEN 'MVA Injury Care' THEN 420   WHEN 'Joint Replacement' THEN 580
                WHEN 'Spine' THEN 520             WHEN 'Hand/Wrist' THEN 300
                ELSE 320 END) cb
    CROSS APPLY (SELECT ChargeAmount =
            CAST(ROUND(cb.BaseCharge * (0.80 + 0.50 * r.rAmt), 0) AS decimal(10,2))) ch
    CROSS APPLY (SELECT f =
            CASE p.PayerClassName
                WHEN 'Commercial' THEN 0.58 WHEN 'Motor Vehicle Accident' THEN 0.70
                WHEN 'Cash / Self-Pay' THEN 0.52 WHEN 'Medicare' THEN 0.44
                WHEN 'Workers'' Compensation' THEN 0.64 ELSE 0.40 END) af
    CROSS APPLY (SELECT MinutesToProvider =
            CAST(
                CASE WHEN 12 + 0.9 * (dp.targetVisits * 1.0 / dp.cnt)
                            + CASE h.ArrivalHour WHEN 9 THEN 6 WHEN 10 THEN 6 WHEN 16 THEN 5
                                                 WHEN 8 THEN 3 WHEN 17 THEN 3 ELSE 1 END
                            + CASE WHEN dp.isSat = 1 THEN 7 ELSE 0 END
                            + (-LOG(r.rTail + 0.00001) * 6.0) < 5 THEN 5
                     ELSE ROUND(12 + 0.9 * (dp.targetVisits * 1.0 / dp.cnt)
                            + CASE h.ArrivalHour WHEN 9 THEN 6 WHEN 10 THEN 6 WHEN 16 THEN 5
                                                 WHEN 8 THEN 3 WHEN 17 THEN 3 ELSE 1 END
                            + CASE WHEN dp.isSat = 1 THEN 7 ELSE 0 END
                            + (-LOG(r.rTail + 0.00001) * 6.0), 0) END
            AS int)) mp
    JOIN dim.PayerClass  pc  ON pc.PayerClassName  = p.PayerClassName
    JOIN dim.ServiceLine sl  ON sl.ServiceLineName = s.ServiceLineName
    JOIN dim.VisitType   vtd ON vtd.VisitTypeName  = vt.VisitTypeName;

    ------------------------------------------------------------------
    -- 8. fact.Claim  (every non-cash visit generates one claim)
    ------------------------------------------------------------------
    ;WITH vc AS (
        SELECT
            fv.VisitKey, fv.VisitID, fv.VisitDateKey, fv.LocationKey,
            fv.PayerClassKey, fv.PayerName, fv.ChargeAmount, fv.AllowedAmount,
            pc.PayerClassName, vd.[Date] AS VisitDate
        FROM fact.Visit fv
        JOIN dim.PayerClass pc ON pc.PayerClassKey = fv.PayerClassKey
        JOIN dim.Date       vd ON vd.DateKey       = fv.VisitDateKey
        WHERE pc.PayerClassName <> 'Cash / Self-Pay'
    )
    INSERT fact.Claim
        (ClaimID, VisitID, VisitKey, ServiceDateKey, SubmitDateKey, PaidDateKey,
         LocationKey, PayerClassKey, ClaimStatusKey, PayerName,
         BilledAmount, AllowedAmount, PaidAmount, ClaimAgeDays, AgeBand)
    SELECT
        500000 + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
        vc.VisitID,
        vc.VisitKey,
        vc.VisitDateKey,
        sd.DateKey,
        ISNULL(pdk.DateKey, -1),
        vc.LocationKey,
        vc.PayerClassKey,
        cs.ClaimStatusKey,
        vc.PayerName,
        vc.ChargeAmount,
        vc.AllowedAmount,
        st.PaidAmount,
        age.ClaimAgeDays,
        CASE WHEN age.ClaimAgeDays <= 30 THEN '0-30'
             WHEN age.ClaimAgeDays <= 90 THEN '31-90'
             WHEN age.ClaimAgeDays <= 180 THEN '91-180'
             WHEN age.ClaimAgeDays <= 365 THEN '181-365'
             ELSE '366-730' END
    FROM vc
    CROSS APPLY (SELECT SubmitDate =
            CASE WHEN DATEADD(day, 1 + ABS(CHECKSUM(NEWID())) % 9, vc.VisitDate) > @Through
                 THEN @Through
                 ELSE DATEADD(day, 1 + ABS(CHECKSUM(NEWID())) % 9, vc.VisitDate) END) sub
    CROSS APPLY (SELECT ClaimAgeDays = DATEDIFF(day, sub.SubmitDate, @Through)) age
    CROSS APPLY (SELECT r1 = (ABS(CHECKSUM(NEWID())) % 100000) / 100000.0) r
    CROSS APPLY (SELECT
            paidProb = CASE WHEN vc.PayerClassName = 'Motor Vehicle Accident'
                            THEN CASE WHEN age.ClaimAgeDays < 180 THEN 0.03
                                      WHEN age.ClaimAgeDays < 365 THEN 0.10
                                      WHEN age.ClaimAgeDays < 540 THEN 0.25
                                      ELSE 0.40 END
                            ELSE 0.90 END,
            deniedProb = CASE WHEN vc.PayerClassName = 'Motor Vehicle Accident' THEN 0.05 ELSE 0.03 END) pp
    CROSS APPLY (SELECT StatusName =
            CASE WHEN age.ClaimAgeDays < 1 THEN 'Open'
                 WHEN r.r1 < pp.paidProb THEN 'Paid'
                 WHEN r.r1 < pp.paidProb + pp.deniedProb THEN 'Denied'
                 ELSE 'Open' END) stt
    CROSS APPLY (SELECT
            PaidAmount = CASE WHEN stt.StatusName = 'Paid' THEN vc.AllowedAmount ELSE 0 END,
            PaidDate   = CASE WHEN stt.StatusName = 'Paid'
                              THEN DATEADD(day,
                                       CASE WHEN age.ClaimAgeDays <= 20 THEN age.ClaimAgeDays
                                            ELSE 20 + ABS(CHECKSUM(NEWID())) % (age.ClaimAgeDays - 19) END,
                                       sub.SubmitDate)
                              ELSE NULL END) st
    JOIN      dim.Date        sd  ON sd.[Date]         = sub.SubmitDate
    LEFT JOIN dim.Date        pdk ON pdk.[Date]        = st.PaidDate
    JOIN      dim.ClaimStatus  cs ON cs.ClaimStatusName = stt.StatusName;

    ------------------------------------------------------------------
    -- 9. Update statistics for good query plans on the fresh data
    ------------------------------------------------------------------
    UPDATE STATISTICS fact.Visit;
    UPDATE STATISTICS fact.Claim;
    UPDATE STATISTICS fact.ProviderDay;
END
GO
