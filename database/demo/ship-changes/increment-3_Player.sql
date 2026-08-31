CREATE TABLE [football].[Player]
(
    [PlayerId]     INT           IDENTITY (1, 1) NOT NULL,
    [TeamId]       INT           NULL,
    [FirstName]    NVARCHAR (60) NOT NULL,
    [LastName]     NVARCHAR (60) NOT NULL,
    [Position]     CHAR (2)      NULL,   -- GK / DF / MF / FW
    [SquadNumber]  TINYINT       NULL,
    [DateOfBirth]  DATE          NULL,
    CONSTRAINT [PK_Player] PRIMARY KEY CLUSTERED ([PlayerId] ASC),
    CONSTRAINT [CK_Player_Position] CHECK ([Position] IS NULL OR [Position] IN ('GK', 'DF', 'MF', 'FW')),
    CONSTRAINT [FK_Player_Team] FOREIGN KEY ([TeamId]) REFERENCES [football].[Team] ([TeamId])
);
GO
CREATE NONCLUSTERED INDEX [IX_Player_TeamId] ON [football].[Player] ([TeamId]);
