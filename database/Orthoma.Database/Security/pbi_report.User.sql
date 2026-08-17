/****** Object:  Database User [pbi_report] ******/
/*
    Read-only user for the Orthoma Power BI report.
    Run this inside the [ortho] database.

    A new user has no permissions until granted, so the single GRANT below
    is the whole permission set. The rpt.* views read fact.* and dim.*
    through ownership chaining, so no rights on the base tables are needed.

    Replace the password before running. Do not commit the real one.
*/

-- 1. create the user
CREATE USER [pbi_report] WITH PASSWORD = N'<replace-me>';
GO

-- 2. grant read-only access to the reporting layer
GRANT SELECT ON SCHEMA::[rpt] TO [pbi_report];
GO


/*  Check it worked:

    -- should return rows
    EXECUTE AS USER = 'pbi_report';
    SELECT TOP 1 * FROM rpt.FactVisit;
    REVERT;

    -- should fail with a permission error
    EXECUTE AS USER = 'pbi_report';
    SELECT TOP 1 * FROM fact.Visit;
    REVERT;
*/
