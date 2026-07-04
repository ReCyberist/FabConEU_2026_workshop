-- Category keeps the men's and women's game side by side without duplicating structure:
-- e.g. 'Premier League' (Men) and 'Women's Super League' (Women).
CREATE TABLE [football].[Competition]
(
    [CompetitionId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]          NVARCHAR (100) NOT NULL,
    [Category]      NVARCHAR (10)  NOT NULL,
    [Country]       NVARCHAR (80)  NULL,
    [Tier]          TINYINT        NULL,
    CONSTRAINT [PK_Competition] PRIMARY KEY CLUSTERED ([CompetitionId] ASC),
    CONSTRAINT [UQ_Competition_Name_Category] UNIQUE ([Name], [Category]),
    CONSTRAINT [CK_Competition_Category] CHECK ([Category] IN (N'Men', N'Women'))
);
