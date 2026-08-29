# Working Instructions — FabCon Europe 2026 Workshop

**This file is the canonical guide for how we work in this repo.** It is read by both
humans (Jess & Rob) and AI agents (Claude Code). Keep it accurate. When you learn
something that changes how the repo should be built or maintained, update this file
**and** log it in [`notes/LEARNINGS.md`](notes/LEARNINGS.md).

> 🔁 **The golden rule:** every session ends with learnings captured. If you discovered
> a gotcha, a better command, a broken assumption, or a decision — write it down before
> you stop. Future-us and every attendee benefits.

---

## 1. What this repo is

The single source of truth for a **full-day, hands-on workshop** at **FabCon Europe 2026,
Barcelona**, presented by **Jess Pomfret** and **Rob Sewell**.

**Abstract — _Azure SQL or Fabric SQL: Deploying Infrastructure and Databases as Code_:**
Managing Azure SQL or Fabric SQL by hand doesn't scale. We show attendees how to deploy
both their infrastructure and their database schemas as code, building real CI/CD
pipelines that provision resources and ship database changes automatically — version
controlled, repeatable, production-ready. Hands-on, practical, no clicking required.

The repo holds four things:
1. **Planning** — agenda, notes, ideas, ordering, task management (for Jess & Rob).
2. **Infrastructure code** — deploy Azure SQL **and** Fabric SQL as code.
3. **Database code** — ship schema changes as code through pipelines.
4. **Attendee content** — delivered via **GitHub Pages**: all prose as web pages, all
   code as downloadable bundles.

## 2. Decisions that shape everything (see `notes/decisions.md` for the full log)

| Area | Decision |
|------|----------|
| **Platform scope** | Cover **both Azure SQL and Fabric SQL, side by side.** |
| **IaC tooling** | Provide **all** as working code/demos (Terraform, Bicep). **Written/taught content focuses on Terraform.** |
| **CI/CD** | Provide **all** as working code/demos (GitHub Actions, Azure DevOps). **Written/taught content focuses on GitHub Actions.** |
| **Database deploy** | Provide **all** as working code (SQL projects, Flyway, dbatools/dbops). **Written/taught content focuses on SQL projects (`.sqlproj` / DACPAC).** |
| **Attendee site** | **MkDocs Material**, published to **GitHub Pages**. |

**"All as code, focus in content"** is the rule to remember: the repo contains every
variant so nothing is hand-wavy, but the pages we write and the demos we run lead with
Terraform + GitHub Actions + SQL projects. The other variants are there for the curious
and for our own credibility.

## 3. Repo map

```
├── CLAUDE.md              ← you are here (working instructions)
├── CONTRIBUTING.md        ← human quick-start, points back here
├── README.md              ← public overview + abstract
├── mkdocs.yml             ← attendee site config (MkDocs Material)
├── includes/glossary.md   ← hover translations (acronyms + British idioms) — see §5c
├── agenda/                ← the run-of-day
├── notes/
│   ├── Ideas.md           ← brain-dump, anything goes
│   ├── decisions.md       ← ADR-lite: why we chose what we chose
│   └── LEARNINGS.md       ← 🔁 running log — KEEP THIS UPDATED
├── planning/
│   ├── ordering.md        ← services, labs, assets, prerequisites to order
│   └── tasks.md           ← ownership, status, deadlines
├── infra/                 ← infrastructure as code (Azure SQL + Fabric SQL)
│   ├── azure-sql/{terraform/{demo,shared-endpoint},bicep}
│   ├── fabric-sql/{terraform,bicep}
│   └── pipelines/{github-actions,azure-devops}
├── database/              ← database as code
│   ├── sql-projects/      ← FOCUS: .sqlproj / DACPAC
│   ├── flyway/
│   └── dbatools-dbops/
└── docs/                  ← attendee content (text) → built by MkDocs → GitHub Pages
```

## 4. How we work

- **Small, verifiable steps.** Every piece of infra/database code must actually run.
  If you can't run it, mark it clearly as untested in the file and add a task in
  `planning/tasks.md`.
- **Everything is code, nothing is clicked.** If an instruction says "click", it's a bug.
  Rewrite it as a command, a template, or a pipeline step.
- **Content vs. code separation.** Prose that teaches lives in `docs/` (becomes web
  pages). The code it references lives in `infra/` and `database/` and is shipped to
  attendees as downloads (see §7). Don't paste large code blocks into `docs/` — link to
  the real file and show short excerpts.
- **Two audiences, two registers.** Planning files are for us — terse, honest, TODO-heavy.
  `docs/` is for attendees — polished, tested, friendly. The attendee register is set out in
  full in **§5 (Voice)**; follow it for anything that ships to the site.
- **Naming.** Prefix workshop resources so they're easy to find and tear down, e.g.
  `fabcon26-*`. Never commit secrets, connection strings, or subscription IDs — use
  variables and document them.
- **Code quality — clean enough for the front row.** Our moderator is **Cláudio Silva**,
  a performance-tuning expert. Ship no code smells and no obvious performance traps.
  For SQL specifically: SARGable predicates (no functions wrapping filtered columns),
  explicit column lists (never `SELECT *`), set-based over row-by-row (no cursors), and
  **no `MERGE`** (known correctness/locking gotchas — use `INSERT … WHERE NOT EXISTS`).
  T-SQL static code analysis runs on every SQL-project build (`RunSqlCodeAnalysis`) and in
  CI with `-warnaserror`; keep it at **zero findings**.
- **CI checks our code.** `.github/workflows/ci.yml` validates the repo on every push/PR.
  It starts with the SQL project build + analysis; add a job per area as we build it out.
