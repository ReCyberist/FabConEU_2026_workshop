/*
    Put the ShirtNumber data back after increment 2.

    Increment 2a drops the populated ShirtNumber column with the safety disabled, and the
    recovery re-adds the COLUMN but not the DATA -- the seed only inserts players that are
    missing, it never updates the ones already there. That leaves ShirtNumber present and
    empty, which is exactly the state increment 3 cannot start from: increment 3 needs
    ShirtNumber present AND populated.

    In production the way back is a point-in-time restore, not re-typing the values. We run
    this only so the whole demo stays on one database instead of needing a second, pristine
    one -- and we say so out loud when we run it. It is a demo convenience, not a recovery
    plan.

    House rules, same as Seed.sql: set-based, explicit column list, no cursor, no MERGE. The
    WHERE guard fills only the empty rows, so re-running it never overwrites a value that is
    already there.
*/
SET NOCOUNT ON;

UPDATE p
SET p.[ShirtNumber] = v.[ShirtNumber]
FROM [football].[Player] AS p
INNER JOIN (VALUES
    -- Arsenal Men
    ( 1,  7),   -- Saka
    ( 2,  8),   -- Ødegaard
    ( 3, 41),   -- Rice
    ( 4,  1),   -- Raya
    -- Chelsea Men
    ( 5, 10),   -- Palmer
    ( 6, 15),   -- Jackson
    ( 7,  8),   -- Fernández
    ( 8,  1),   -- Sánchez
    -- Arsenal Women
    ( 9, 23),   -- Russo
    (10,  9),   -- Mead
    (11,  6),   -- Williamson
    (12, 10),   -- Little
    -- Chelsea Women
    (13, 10),   -- James
    (14, 20),   -- Kerr
    (15,  4),   -- Bright
    (16,  1)    -- Hampton
) AS v ([PlayerId], [ShirtNumber])
    ON v.[PlayerId] = p.[PlayerId]
WHERE p.[ShirtNumber] IS NULL;
GO
