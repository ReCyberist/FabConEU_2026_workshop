-- Move a player to a different team (a transfer). Validates both the player and the
-- destination team exist. @ToTeamId NULL is allowed and represents a released / free
-- agent player.
CREATE PROCEDURE [football].[usp_TransferPlayer]
    @PlayerId INT,
    @ToTeamId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM [football].[Player] WHERE [PlayerId] = @PlayerId)
    BEGIN
        THROW 50003, 'Player does not exist.', 1;
    END;

    IF @ToTeamId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [football].[Team] WHERE [TeamId] = @ToTeamId)
    BEGIN
        THROW 50004, 'Destination team does not exist.', 1;
    END;

    UPDATE [football].[Player]
    SET [TeamId] = @ToTeamId
    WHERE [PlayerId] = @PlayerId;
END;
