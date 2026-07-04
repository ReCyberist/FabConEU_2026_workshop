-- One row per club per category (Arsenal Men, Arsenal Women). CompetitionId is the
-- league the team currently plays in.
CREATE TABLE [football].[Team]
(
    [TeamId]        INT           IDENTITY (1, 1) NOT NULL,
    [ClubId]        INT           NOT NULL,
    [Category]      NVARCHAR (10) NOT NULL,
    [CompetitionId] INT           NULL,
    CONSTRAINT [PK_Team] PRIMARY KEY CLUSTERED ([TeamId] ASC),
    CONSTRAINT [UQ_Team_Club_Category] UNIQUE ([ClubId], [Category]),
    CONSTRAINT [CK_Team_Category] CHECK ([Category] IN (N'Men', N'Women')),
    CONSTRAINT [FK_Team_Club] FOREIGN KEY ([ClubId]) REFERENCES [football].[Club] ([ClubId]),
    CONSTRAINT [FK_Team_Competition] FOREIGN KEY ([CompetitionId]) REFERENCES [football].[Competition] ([CompetitionId])
);
