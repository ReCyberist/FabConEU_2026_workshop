# Increment 2 — the destructive change (the trap)

Bundled with the harmless `vw_TeamRosterSizes` view (so it's easy to miss in review), this
increment **drops a populated column**. In a SQL project the change is declarative — you
*remove the column from the source*, and SqlPackage works out the `ALTER TABLE … DROP COLUMN`.

## The edit

In [`database/sql-projects/Tables/Player.sql`](../../sql-projects/Tables/Player.sql), delete the
`ShirtNumber` line:

```diff
     [FirstName]    NVARCHAR (60) NOT NULL,
     [LastName]     NVARCHAR (60) NOT NULL,
     [Position]     CHAR (2)      NULL,   -- GK / DF / MF / FW
-    [ShirtNumber]  TINYINT       NULL,
     [DateOfBirth]  DATE          NULL,
```

`ShirtNumber` **is populated by the [seed](../../sql-projects/Scripts/PostDeployment/Seed.sql)**,
so in Test it holds real data. Also remove it from the seed's `Player` INSERT column list and
`VALUES`, or the build will fail on the now-missing column.

## What each path shows

- **The DB plan (`DeployReport`) flags it before you deploy.** Against the Test database the
  report contains an `<Alert Name="DataIssue">` / *"possible data loss"* operation for the
  column drop — the reviewable "this will delete data" signal.
- **YOLO (`/p:BlockOnPossibleDataLoss=false`)** → the drop goes through and the data is
  **silently gone**. Prove it with `SELECT ShirtNumber` before (rows) and after (column doesn't
  exist).
- **Our shipped guard (`BlockOnPossibleDataLoss=True`, already in the publish profiles)** →
  the same publish **fails loudly** with *possible data loss*, and Test is never touched.

See [`README.md`](README.md) for the exact commands.
