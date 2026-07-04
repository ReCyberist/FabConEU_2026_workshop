/*
    Post-deployment seed for the FabCon football sample.

    Design notes (kept deliberately clean -- our moderator Cláudio Silva tunes for a living):
      * Idempotent and re-runnable: every INSERT is guarded with WHERE NOT EXISTS on the
        target key, so re-publishing a demo database never double-inserts.
      * Set-based only. No cursors, no row-by-row loops, no MERGE (we sidestep the
        well-documented MERGE bugs/quirks and keep the pattern obvious).
      * Explicit column lists everywhere -- no SELECT *.
      * Explicit IDENTITY values via IDENTITY_INSERT so foreign keys are deterministic
        and the data reads the same on every deploy, on Azure SQL and Fabric SQL alike.

    Covers BOTH the men's and women's game from a shared set of clubs.
*/
SET NOCOUNT ON;

-------------------------------------------------------------------------------
-- Stadium
-------------------------------------------------------------------------------
SET IDENTITY_INSERT [football].[Stadium] ON;
INSERT INTO [football].[Stadium] ([StadiumId], [Name], [City], [Country], [Capacity], [Opened])
SELECT v.[StadiumId], v.[Name], v.[City], v.[Country], v.[Capacity], v.[Opened]
FROM (VALUES
    (1, N'Emirates Stadium',   N'London',       N'England', 60704, 2006),
    (2, N'Stamford Bridge',    N'London',       N'England', 40343, 1877),
    (3, N'Etihad Stadium',     N'Manchester',   N'England', 53400, 2003),
    (4, N'Spotify Camp Nou',   N'Barcelona',    N'Spain',   99354, 1957),
    (5, N'Santiago Bernabéu',  N'Madrid',       N'Spain',   78297, 1947),
    (6, N'Meadow Park',        N'Borehamwood',  N'England',  4502, 1933),
    (7, N'Kingsmeadow',        N'London',       N'England',  4850, 1989),
    (8, N'Estadi Johan Cruyff',N'Barcelona',    N'Spain',    6000, 2019)
) AS v ([StadiumId], [Name], [City], [Country], [Capacity], [Opened])
WHERE NOT EXISTS (SELECT 1 FROM [football].[Stadium] AS s WHERE s.[StadiumId] = v.[StadiumId]);
SET IDENTITY_INSERT [football].[Stadium] OFF;

-------------------------------------------------------------------------------
-- Club
-------------------------------------------------------------------------------
SET IDENTITY_INSERT [football].[Club] ON;
INSERT INTO [football].[Club] ([ClubId], [Name], [ShortName], [Founded], [HomeStadiumId])
SELECT v.[ClubId], v.[Name], v.[ShortName], v.[Founded], v.[HomeStadiumId]
FROM (VALUES
    (1, N'Arsenal',         N'ARS', 1886, 1),
    (2, N'Chelsea',         N'CHE', 1905, 2),
    (3, N'Manchester City', N'MCI', 1880, 3),
    (4, N'Barcelona',       N'BAR', 1899, 4),
    (5, N'Real Madrid',     N'RMA', 1902, 5)
) AS v ([ClubId], [Name], [ShortName], [Founded], [HomeStadiumId])
WHERE NOT EXISTS (SELECT 1 FROM [football].[Club] AS c WHERE c.[ClubId] = v.[ClubId]);
SET IDENTITY_INSERT [football].[Club] OFF;

-------------------------------------------------------------------------------
-- Competition (men's and women's, side by side)
-------------------------------------------------------------------------------
SET IDENTITY_INSERT [football].[Competition] ON;
INSERT INTO [football].[Competition] ([CompetitionId], [Name], [Category], [Country], [Tier])
SELECT v.[CompetitionId], v.[Name], v.[Category], v.[Country], v.[Tier]
FROM (VALUES
    (1, N'Premier League',        N'Men',   N'England', 1),
    (2, N'Women''s Super League', N'Women', N'England', 1),
    (3, N'La Liga',               N'Men',   N'Spain',   1),
    (4, N'Liga F',                N'Women', N'Spain',   1)
) AS v ([CompetitionId], [Name], [Category], [Country], [Tier])
WHERE NOT EXISTS (SELECT 1 FROM [football].[Competition] AS c WHERE c.[CompetitionId] = v.[CompetitionId]);
SET IDENTITY_INSERT [football].[Competition] OFF;

-------------------------------------------------------------------------------
-- Season
-------------------------------------------------------------------------------
SET IDENTITY_INSERT [football].[Season] ON;
INSERT INTO [football].[Season] ([SeasonId], [Name], [StartDate], [EndDate])
SELECT v.[SeasonId], v.[Name], v.[StartDate], v.[EndDate]
FROM (VALUES
    (1, N'2025/26', '2025-08-08', '2026-05-24')
) AS v ([SeasonId], [Name], [StartDate], [EndDate])
WHERE NOT EXISTS (SELECT 1 FROM [football].[Season] AS s WHERE s.[SeasonId] = v.[SeasonId]);
SET IDENTITY_INSERT [football].[Season] OFF;

