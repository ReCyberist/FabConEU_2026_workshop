-- Every fixture still to be played, with friendly club/competition names. Kept
-- date-agnostic (Status = 'Scheduled') so it always returns rows in a demo regardless
-- of the clock.
CREATE VIEW [football].[vw_UpcomingFixtures]
AS
SELECT
    f.[FixtureId],
    f.[KickoffUtc],
    comp.[Name]     AS [Competition],
    comp.[Category] AS [Category],
    homeClub.[Name] AS [HomeTeam],
    awayClub.[Name] AS [AwayTeam],
    s.[Name]        AS [Stadium]
FROM [football].[Fixture]     AS f
INNER JOIN [football].[Competition] AS comp     ON comp.[CompetitionId] = f.[CompetitionId]
INNER JOIN [football].[Team]        AS homeTeam ON homeTeam.[TeamId] = f.[HomeTeamId]
INNER JOIN [football].[Club]        AS homeClub ON homeClub.[ClubId] = homeTeam.[ClubId]
INNER JOIN [football].[Team]        AS awayTeam ON awayTeam.[TeamId] = f.[AwayTeamId]
INNER JOIN [football].[Club]        AS awayClub ON awayClub.[ClubId] = awayTeam.[ClubId]
LEFT  JOIN [football].[Stadium]     AS s        ON s.[StadiumId] = f.[StadiumId]
WHERE f.[Status] = N'Scheduled';
