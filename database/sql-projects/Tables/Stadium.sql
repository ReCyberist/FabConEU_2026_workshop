CREATE TABLE [football].[Stadium]
(
    [StadiumId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]      NVARCHAR (100) NOT NULL,
    [City]      NVARCHAR (80)  NOT NULL,
    [Country]   NVARCHAR (80)  NOT NULL,
    [Capacity]  INT            NULL,
    [Opened]    SMALLINT       NULL,
    CONSTRAINT [PK_Stadium] PRIMARY KEY CLUSTERED ([StadiumId] ASC),
    CONSTRAINT [CK_Stadium_Capacity] CHECK ([Capacity] IS NULL OR [Capacity] >= 0)
);
