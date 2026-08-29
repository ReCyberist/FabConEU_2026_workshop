# Contributing / Working in this repo

This is the workshop's source of truth. **Read [`CLAUDE.md`](CLAUDE.md) first** — it's the
canonical working guide for both humans and AI agents.

## Quick start
1. Skim [`CLAUDE.md`](CLAUDE.md) (how we work, the key decisions, the repo map).
2. Check [`planning/tasks.md`](planning/tasks.md) for what needs doing.
3. Make small, runnable changes. No secrets. No "click here" instructions.
4. **Before you stop:** add a line to [`notes/LEARNINGS.md`](notes/LEARNINGS.md). This is
   not optional — it's how the workshop gets better each pass.

## Preview the attendee site

Note, if in a virtual environment you may need to

```bash
cd /path/to/FabConEU_2026_workshop
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

```powershell
pip install -r requirements.txt
mkdocs serve                        # published (teaser) site — what attendees see today
mkdocs serve -f mkdocs.local.yml    # the FULL site, revealing pages still held from publish
```
The published site is held in **teaser mode** (`exclude_docs` in `mkdocs.yml`) until the
reveal, so `mkdocs serve` shows only what's live. Use the `mkdocs.local.yml` overlay to write
and preview held pages locally — it never affects the pushed site.

## Where things go
- Planning/prep → `agenda/`, `notes/`, `planning/`
- Infra code → `infra/` · Database code → `database/`
- Attendee prose → `docs/` (code stays in `infra/`/`database/`, shipped as downloads)
