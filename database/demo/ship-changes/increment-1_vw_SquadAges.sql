-- Increment 1 (additive, safe): a new read-only view. Copy this into the SQL project at
-- database/sql-projects/Views/vw_SquadAges.sql, then build + deploy.
--
-- Purely additive — it creates a new object and touches nothing existing, so the deploy
-- report shows "1 view to create, 0 data-loss operations" and it's safe to auto-deploy.
CREATE VIEW [football].[vw_SquadAges]
AS
SELECT
    p.[PlayerId],
    p.[TeamId],
    p.[FirstName],
    p.[LastName],
    p.[DateOfBirth],
    -- Whole years old today (adjusts for whether this year's birthday has happened yet).
    DATEDIFF(YEAR, p.[DateOfBirth], SYSUTCDATETIME())
        - CASE
              WHEN MONTH(p.[DateOfBirth]) > MONTH(SYSUTCDATETIME())
                   OR (MONTH(p.[DateOfBirth]) = MONTH(SYSUTCDATETIME())
                       AND DAY(p.[DateOfBirth]) > DAY(SYSUTCDATETIME()))
              THEN 1 ELSE 0
          END AS [AgeYears]
FROM [football].[Player] AS p
WHERE p.[DateOfBirth] IS NOT NULL;
