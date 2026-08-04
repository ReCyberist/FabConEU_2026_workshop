# Attendee content — design spec

**Date:** 2026-08-04 · **Status:** Approved (Rob) · **Feeds:** tasks [#22](tasks.md) (per-module
`docs/` pages) and [#2](tasks.md) (prerequisites page).

> **Why this lives in `planning/`, not `docs/superpowers/specs/`:** `docs/` is the published
> MkDocs attendee site, so an internal spec there would break `mkdocs build --strict` (or need
> excluding). This repo already keeps design docs in `planning/` (see
> [`ship-changes-increments.md`](ship-changes-increments.md)) — we follow that convention.

---

## 1. Goal & context

Turn the attendee site from a single teaser page into a complete, honest, revealable workshop
site. Today only [`docs/index.md`](../docs/index.md) (teaser) and
[`docs/database/sample-database.md`](../docs/database/sample-database.md) exist; the engineering
(infra, database, CI/CD — see [`tasks.md`](tasks.md)) is far ahead of the attendee prose.

The taught path is already **live-verified on the Azure SQL side** (one pipeline dispatch
provisions infra then publishes schema + seed, passwordless, with a `DeployReport` "database
plan" step). This spec plans the prose that teaches that path — **prose = pages, code =
downloads** ([CLAUDE.md §6](../CLAUDE.md)).

## 2. Scope

**In scope:** the attendee-facing Markdown under `docs/`, the `mkdocs.yml` nav/`exclude_docs`
wiring, and keeping `mkdocs build --strict` green — delivered in three phases (§8).

**Out of scope:** revealing the site (a later, one-PR decision the presenters make); new
infra/database/pipeline code; the Fabric live-verification (task [#20](tasks.md)); wiring the
approval gate (task [#21](tasks.md), plan-blocked); screenshots (added once demos are captured).

## 3. Decisions

Resolved for this work (approved 2026-08-04):

- **A — Depth posture: hybrid.** Pages teach the concept and narrative, show the essential
  happy-path PowerShell commands and short excerpts inline so a page is followable during the
  live demo, and link to the real files + downloadable bundle for the full thing and variants.
  Honours [CLAUDE.md §6](../CLAUDE.md) ("no large code blocks — link + short excerpts"); the
  demo/module READMEs remain the exhaustive command source of truth.
- **B — Reference/bonus tooling: weave in + one index page.** Bicep, Azure DevOps, Flyway and
  dbatools/dbops appear as reference tabs/callouts inside the focus pages (e.g. a "Bicep
  equivalent" tab on the Azure SQL page), plus one **"Other tooling"** reference page linking all
  variants. Keeps the taught narrative on the focus path ([D2](../notes/decisions.md)) without
  hiding the "all as code" credibility.
- **C — Include two framing pages:** **Welcome & how the day works** and **Resources & next
  steps**, rounding out the site beyond the strictly hands-on modules.

Inherited: [D1](../notes/decisions.md) (both platforms, side by side), [D2](../notes/decisions.md)
(focus = Terraform + GitHub Actions + SQL projects; rest is reference),
[D6](../notes/decisions.md) (bring-your-own; two optional lab parts + one unsupported shared
endpoint).

## 4. Information architecture

Topic-based sections (extending the commented nav already in [`mkdocs.yml`](../mkdocs.yml)). Each
page maps to an agenda module and the real code it links to.

| Nav section / page | File | Agenda | Backing code | Phase |
|---|---|---|---|---|
| **Home** | `index.md` | 09:00 | — | exists (teaser; reveal-time rewrite later) |
| **Getting started** → Welcome & how the day works | `setup/welcome.md` | 09:00 | — | 1 (stub) |
| Getting started → Prerequisites | `setup/prerequisites.md` | 09:20 | [`ordering.md`](ordering.md), [D6](../notes/decisions.md) | **2** |
| **Foundations** → Source control for databases | `foundations/source-control.md` | 09:45 | repo layout, `.gitignore` | 3 |
| **Infrastructure as code** → Azure SQL (Terraform) | `infra/azure-sql.md` | 10:15 | [`infra/azure-sql/`](../infra/azure-sql/) | **3** |
| Infrastructure as code → Fabric SQL (Terraform) | `infra/fabric-sql.md` | 11:15 | [`infra/fabric-sql/`](../infra/fabric-sql/) | 3 (caveated) |
| **Database as code** → The sample database | `database/sample-database.md` | 12:00 | [`database/sql-projects/`](../database/sql-projects/) | exists |
| Database as code → SQL projects (`.sqlproj`/DACPAC) | `database/sql-projects.md` | 12:00 | [`database/sql-projects/`](../database/sql-projects/) | **3** |
| **CI/CD** → Build & validate | `cicd/build-validate.md` | 13:45 | `ci.yml`, `azure-sql-plan.yml` | **3** |
| CI/CD → Deploy infrastructure | `cicd/deploy-infra.md` | 14:30 | `azure-sql-apply.yml` | **3** |
| CI/CD → Ship database changes | `cicd/ship-database-changes.md` | 15:30 | [`database/demo/ship-changes/`](../database/demo/ship-changes/), [`ship-changes-increments.md`](ship-changes-increments.md) | **3** (Azure side) |
| **Wrap up** → Migrations, drift & teardown | `wrap-up/migrations-drift-teardown.md` | 16:15 | Flyway/dbatools READMEs, destroy workflows | 3 |
| Wrap up → Resources & next steps | `wrap-up/resources.md` | 16:45 | download bundles | 3 |
| **Reference** → Other tooling | `reference/other-tooling.md` | backup/stretch | Bicep, ADO, Flyway, dbatools | 3 |

~12 new pages + the 2 that exist. Coverage matches every agenda slot.

## 5. Standard page template

Every module page follows this shape (headings scale to the module):

1. **H1 + one-line what/why**, then a short intro (the "why as code").
2. **`!!! note "Follow along — or just watch"`** — the standard bring-your-own admonition: what
   this module needs, link to Prerequisites.
3. **What you'll build** — a tight bullet list or "at a glance" table.
4. **The concept** — the ~5-minute teaching prose from the agenda module.
5. **Azure SQL / Fabric SQL** — side-by-side via `=== "Azure SQL"` content tabs where they
   differ (`content.tabs.link` keeps them synced site-wide).
6. **The code** — link to the real files on GitHub + short excerpts + the key happy-path
   PowerShell commands + the download-bundle link.
7. **Checkpoint** — the hard "we move on" state (agenda timing discipline); what success looks like.
8. **Gotchas** — the relevant [`LEARNINGS.md`](../notes/LEARNINGS.md) items distilled for
   attendees (region restriction, Entra-group admin, `DeployReport` = the DB's `plan`, …).
9. **What's next** → link to the next module.

In **Phase 1** each page carries this structure as headings + a 1–2 line intent per section +
the real code links wired (the code already exists), fronted by a `<!-- DRAFT: skeleton only -->`
banner removed on flesh-out.

## 6. Content conventions

- **Voice:** polished, friendly, attendee-facing ([CLAUDE.md §4](../CLAUDE.md) "two audiences,
  two registers"). Style exemplar = [`sample-database.md`](../docs/database/sample-database.md).
- **Shell:** PowerShell for every command example ([CLAUDE.md §4](../CLAUDE.md)) — cmdlets +
  `$env:VAR`, fenced ` ```powershell `. Cross-platform tools (dotnet, terraform, sqlpackage,
  mkdocs) run the same; only shell glue changes.
- **Code:** short excerpts inline; link the real file on GitHub and the download bundle for the
  full source — never paste large blocks ([CLAUDE.md §6](../CLAUDE.md)).
- **Material features:** admonitions (`!!! note/tip/warning`), content tabs (Azure SQL vs Fabric
  SQL; Terraform vs Bicep), Mermaid where a diagram helps, code annotations.
- **Naming/secrets:** `fabcon26-*` resource prefixes; never a secret, connection string, or
  subscription id — variables, documented.
- **Theme:** light football flavour is welcome (the sample DB already is); technical content first.

## 7. Reveal & build safety

- **Stay in teaser mode throughout.** Every new page is added to `exclude_docs` in
  [`mkdocs.yml`](../mkdocs.yml); the published site stays just the teaser until the presenters
  choose to reveal.
- **Prepare the full nav but keep it commented**, so reveal remains a one-PR diff (delete the
  `exclude_docs` entries + uncomment the nav).
- **Build-safety constraint:** `mkdocs build --strict` errors on a link **from a built page to an
  excluded page** — so `index.md` must not link to held pages until reveal (links between two
  excluded pages are fine, since neither is built). Verified per phase.
- CI already runs `mkdocs build --strict` on docs changes ([`ci.yml`](../.github/workflows/ci.yml)).

## 8. Phased delivery plan

Each phase is one branch/PR (matching the repo's PR flow).

### Phase 1 — Skeleton the whole site
**Deliverable:** every §4 page that does **not** already exist (i.e. all but `index.md` and
`database/sample-database.md`) created as a templated stub with code links wired; full nav added
to `mkdocs.yml` **commented**; every new stub listed in `exclude_docs`.
**Acceptance:** each new page file exists with the §5 section headings + intent stubs + wired code
links + DRAFT banner; `mkdocs build --strict` exits 0 publishing only `index.html` (+ auto
`404.html`); no built page links to an excluded page.

### Phase 2 — Prerequisites page (#2)
**Deliverable:** [`setup/prerequisites.md`](../docs/setup/prerequisites.md) fleshed to polished
quality from [D6](../notes/decisions.md) + [`ordering.md`](ordering.md).
**Acceptance:** covers the two **optional** BYO paths (IaC needs own Azure sub; DB-deploy needs a
target SQL), the shared **unsupported** endpoint, cost + **teardown** warnings, and the minimal
local toolchain (git; for the DB part dotnet/SqlPackage); DRAFT banner removed; page still
excluded (teaser) but internally complete; `--strict` green.

### Phase 3 — Azure SQL core
**Deliverable:** flesh the live-verified path to revealable quality — `foundations/source-control`,
`infra/azure-sql`, `database/sql-projects`, `cicd/build-validate`, `cicd/deploy-infra`,
`cicd/ship-database-changes` (Azure side) — plus the framing/reference pages (decisions B & C) and
the remaining stubs to a consistent state.
**Acceptance:** each core page complete per template + conventions; the Fabric infra page and all
Fabric sections carry a clear **"code ready, live-verification pending ([#20](tasks.md))"** callout;
the approval-gate content documents the **pattern + the plan constraint** ([#21](tasks.md)) rather
than implying it's wired; reference/bonus tooling woven per decision B; `--strict` green.

## 9. Success criteria

- An attendee (or the presenters) can read the site and understand and follow the workshop end to
  end on the Azure SQL path, with code downloaded rather than pasted.
- The site is **one PR away from reveal** at any checkpoint (delete `exclude_docs` + uncomment nav).
- `mkdocs build --strict` stays green throughout.
- Nothing on the site over-claims: unverified Fabric and un-wired gate are honestly caveated.

## 10. Open items / caveats (not blockers for this content work)

- **Fabric live-verify** (task [#20](tasks.md)) — needs a tenant setting + workspace role + an
  F-SKU capacity. Until then Fabric pages are written but caveated.
- **Approval gate** (task [#21](tasks.md)) — GitHub Environment protection rules need Team/
  Enterprise on a private repo; documented, not wired.
- **Reveal date** — not recorded in the repo; sets the flesh-out deadline. Presenters' call.
- **Screenshots** — deferred until pipeline runs / deploy reports are captured.

## 11. References

[CLAUDE.md](../CLAUDE.md) · [agenda](../agenda/agenda.md) · [decisions](../notes/decisions.md) ·
[LEARNINGS](../notes/LEARNINGS.md) · [ordering](ordering.md) ·
[ship-changes-increments](ship-changes-increments.md) · [mkdocs.yml](../mkdocs.yml) ·
[sample-database.md](../docs/database/sample-database.md)
