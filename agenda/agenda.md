# Agenda — Full Day (DRAFT)

**Workshop:** Azure SQL or Fabric SQL: Deploying Infrastructure and Databases as Code
**Presenters:** Jess Pomfret & Rob Sewell · **Event:** FabCon Europe 2026, Barcelona

> Status: **DRAFT** — refine timings against real demo/lab runs. Log every timing surprise
> in [`../notes/LEARNINGS.md`](../notes/LEARNINGS.md).

Assumes ~6.5 hours of teaching within a 09:00–17:00 day. Every module = short concept →
live demo (Terraform + GitHub Actions + SQL projects) → hands-on lab. Azure SQL and Fabric
SQL are shown side by side throughout.

| Time | Module | Format | Notes |
|------|--------|--------|-------|
| 09:00 | Welcome & why infrastructure-as-code for data | Talk | Set the "no clicking required" promise. Story hook. |
| 09:20 | Environment check & prerequisites | Lab | Everyone confirms tooling works (see attendee prereqs). Buffer for stragglers. |
| 09:45 | Source control foundations for databases | Concept + demo | Git, repo layout, secrets handling. |
| 10:15 | Provisioning infra as code — Azure SQL (Terraform) | Demo + lab | First `terraform apply`. Bicep shown as reference. |
| 11:00 | ☕ Break | — | 15 min |
| 11:15 | Provisioning infra as code — Fabric SQL | Demo + lab | Side-by-side with Azure SQL; call out differences. |
| 12:00 | Database as code — SQL projects (`.sqlproj`/DACPAC) | Demo + lab | Build a DACPAC from the canonical sample schema. |
| 12:45 | 🍽 Lunch | — | 60 min |
| 13:45 | CI/CD part 1 — build & validate (GitHub Actions) | Demo + lab | Pipeline builds infra plan + DACPAC on PR. |
| 14:30 | CI/CD part 2 — deploy infra automatically | Demo + lab | Apply Terraform from the pipeline; environments/approvals. |
| 15:15 | ☕ Break | — | 15 min |
| 15:30 | CI/CD part 3 — ship database changes automatically | Demo + lab | Deploy DACPAC to Azure SQL & Fabric SQL from the pipeline. |
| 16:15 | Putting it together / migrations, drift & teardown | Demo + discussion | Migration-based options (Flyway, dbatools/dbops) as bonus; drift detection; clean teardown. |
| 16:45 | Wrap-up, resources, Q&A | Talk | Point to the site + downloads. Collect feedback → learnings. |
| 17:00 | End | — | |

## Backup / stretch material (if ahead of schedule)
- Bicep equivalents of each Terraform demo.
- Azure DevOps pipeline equivalents of the GitHub Actions demos.
- Flyway and dbatools/dbops migration demos against the same schema.

## Timing discipline
- Each lab has a hard "we move on" time; publish the answer/checkpoint state so nobody is
  stuck.
- Note actual vs planned durations during dry runs and log them.
