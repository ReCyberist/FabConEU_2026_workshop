-- Record the final score for a fixture and mark it played. Validates that the fixture
-- exists and hasn't already been played, so re-running a demo doesn't silently
-- double-count anything.
CREATE PROCEDURE [football].[usp_RecordFixtureResult]
    @FixtureId INT,
    @HomeScore TINYINT,
    @AwayScore TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM [football].[Fixture] WHERE [FixtureId] = @FixtureId)
    BEGIN
        THROW 50001, 'Fixture does not exist.', 1;
    END;

    IF EXISTS (SELECT 1 FROM [football].[Fixture] WHERE [FixtureId] = @FixtureId AND [Status] = N'Played')
    BEGIN
        THROW 50002, 'Fixture has already been played.', 1;
    END;

    UPDATE [football].[Fixture]
    SET [HomeScore] = @HomeScore,
        [AwayScore] = @AwayScore,
        [Status]    = N'Played'
    WHERE [FixtureId] = @FixtureId;
END;
