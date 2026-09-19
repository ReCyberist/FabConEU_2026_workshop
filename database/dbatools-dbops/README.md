# dbatools / dbops (reference / bonus)

PowerShell-first migrations — fits Jess & Rob's dbatools heritage. Deploys the same
canonical schema as the SQL project using dbops/dbatools. Reference path; keep the schema
identical to [`../sql-projects/`](../sql-projects/).

## What dbatools and dbops are

Two PowerShell tools that pair naturally:

- **dbops** does the deployment — a PowerShell module (built on [DbUp](https://dbup.readthedocs.io/))
  that runs an ordered set of migration scripts once each and records them in a tracking table. It
  is the *migration-based* model, the same idea as Flyway, but native to PowerShell.
- **dbatools** is the broader community PowerShell toolkit for SQL Server — the day-to-day
  swiss-army knife the presenters help maintain, useful for the surrounding work (connections,
  backups, checks) around a deployment.

PowerShell-first, so it suits the presenters' heritage and the workshop's Windows/PowerShell
examples. Same destination as the taught path: the schema it builds must match
[`../sql-projects/`](../sql-projects/) exactly.

## Learn more

- **dbatools** — [dbatools.io](https://dbatools.io) · [source](https://github.com/dataplat/dbatools)
- **dbops** — [source & docs](https://github.com/dataplat/dbops) · [PowerShell Gallery](https://www.powershellgallery.com/packages/dbops)
- **DbUp** (what dbops builds on) — [dbup.readthedocs.io](https://dbup.readthedocs.io/)