-------------------------------------------------------------------------------
-- Team (one per club per category)
-------------------------------------------------------------------------------
SET IDENTITY_INSERT [football].[Team] ON;
INSERT INTO [football].[Team] ([TeamId], [ClubId], [Category], [CompetitionId])
SELECT v.[TeamId], v.[ClubId], v.[Category], v.[CompetitionId]
FROM (VALUES
    ( 1, 1, N'Men',   1),
    ( 2, 2, N'Men',   1),
    ( 3, 3, N'Men',   1),
    ( 4, 4, N'Men',   3),
    ( 5, 5, N'Men',   3),
    ( 6, 1, N'Women', 2),
    ( 7, 2, N'Women', 2),
    ( 8, 3, N'Women', 2),
    ( 9, 4, N'Women', 4),
    (10, 5, N'Women', 4)
) AS v ([TeamId], [ClubId], [Category], [CompetitionId])
WHERE NOT EXISTS (SELECT 1 FROM [football].[Team] AS t WHERE t.[TeamId] = v.[TeamId]);
SET IDENTITY_INSERT [football].[Team] OFF;

-------------------------------------------------------------------------------
-- Referee (Cláudio Silva keeps the game clean of fouls -- and code smells)
-------------------------------------------------------------------------------
SET IDENTITY_INSERT [football].[Referee] ON;
INSERT INTO [football].[Referee] ([RefereeId], [FirstName], [LastName], [Country])
SELECT v.[RefereeId], v.[FirstName], v.[LastName], v.[Country]
FROM (VALUES
    (1, N'Michael',  N'Oliver',      N'England'),
    (2, N'Anthony',  N'Taylor',      N'England'),
    (3, N'Rebecca',  N'Welch',       N'England'),
    (4, N'Jesús',    N'Gil Manzano', N'Spain'),
    (5, N'Cláudio',  N'Silva',       N'Portugal')
) AS v ([RefereeId], [FirstName], [LastName], [Country])
WHERE NOT EXISTS (SELECT 1 FROM [football].[Referee] AS r WHERE r.[RefereeId] = v.[RefereeId]);
SET IDENTITY_INSERT [football].[Referee] OFF;

-------------------------------------------------------------------------------
-- Player
-------------------------------------------------------------------------------
SET IDENTITY_INSERT [football].[Player] ON;
INSERT INTO [football].[Player] ([PlayerId], [TeamId], [FirstName], [LastName], [Position], [ShirtNumber], [DateOfBirth])
SELECT v.[PlayerId], v.[TeamId], v.[FirstName], v.[LastName], v.[Position], v.[ShirtNumber], v.[DateOfBirth]
FROM (VALUES
    -- Arsenal Men (Team 1)
    ( 1,  1, N'Bukayo',   N'Saka',       'FW',  7, '2001-09-05'),
    ( 2,  1, N'Martin',   N'Ødegaard',   'MF',  8, '1998-12-17'),
    ( 3,  1, N'Declan',   N'Rice',       'MF', 41, '1999-01-14'),
    ( 4,  1, N'David',    N'Raya',       'GK',  1, '1995-09-15'),
    -- Chelsea Men (Team 2)
    ( 5,  2, N'Cole',     N'Palmer',     'MF', 10, '2002-05-06'),
    ( 6,  2, N'Nicolas',  N'Jackson',    'FW', 15, '2001-06-20'),
    ( 7,  2, N'Enzo',     N'Fernández',  'MF',  8, '2001-01-17'),
    ( 8,  2, N'Robert',   N'Sánchez',    'GK',  1, '1997-11-18'),
    -- Arsenal Women (Team 6)
    ( 9,  6, N'Alessia',  N'Russo',      'FW', 23, '1999-02-08'),
    (10,  6, N'Beth',     N'Mead',       'FW',  9, '1995-05-09'),
    (11,  6, N'Leah',     N'Williamson', 'DF',  6, '1997-03-29'),
    (12,  6, N'Kim',      N'Little',     'MF', 10, '1990-06-29'),
    -- Chelsea Women (Team 7)
    (13,  7, N'Lauren',   N'James',      'FW', 10, '2001-09-29'),
    (14,  7, N'Sam',      N'Kerr',       'FW', 20, '1993-09-10'),
    (15,  7, N'Millie',   N'Bright',     'DF',  4, '1993-08-21'),
    (16,  7, N'Hannah',   N'Hampton',    'GK',  1, '2000-11-16')
) AS v ([PlayerId], [TeamId], [FirstName], [LastName], [Position], [ShirtNumber], [DateOfBirth])
WHERE NOT EXISTS (SELECT 1 FROM [football].[Player] AS p WHERE p.[PlayerId] = v.[PlayerId]);
SET IDENTITY_INSERT [football].[Player] OFF;

