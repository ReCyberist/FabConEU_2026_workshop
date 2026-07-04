-- A single match. Scores are NULL until the game is played; usp_RecordFixtureResult
-- fills them in and flips Status to 'Played'.
CREATE TABLE [football].[Fixture]
(
    [FixtureId]     INT           IDENTITY (1, 1) NOT NULL,
    [SeasonId]      INT           NOT NULL,
    [CompetitionId] INT           NOT NULL,
    [HomeTeamId]    INT           NOT NULL,
    [AwayTeamId]    INT           NOT NULL,
    [StadiumId]     INT           NULL,
    [RefereeId]     INT           NULL,
    [KickoffUtc]    DATETIME2 (0) NOT NULL,
    [HomeScore]     TINYINT       NULL,
    [AwayScore]     TINYINT       NULL,
    [Status]        NVARCHAR (12) NOT NULL CONSTRAINT [DF_Fixture_Status] DEFAULT (N'Scheduled'),
    CONSTRAINT [PK_Fixture] PRIMARY KEY CLUSTERED ([FixtureId] ASC),
    CONSTRAINT [CK_Fixture_Status] CHECK ([Status] IN (N'Scheduled', N'Played', N'Postponed', N'Cancelled')),
    CONSTRAINT [CK_Fixture_DifferentTeams] CHECK ([HomeTeamId] <> [AwayTeamId]),
    CONSTRAINT [FK_Fixture_Season] FOREIGN KEY ([SeasonId]) REFERENCES [football].[Season] ([SeasonId]),
    CONSTRAINT [FK_Fixture_Competition] FOREIGN KEY ([CompetitionId]) REFERENCES [football].[Competition] ([CompetitionId]),
    CONSTRAINT [FK_Fixture_HomeTeam] FOREIGN KEY ([HomeTeamId]) REFERENCES [football].[Team] ([TeamId]),
    CONSTRAINT [FK_Fixture_AwayTeam] FOREIGN KEY ([AwayTeamId]) REFERENCES [football].[Team] ([TeamId]),
    CONSTRAINT [FK_Fixture_Stadium] FOREIGN KEY ([StadiumId]) REFERENCES [football].[Stadium] ([StadiumId]),
    CONSTRAINT [FK_Fixture_Referee] FOREIGN KEY ([RefereeId]) REFERENCES [football].[Referee] ([RefereeId])
);
GO
CREATE NONCLUSTERED INDEX [IX_Fixture_Season_Competition] ON [football].[Fixture] ([SeasonId], [CompetitionId]) INCLUDE ([HomeTeamId], [AwayTeamId], [HomeScore], [AwayScore], [Status]);
