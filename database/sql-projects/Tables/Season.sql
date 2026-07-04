CREATE TABLE [football].[Season]
(
    [SeasonId]  INT          IDENTITY (1, 1) NOT NULL,
    [Name]      NVARCHAR (9) NOT NULL,   -- e.g. '2025/26'
    [StartDate] DATE         NOT NULL,
    [EndDate]   DATE         NOT NULL,
    CONSTRAINT [PK_Season] PRIMARY KEY CLUSTERED ([SeasonId] ASC),
    CONSTRAINT [UQ_Season_Name] UNIQUE ([Name]),
    CONSTRAINT [CK_Season_Dates] CHECK ([EndDate] > [StartDate])
);