-------------------------------------------------------------------------------
-- Fixture  (4 played to populate the standings/top-scorers, 4 upcoming)
-------------------------------------------------------------------------------
SET IDENTITY_INSERT [football].[Fixture] ON;
INSERT INTO [football].[Fixture] ([FixtureId], [SeasonId], [CompetitionId], [HomeTeamId], [AwayTeamId], [StadiumId], [RefereeId], [KickoffUtc], [HomeScore], [AwayScore], [Status])
SELECT v.[FixtureId], v.[SeasonId], v.[CompetitionId], v.[HomeTeamId], v.[AwayTeamId], v.[StadiumId], v.[RefereeId], v.[KickoffUtc], v.[HomeScore], v.[AwayScore], v.[Status]
FROM (VALUES
    -- Played -- Premier League (men)
    (1, 1, 1, 1, 2, 1, 1, '2025-08-16T12:30:00', CAST(2 AS TINYINT), CAST(0 AS TINYINT), N'Played'),
    (2, 1, 1, 2, 1, 2, 2, '2025-11-30T16:30:00', CAST(1 AS TINYINT), CAST(1 AS TINYINT), N'Played'),
    -- Played -- Women's Super League
    (3, 1, 2, 6, 7, 6, 3, '2025-09-21T14:00:00', CAST(3 AS TINYINT), CAST(1 AS TINYINT), N'Played'),
    (4, 1, 2, 7, 6, 7, 3, '2026-02-15T14:00:00', CAST(2 AS TINYINT), CAST(2 AS TINYINT), N'Played'),
    -- Upcoming -- El Clásico (men and women) + more
    (5, 1, 3, 4, 5, 4, 4, '2026-04-05T20:00:00', NULL, NULL, N'Scheduled'),
    (6, 1, 4, 9,10, 8, 5, '2026-04-12T12:00:00', NULL, NULL, N'Scheduled'),
    (7, 1, 1, 3, 1, 3, 1, '2026-03-15T16:30:00', NULL, NULL, N'Scheduled'),
    (8, 1, 2, 8, 6, NULL, 3, '2026-03-22T14:00:00', NULL, NULL, N'Scheduled')
) AS v ([FixtureId], [SeasonId], [CompetitionId], [HomeTeamId], [AwayTeamId], [StadiumId], [RefereeId], [KickoffUtc], [HomeScore], [AwayScore], [Status])
WHERE NOT EXISTS (SELECT 1 FROM [football].[Fixture] AS f WHERE f.[FixtureId] = v.[FixtureId]);
SET IDENTITY_INSERT [football].[Fixture] OFF;

-------------------------------------------------------------------------------
-- Goal  (totals match the fixture scores above)
-------------------------------------------------------------------------------
SET IDENTITY_INSERT [football].[Goal] ON;
INSERT INTO [football].[Goal] ([GoalId], [FixtureId], [PlayerId], [TeamId], [Minute], [IsPenalty], [IsOwnGoal])
SELECT v.[GoalId], v.[FixtureId], v.[PlayerId], v.[TeamId], v.[Minute], v.[IsPenalty], v.[IsOwnGoal]
FROM (VALUES
    -- Fixture 1: Arsenal 2-0 Chelsea (men)
    ( 1, 1,  1, 1, 23, 0, 0),   -- Saka
    ( 2, 1,  2, 1, 67, 0, 0),   -- Ødegaard
    -- Fixture 2: Chelsea 1-1 Arsenal (men)
    ( 3, 2,  5, 2, 40, 1, 0),   -- Palmer (pen)
    ( 4, 2,  3, 1, 82, 0, 0),   -- Rice
    -- Fixture 3: Arsenal 3-1 Chelsea (women)
    ( 5, 3,  9, 6, 12, 0, 0),   -- Russo
    ( 6, 3,  9, 6, 55, 0, 0),   -- Russo
    ( 7, 3, 10, 6, 78, 0, 0),   -- Mead
    ( 8, 3, 13, 7, 66, 0, 0),   -- James
    -- Fixture 4: Chelsea 2-2 Arsenal (women)
    ( 9, 4, 14, 7, 30, 0, 0),   -- Kerr
    (10, 4, 13, 7, 71, 0, 0),   -- James
    (11, 4,  9, 6,  5, 0, 0),   -- Russo
    (12, 4, 12, 6, 88, 1, 0)    -- Little (pen)
) AS v ([GoalId], [FixtureId], [PlayerId], [TeamId], [Minute], [IsPenalty], [IsOwnGoal])
WHERE NOT EXISTS (SELECT 1 FROM [football].[Goal] AS g WHERE g.[GoalId] = v.[GoalId]);
SET IDENTITY_INSERT [football].[Goal] OFF;
GO
