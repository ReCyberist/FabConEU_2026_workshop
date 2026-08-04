-- Increment 2 (the trap): this innocent-looking view is added in the SAME piece of work as a
-- destructive change (see increment-2_drop-shirtnumber.md), so the drop is easy to miss in a
-- busy PR. Copy this into database/sql-projects/Views/vw_TeamRosterSizes.sql alongside
-- removing Player.ShirtNumber.
--
-- Harmless on its own — squad size per team. A "team" is a Club fielding a Men's/Women's side
-- (see football.Team), so the display name is the club name plus the category. The point is
-- that this distracts the reviewer from the column drop bundled with it.
CREATE VIEW [football].[vw_TeamRosterSizes]
AS
SELECT
    t.[TeamId],
    c.[Name] AS [ClubName],
    t.[Category],
    COUNT(p.[PlayerId]) AS [PlayerCount]
FROM [football].[Team] AS t
INNER JOIN [football].[Club] AS c
    ON c.[ClubId] = t.[ClubId]
LEFT JOIN [football].[Player] AS p
    ON p.[TeamId] = t.[TeamId]
GROUP BY t.[TeamId], c.[Name], t.[Category];
