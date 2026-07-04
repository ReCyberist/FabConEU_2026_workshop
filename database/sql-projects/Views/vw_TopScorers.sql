-- Goals per player, by season and competition. Own goals don't count towards the
-- scorer's tally, so they're excluded here.
CREATE VIEW [football].[vw_TopScorers]
AS
SELECT
    f.[SeasonId],
    f.[CompetitionId],
    comp.[Name]     AS [Competition],
    comp.[Category] AS [Category],
    p.[PlayerId],
    p.[FirstName] + N' ' + p.[LastName] AS [Player],
    club.[Name]     AS [Team],
    COUNT(*)                                              AS [Goals],
    SUM(CASE WHEN g.[IsPenalty] = 1 THEN 1 ELSE 0 END)    AS [Penalties]
FROM [football].[Goal]        AS g
INNER JOIN [football].[Fixture]     AS f    ON f.[FixtureId] = g.[FixtureId]
INNER JOIN [football].[Player]      AS p    ON p.[PlayerId] = g.[PlayerId]
INNER JOIN [football].[Team]        AS t    ON t.[TeamId] = g.[TeamId]
INNER JOIN [football].[Club]        AS club ON club.[ClubId] = t.[ClubId]
INNER JOIN [football].[Competition] AS comp ON comp.[CompetitionId] = f.[CompetitionId]
WHERE g.[IsOwnGoal] = 0
GROUP BY
    f.[SeasonId],
    f.[CompetitionId],
    comp.[Name],
    comp.[Category],
    p.[PlayerId],
    p.[FirstName] + N' ' + p.[LastName],
    club.[Name];
