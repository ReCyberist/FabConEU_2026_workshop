-- Standings computed from played fixtures. Each played fixture contributes two rows
-- (home view + away view); we then aggregate per season / competition / team.
-- 3 points for a win, 1 for a draw. "Shake it off" if a team hasn't played yet -- it
-- simply won't appear until it has a result.
CREATE VIEW [football].[vw_LeagueTable]
AS
WITH [PerTeam] AS
(
    SELECT
        f.[SeasonId],
        f.[CompetitionId],
        f.[HomeTeamId] AS [TeamId],
        f.[HomeScore]  AS [GoalsFor],
        f.[AwayScore]  AS [GoalsAgainst]
    FROM [football].[Fixture] AS f
    WHERE f.[Status] = N'Played'

    UNION ALL

    SELECT
        f.[SeasonId],
        f.[CompetitionId],
        f.[AwayTeamId] AS [TeamId],
        f.[AwayScore]  AS [GoalsFor],
        f.[HomeScore]  AS [GoalsAgainst]
    FROM [football].[Fixture] AS f
    WHERE f.[Status] = N'Played'
)
SELECT
    pt.[SeasonId],
    pt.[CompetitionId],
    comp.[Name]     AS [Competition],
    comp.[Category] AS [Category],
    pt.[TeamId],
    club.[Name]     AS [Team],
    COUNT(*)                                                              AS [Played],
    SUM(CASE WHEN pt.[GoalsFor] >  pt.[GoalsAgainst] THEN 1 ELSE 0 END)   AS [Won],
    SUM(CASE WHEN pt.[GoalsFor] =  pt.[GoalsAgainst] THEN 1 ELSE 0 END)   AS [Drawn],
    SUM(CASE WHEN pt.[GoalsFor] <  pt.[GoalsAgainst] THEN 1 ELSE 0 END)   AS [Lost],
    SUM(pt.[GoalsFor])                                                    AS [GoalsFor],
    SUM(pt.[GoalsAgainst])                                                AS [GoalsAgainst],
    SUM(pt.[GoalsFor]) - SUM(pt.[GoalsAgainst])                           AS [GoalDifference],
    SUM(CASE WHEN pt.[GoalsFor] >  pt.[GoalsAgainst] THEN 3
             WHEN pt.[GoalsFor] =  pt.[GoalsAgainst] THEN 1
             ELSE 0 END)                                                  AS [Points]
FROM [PerTeam] AS pt
INNER JOIN [football].[Team]        AS t    ON t.[TeamId] = pt.[TeamId]
INNER JOIN [football].[Club]        AS club ON club.[ClubId] = t.[ClubId]
INNER JOIN [football].[Competition] AS comp ON comp.[CompetitionId] = pt.[CompetitionId]
GROUP BY
    pt.[SeasonId],
    pt.[CompetitionId],
    comp.[Name],
    comp.[Category],
    pt.[TeamId],
    club.[Name];
