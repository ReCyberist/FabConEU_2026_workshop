-- Returns the standings for one competition + season, already ordered the way a league
-- table is read: points, then goal difference, then goals scored, then name.
CREATE PROCEDURE [football].[usp_GetLeagueTable]
    @CompetitionId INT,
    @SeasonId      INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ROW_NUMBER() OVER (ORDER BY lt.[Points] DESC, lt.[GoalDifference] DESC, lt.[GoalsFor] DESC, lt.[Team] ASC) AS [Position],
        lt.[Team],
        lt.[Played],
        lt.[Won],
        lt.[Drawn],
        lt.[Lost],
        lt.[GoalsFor],
        lt.[GoalsAgainst],
        lt.[GoalDifference],
        lt.[Points]
    FROM [football].[vw_LeagueTable] AS lt
    WHERE lt.[CompetitionId] = @CompetitionId
      AND lt.[SeasonId]      = @SeasonId
    ORDER BY [Position];
END;
