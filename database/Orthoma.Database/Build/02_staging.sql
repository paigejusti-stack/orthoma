USE ortho;
GO

/*  Orthoma star-schema build - 02 Staging (landing)
    ------------------------------------------------------------------
    Raw text landing tables. Columns match the CSV headers in order.
    Everything is nvarchar so BULK INSERT never fails on quoted numbers,
    empty dates, or Yes/No flags. Typing and cleaning happen in
    etl.usp_LoadStarSchema.
*/

DROP TABLE IF EXISTS stg.Visits;
CREATE TABLE stg.Visits (
    VisitID              nvarchar(20),
    VisitDate            nvarchar(20),
    ArrivalTime          nvarchar(20),
    ArrivalHour          nvarchar(10),
    DayOfWeek            nvarchar(20),
    Location             nvarchar(60),
    Provider             nvarchar(100),
    ProviderType         nvarchar(10),
    PayerClass           nvarchar(60),
    PayerName            nvarchar(80),
    ServiceLine          nvarchar(60),
    BodyPart             nvarchar(40),
    VisitType            nvarchar(40),
    ReferralSource       nvarchar(60),
    MinutesToRoom        nvarchar(10),
    MinutesToProvider    nvarchar(10),
    VisitDurationMinutes nvarchar(10),
    XrayPerformed        nvarchar(5),
    MRIOrdered           nvarchar(5),
    MRILocation          nvarchar(20),
    InjectionPerformed   nvarchar(5),
    ChargeAmount         nvarchar(20),
    AllowedAmount        nvarchar(20)
);
GO

DROP TABLE IF EXISTS stg.Claims;
CREATE TABLE stg.Claims (
    ClaimID       nvarchar(20),
    VisitID       nvarchar(20),
    ServiceDate   nvarchar(20),
    SubmitDate    nvarchar(20),
    Location      nvarchar(60),
    PayerClass    nvarchar(60),
    PayerName     nvarchar(80),
    BilledAmount  nvarchar(20),
    AllowedAmount nvarchar(20),
    PaidAmount    nvarchar(20),
    ClaimStatus   nvarchar(20),
    PaidDate      nvarchar(20),
    ClaimAgeDays  nvarchar(10),
    AgeBand       nvarchar(20)
);
GO

DROP TABLE IF EXISTS stg.ProviderDays;
CREATE TABLE stg.ProviderDays (
    WorkDate       nvarchar(20),
    Location       nvarchar(60),
    Provider       nvarchar(100),
    ProviderType   nvarchar(10),
    ScheduledHours nvarchar(10),
    WorkedHours    nvarchar(10)
);
GO