- **Shell examples in PowerShell.** Every command example — in `docs/`, READMEs, and
  planning — uses **PowerShell**. The presenters run Windows and demo in PowerShell, so
  examples must match what they'll type: PowerShell cmdlets and syntax (`Copy-Item`,
  `$env:VAR = '…'`), not bash (`cp`, `export`, `\` line-continuations). Fence them
  ` ```powershell `. Cross-platform tools (dotnet, terraform, sqlpackage, mkdocs, pip) run
  the same — only the shell glue changes. Where a command genuinely differs across shells and
  both matter to attendees, add a tabbed bash alternative, but PowerShell is the default and
  the one we test.

## 5. Voice — how attendee content reads

This applies to everything in `docs/`. The room in Barcelona will contain **many attendees who do
not have English as a first language**, and that single fact shapes every rule below.

Attendee pages have **two registers**, and the line between them is the line between *talking
about a thing* and *doing the thing*. Know which one you are writing before you write it.

### 5a. Discussion register — the prose around the work

Intros, "why this matters", section openers, asides, wrap-ups. Here we can relax.

- **Tone: gentle, professional, quietly British.** Warm and calm — never breathless, never
  salesy, never patronising.
- **Dry humour is welcome here**, and only here. Keep it to an aside or a closing line.
- **Idioms and informal British words are allowed here**, on one condition: give them a hover
  translation (see §5c). "Kit", "faff", "sorted" are fine. In a step, they are not.
- **Reassure rather than caveat.** "Both are entirely respectable choices" beats "or just watch,
  I suppose".
- **Humour never carries meaning.** Every sentence must stay correct and complete if the joke
  lands flat or the tooltip never appears.

### 5b. Step register — anything the attendee follows to make something happen

Numbered procedures, commands, configuration, troubleshooting. Here we are precise and plain.

- **Numbered list. One action per step**, in the order it is performed. No paragraph-shaped
  instructions.
- **Say *where* before *what*:** "In the `infra/azure-sql/terraform/demo` folder, run:".
- **Say what success looks like** — the expected output, the resource that now exists, the row
  count. An attendee must be able to tell the step worked without asking.
- **No vagueness.** Not "configure the provider", but "set `subscription_id` in
  `terraform.tfvars`".
- **No hedging.** Cut "should", "hopefully", "might", "we think", "basically", "just". If a
  command works, say it works. If it can fail, say exactly when and what to do about it.
- **No humour, no idioms, no phrasal verbs, no cultural references.** Plain words: "use" not
  "leverage", "set up" not "spin up", "delete" not "nuke".
- **Short sentences, one idea each.** Prefer full stops to semicolons and nested clauses.
- **The same word for the same thing, every time.** Pick "folder" or "directory" and never swap.
- **Watch the length.** Clarity earns words; padding does not. When a step grows long, rewrite
  it — do not pile on caveats.
- **Never promise what we have not tested.** Untested content is marked as such (see §4).

### 5c. Hover translations (how the tooltips work)

`includes/glossary.md` is auto-appended to every page by `pymdownx.snippets`, so any term defined
there gets a dotted underline and a hover tooltip **everywhere it appears** — no per-page markup:

```markdown
*[kit]: British informal — equipment. Here it means your own laptop, subscription and tools
```

- Use it for **acronyms** (expanded on first use in the text as well, per page) and for
  **British idioms** used in the discussion register.
- Matching is exact and case-sensitive, and applies to every page — so only add words we are
  content to see underlined inside a step, too.
- For a one-off phrase, inline HTML is fine: `<abbr title="plain English">the phrase</abbr>`.
- **Tooltips do not appear on touch devices.** They are a courtesy, never the meaning.

## 6. Editing the attendee site (MkDocs Material)

- Content is Markdown in `docs/`. Navigation is defined in `mkdocs.yml`.
- Preview locally: `pip install -r requirements.txt` then `mkdocs serve` (published/teaser
  site) or `mkdocs serve -f mkdocs.local.yml` to preview the **full** site including pages
  still held from publish by `exclude_docs`. The overlay is local-only — CI and Pages always
  build the default `mkdocs.yml`.
- Publish: GitHub Actions builds and deploys to GitHub Pages on push to `main`
  (workflow to be added under `.github/workflows/`).
- Use Material features: admonitions (`!!! note`), tabbed content (great for
  Azure SQL vs Fabric SQL, or Terraform vs Bicep), and code annotations.

## 7. Code delivery to attendees

- **Prose = pages, code = downloads.** Attendees read the steps on the site and download
  the code to run it.
- Downloadable bundles are produced from `infra/` and `database/` (zipped per module) and
  linked from the relevant `docs/` page. The packaging step is a pipeline job (to be
  added) — do not hand-zip and commit binaries.

## 8. 🔁 The learnings loop (do not skip)

At the **end of every working session**, before you stop:
1. Add an entry to [`notes/LEARNINGS.md`](notes/LEARNINGS.md) — even a one-liner.
2. If the learning changes a decision, update `notes/decisions.md`.
3. If it changes how we work, update **this file**.
4. If it's a task, add/close it in `planning/tasks.md`.

Good learnings: a Terraform provider quirk, an Azure/Fabric quota surprise, a demo timing
that ran long, a lab step that confused a tester, a command that's better than the one we
documented.

## 9. Personality (tasteful, not distracting)

Jess is a **Taylor Swift** fan, Rob is a **Metallica** fan, and both love
**football (soccer)**. A little themed flavour in sample data, database names, or example
records is welcome (a football-fixtures sample DB is a strong candidate). Keep it light —
the technical content always comes first.
