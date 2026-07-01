# Learnings Log 🔁

**Keep this updated.** Newest entries at the top. One entry per learning — a gotcha, a
better command, a broken assumption, a demo-timing note, a tester's confusion. See the
learnings loop in [`../CLAUDE.md`](../CLAUDE.md) §7.

Format:

```
## YYYY-MM-DD — short title
**Context:** what we were doing.
**Learning:** what we found out.
**Action:** what changed as a result (file updated, decision changed, task added). Link it.
```

---

## 2026-07-01 — Repo scaffolded and decisions locked
**Context:** First pass setting up the repo as the source of truth for the workshop.
**Learning:** Agreed the "all as code, focus in content" rule — the repo carries every
tooling variant (Terraform + Bicep, GitHub Actions + Azure DevOps, SQL projects + Flyway +
dbatools/dbops) but the taught content leads with **Terraform + GitHub Actions + SQL
projects**, covering **both Azure SQL and Fabric SQL** side by side. Site is **MkDocs
Material** → GitHub Pages.
**Action:** Recorded in [`decisions.md`](decisions.md) and [`../CLAUDE.md`](../CLAUDE.md).
Scaffold created; content still to be written (see [`../planning/tasks.md`](../planning/tasks.md)).

<!-- Add new entries above this line -->
