-- A Club is the institution (Arsenal, Barcelona). A club fields more than one Team
-- (men's, women's) -- see football.Team. This is how the sample covers both the
-- men's and women's game from one shared set of clubs.
CREATE TABLE [football].[Club]
(
    [ClubId]        INT            IDENTITY (1, 1) NOT NULL,
    [Name]          NVARCHAR (100) NOT NULL,
    [ShortName]     NVARCHAR (20)  NULL,
    [Founded]       SMALLINT       NULL,
    [HomeStadiumId] INT            NULL,
    CONSTRAINT [PK_Club] PRIMARY KEY CLUSTERED ([ClubId] ASC),
    CONSTRAINT [UQ_Club_Name] UNIQUE ([Name]),
    CONSTRAINT [FK_Club_Stadium] FOREIGN KEY ([HomeStadiumId]) REFERENCES [football].[Stadium] ([StadiumId])
);
