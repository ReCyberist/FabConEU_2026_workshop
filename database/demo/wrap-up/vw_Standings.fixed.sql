-- Slim public standings: season, competition, team, games played and points,
-- straight off the league table. Explicit column list (no SELECT *), plain name.
CREATE VIEW [football].[vw_Standings]
AS
SELECT
    lt.[SeasonId],
    lt.[CompetitionId],
    lt.[Competition],
    lt.[Team],
    lt.[Played],
    lt.[Points]
FROM [football].[vw_LeagueTable] AS lt;
