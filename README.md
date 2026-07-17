# FabConEU 2026 Workshop Planning

This repository stores the information Jess Pomfret and Rob Sewell will use to order, task manage, and deliver a full-day workshop.

## Workshop Abstract

### Azure SQL or Fabric SQL: Deploying Infrastructure and Databases as Code

Managing Azure SQL or Fabric SQL by hand doesn't scale. In this workshop, Jess Pomfret and Rob Sewell show you how to deploy both your Azure SQL infrastructure and your database schemas as code. You'll build real CI/CD pipelines that provision resources and ship database changes automatically — version controlled, repeatable, and ready for production. Hands-on, practical, and no clicking required.

## 👉 Start here

## First up Lets talk about the hardest part of IT

Wee can show you the tech part, hell most of you will prolly copilot it anyways but heres the bits copilot doesnt know - its the blood balloons with egos............ and feelings - This is what we have learnt

**Contributors (Jess, Rob, and AI agents): read [`CLAUDE.md`](CLAUDE.md) first** — it's the
canonical working guide (how we work, the decisions that shape the repo, and the
🔁 _keep learnings updated_ loop). Quick human on-ramp: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## What's in this repo

| Path | Purpose |
|------|---------|
| [`agenda/`](agenda/) | Full-day run-of-show (DRAFT). |
| [`notes/`](notes/) | Ideas, [decisions](notes/decisions.md), and the 🔁 [learnings log](notes/LEARNINGS.md). |
| [`planning/`](planning/) | [Ordering](planning/ordering.md) and [tasks](planning/tasks.md). |
| [`infra/`](infra/) | Infra as code — Azure SQL **and** Fabric SQL (Terraform + Bicep, GitHub Actions + Azure DevOps). |
| [`database/`](database/) | Database as code — SQL projects, Flyway, dbatools/dbops. |
| [`docs/`](docs/) | Attendee content (text) → built by MkDocs Material → GitHub Pages. |

## Key decisions (full log in [`notes/decisions.md`](notes/decisions.md))

- **Both platforms, side by side:** Azure SQL and Fabric SQL.
- **All tooling as code, focus in content:** the repo carries every variant; the taught
  content leads with **Terraform + GitHub Actions + SQL projects**.
- **Attendee site:** MkDocs Material on GitHub Pages — **prose as pages, code as downloads**.

## Planning Areas

- **Ordering**: track services, labs, assets, and prerequisites required before the event.
- **Task management**: track ownership, status, and deadlines for workshop preparation.
- **Delivery**: track agenda flow, demo/lab readiness, and day-of execution notes.
