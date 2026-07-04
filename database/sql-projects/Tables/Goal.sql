-- One row per goal. TeamId is the team credited with the goal (for an own goal that is
-- the team that benefits, not the scorer's own team).
CREATE TABLE [football].[Goal]
(
    [GoalId]    INT     IDENTITY (1, 1) NOT NULL,
    [FixtureId] INT     NOT NULL,
    [PlayerId]  INT     NOT NULL,
    [TeamId]    INT     NOT NULL,
    [Minute]    TINYINT NOT NULL,
    [IsPenalty] BIT     NOT NULL CONSTRAINT [DF_Goal_IsPenalty] DEFAULT (0),
    [IsOwnGoal] BIT     NOT NULL CONSTRAINT [DF_Goal_IsOwnGoal] DEFAULT (0),
    CONSTRAINT [PK_Goal] PRIMARY KEY CLUSTERED ([GoalId] ASC),
    CONSTRAINT [CK_Goal_Minute] CHECK ([Minute] BETWEEN 1 AND 130),
    CONSTRAINT [FK_Goal_Fixture] FOREIGN KEY ([FixtureId]) REFERENCES [football].[Fixture] ([FixtureId]),
    CONSTRAINT [FK_Goal_Player] FOREIGN KEY ([PlayerId]) REFERENCES [football].[Player] ([PlayerId]),
    CONSTRAINT [FK_Goal_Team] FOREIGN KEY ([TeamId]) REFERENCES [football].[Team] ([TeamId])
);
GO
CREATE NONCLUSTERED INDEX [IX_Goal_FixtureId] ON [football].[Goal] ([FixtureId]);
GO
CREATE NONCLUSTERED INDEX [IX_Goal_PlayerId] ON [football].[Goal] ([PlayerId]);
