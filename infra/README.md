# Infrastructure as Code

Deploy the workshop's cloud infrastructure — **Azure SQL** and **Fabric SQL** — entirely as
code. No portal clicking.

## Layout

```
infra/
├── azure-sql/
│   ├── terraform/   ← FOCUS: taught path
│   └── bicep/       ← reference/bonus
├── fabric-sql/
│   ├── terraform/   ← FOCUS: taught path
│   └── bicep/       ← reference/bonus
└── pipelines/
    ├── github-actions/  ← FOCUS: taught path
    └── azure-devops/    ← reference/bonus
```

## Rules
- **Everything runs.** Each module must `plan`/`apply` cleanly (or be clearly marked
  untested with a task raised).
- **No secrets in code.** Parameterise subscription IDs, names, and credentials; document
  the variables. Prefix resources `fabcon26-*` for easy teardown.
- **Keep Terraform and Bicep roughly in step** so the reference path stays honest.
- **Azure SQL and Fabric SQL side by side** — where they differ, add a note so the
  attendee content can explain the trade-off.

Learnings (quota surprises, provider quirks, Fabric-specific behaviour) →
[`../notes/LEARNINGS.md`](../notes/LEARNINGS.md).
