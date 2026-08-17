USE ortho;
GO

/*  Orthoma star-schema build - 03 Dimensions
    ------------------------------------------------------------------
    Conformed dimensions with integer surrogate keys. This replaces the
    name-based Provider / Location dimensions the semantic-model doc
    flags as a risk. dim.Date carries an Unknown (-1) member so unpaid
    claims (no PaidDate) still satisfy their foreign key.
*/

-- dim.Date -----------------------------------------------------------
-- Smart key (yyyymmdd). Populated by etl.usp_PopulateDimDate.
DROP TABLE IF EXISTS dim.Date;
CREATE TABLE dim.Date (
    DateKey       int          NOT NULL CONSTRAINT PK_dim_Date PRIMARY KEY,
    [Date]        date         NOT NULL,
    [Year]        smallint     NOT NULL,
    [Quarter]     tinyint      NOT NULL,
    QuarterName   varchar(6)   NOT NULL,   -- 'Q3'
    [Month]       tinyint      NOT NULL,
    MonthName     varchar(10)  NOT NULL,   -- 'August'
    MonthShort    varchar(3)   NOT NULL,   -- 'Aug'
    MonthStart    date         NOT NULL,
    MonthYear     varchar(8)   NOT NULL,   -- 'Aug 2024'
    MonthYearSort int          NOT NULL,   -- 202408 (sort-by for MonthYear)
    [Day]         tinyint      NOT NULL,
    DayOfWeekIso  tinyint      NOT NULL,   -- 1 = Monday .. 7 = Sunday
    DayName       varchar(10)  NOT NULL,
    DayShort      varchar(3)   NOT NULL,
    WeekStart     date         NOT NULL,   -- Monday of the week
    IsWeekend     bit          NOT NULL,
    IsClinicOpen  bit          NOT NULL    -- closed Sundays (extend for holidays)
);
GO

-- dim.Location -------------------------------------------------------
DROP TABLE IF EXISTS dim.Location;
CREATE TABLE dim.Location (
    LocationKey  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_Location PRIMARY KEY,
    LocationName varchar(60)       NOT NULL CONSTRAINT UQ_dim_Location UNIQUE
);
GO

-- dim.Provider -------------------------------------------------------
DROP TABLE IF EXISTS dim.Provider;
CREATE TABLE dim.Provider (
    ProviderKey  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_Provider PRIMARY KEY,
    ProviderName varchar(100)      NOT NULL CONSTRAINT UQ_dim_Provider UNIQUE,
    ProviderType varchar(10)       NULL     -- MD / PA / NP
);
GO

-- dim.PayerClass -----------------------------------------------------
-- OverviewPayerGroup rolls Medicare + Medicaid into 'Government' for the
-- Clinic Overview page; all other classes map to themselves.
DROP TABLE IF EXISTS dim.PayerClass;
CREATE TABLE dim.PayerClass (
    PayerClassKey      int IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_PayerClass PRIMARY KEY,
    PayerClassName     varchar(60)       NOT NULL CONSTRAINT UQ_dim_PayerClass UNIQUE,
    OverviewPayerGroup varchar(40)       NOT NULL
);
GO

-- dim.ServiceLine ----------------------------------------------------
DROP TABLE IF EXISTS dim.ServiceLine;
CREATE TABLE dim.ServiceLine (
    ServiceLineKey  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_ServiceLine PRIMARY KEY,
    ServiceLineName varchar(60)       NOT NULL CONSTRAINT UQ_dim_ServiceLine UNIQUE
);
GO

-- dim.VisitType ------------------------------------------------------
DROP TABLE IF EXISTS dim.VisitType;
CREATE TABLE dim.VisitType (
    VisitTypeKey  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_VisitType PRIMARY KEY,
    VisitTypeName varchar(40)       NOT NULL CONSTRAINT UQ_dim_VisitType UNIQUE
);
GO

-- dim.ClaimStatus ----------------------------------------------------
-- IsUnresolved = 1 for Open or Denied (the MVA follow-up cohort rule).
DROP TABLE IF EXISTS dim.ClaimStatus;
CREATE TABLE dim.ClaimStatus (
    ClaimStatusKey  int IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_ClaimStatus PRIMARY KEY,
    ClaimStatusName varchar(20)       NOT NULL CONSTRAINT UQ_dim_ClaimStatus UNIQUE,
    IsUnresolved    bit               NOT NULL
);
GO
