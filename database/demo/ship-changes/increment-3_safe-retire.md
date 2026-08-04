# Increment 3 — retire the column *safely* (the right way)

Same goal as Increment 2 (stop carrying `ShirtNumber` on `Player`), but **without losing
data** — two techniques. Pair either one with a **deliberate approval gate** (below).

## Option A — preserve the data first (pre-deploy migration)

Move the data to its new home *before* the drop, so the drop is safe because the data already
moved. Add a pre-deploy script to the SQL project (runs **before** the schema is applied):

```sql
-- database/sql-projects/Scripts/PreDeployment/Migrate-ShirtNumber.sql
-- Idempotent: only acts while the old column still exists. Copies ShirtNumber into its new
-- home before the DACPAC's ALTER TABLE ... DROP COLUMN runs.
IF COL_LENGTH('football.Player', 'ShirtNumber') IS NOT NULL
BEGIN
    UPDATE p
    SET p.[SquadNumber] = p.[ShirtNumber]   -- new column / table, added in the same increment
    FROM [football].[Player] AS p
    WHERE p.[SquadNumber] IS NULL
      AND p.[ShirtNumber] IS NOT NULL;
END;
```

(Register it in the `.sqlproj` as a `PreDeploy` script — one `<None Include="…"><CopyToOutputDirectory>` /
SDK `PreDeploy` item. Only one pre-deploy script is allowed; use `:r` includes to compose.)

## Option B — model it as a rename (no data movement at all)

If the column is just being *renamed* (`ShirtNumber` → `SquadNumber`), do the refactor in the
SQL project tooling so it records the intent in the **refactorlog**. SqlPackage then emits
`sp_rename` instead of `DROP` + `ADD` — **zero data loss, no migration script**. The
`.refactorlog` file travels with the project so every environment gets the rename, not a
drop-and-recreate.

## The gate (either option)

Ship the destructive deploy behind a **GitHub Environment required-reviewer approval** so a
human reads the DeployReport diff and approves — the *same* automated publish, just gated:

```yaml
# in the deploy job
jobs:
  publish:
    environment: test        # protection rule: required reviewers
    # …unchanged publish steps…
```

Nothing is clicked *in the database* — the approval is the only manual step, and it's still
"as code." Azure DevOps equivalent: an Environment **approval check**.

**Lesson:** destructive changes ship as code too — with a data-preserving migration (A) or a
rename refactor (B), **and** a human gate. Never a blind auto-apply.
