CREATE TABLE [football].[Referee]
(
    [RefereeId] INT           IDENTITY (1, 1) NOT NULL,
    [FirstName] NVARCHAR (60) NOT NULL,
    [LastName]  NVARCHAR (60) NOT NULL,
    [Country]   NVARCHAR (80) NULL,
    CONSTRAINT [PK_Referee] PRIMARY KEY CLUSTERED ([RefereeId] ASC)
);
