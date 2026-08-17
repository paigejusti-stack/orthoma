/****** Object:  StoredProcedure [etl].[usp_PopulateDimDate]    Script Date: 8/16/2026 12:23:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*  Orthoma star-schema build - etl.usp_PopulateDimDate
    ------------------------------------------------------------------
    Rebuilds dim.Date for a date range (default covers the synthetic
    visit/claim window with margin). Seeds an Unknown (-1) member first.
    ISO weekday math is DATEFIRST-independent, so results are stable
    regardless of server/session settings.

    Must run while fact tables are empty (dim.Date is FK-referenced).
    The Post-Deployment script clears facts before calling this.
*/
CREATE   PROCEDURE [etl].[usp_PopulateDimDate]
    @StartDate date = '2024-01-01',
    @EndDate   date = '2026-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dim.Date;

    -- Unknown member for unmatched / unpaid date keys.
    INSERT dim.Date
        (DateKey,[Date],[Year],[Quarter],QuarterName,[Month],MonthName,MonthShort,
         MonthStart,MonthYear,MonthYearSort,[Day],DayOfWeekIso,DayName,DayShort,
         WeekStart,IsWeekend,IsClinicOpen)
    VALUES
        (-1,'1900-01-01',1900,1,'Q1',1,'Unknown','Unk','1900-01-01','Unknown',
         190001,1,1,'Unknown','Unk','1900-01-01',0,0);

    ;WITH d AS (
        SELECT @StartDate AS dt
        UNION ALL
        SELECT DATEADD(day, 1, dt) FROM d WHERE dt < @EndDate
    )
    INSERT dim.Date
        (DateKey,[Date],[Year],[Quarter],QuarterName,[Month],MonthName,MonthShort,
         MonthStart,MonthYear,MonthYearSort,[Day],DayOfWeekIso,DayName,DayShort,
         WeekStart,IsWeekend,IsClinicOpen)
    SELECT
        CONVERT(int, CONVERT(char(8), dt, 112))                              AS DateKey,
        dt                                                                   AS [Date],
        DATEPART(year, dt)                                                   AS [Year],
        DATEPART(quarter, dt)                                                AS [Quarter],
        'Q' + CONVERT(varchar(1), DATEPART(quarter, dt))                     AS QuarterName,
        DATEPART(month, dt)                                                  AS [Month],
        DATENAME(month, dt)                                                  AS MonthName,
        LEFT(DATENAME(month, dt), 3)                                         AS MonthShort,
        DATEFROMPARTS(YEAR(dt), MONTH(dt), 1)                                AS MonthStart,
        LEFT(DATENAME(month, dt), 3) + ' ' + CONVERT(varchar(4), YEAR(dt))   AS MonthYear,
        YEAR(dt) * 100 + MONTH(dt)                                           AS MonthYearSort,
        DATEPART(day, dt)                                                    AS [Day],
        -- ISO weekday (Mon=1..Sun=7), DATEFIRST-independent: day 0
        -- (1900-01-01) was a Monday, so DATEDIFF(day,0,dt) % 7 = 0 on Mondays.
        (DATEDIFF(day, 0, dt) % 7) + 1                                       AS DayOfWeekIso,
        DATENAME(weekday, dt)                                                AS DayName,
        LEFT(DATENAME(weekday, dt), 3)                                       AS DayShort,
        DATEADD(day, -(DATEDIFF(day, 0, dt) % 7), dt)                        AS WeekStart,
        CASE WHEN ((DATEDIFF(day, 0, dt) % 7) + 1) IN (6,7)
             THEN 1 ELSE 0 END                                              AS IsWeekend,
        CASE WHEN ((DATEDIFF(day, 0, dt) % 7) + 1) = 7
             THEN 0 ELSE 1 END                                              AS IsClinicOpen
    FROM d
    OPTION (MAXRECURSION 0);
END

GO
