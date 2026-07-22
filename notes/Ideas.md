<img width="2505" height="800" alt="image" src="https://github.com/user-attachments/assets/a273e7ab-1d87-493d-99b5-da562131aa08" />

## Demo idea: "blind deploy vs. schema compare" data-loss cautionary tale

**For:** 15:30 agenda slot ("CI/CD part 3 — ship database changes automatically") /
feeds task #15 in `planning/tasks.md`.

**Setup:** a two-stage pipeline (Dev → Test), each stage backed by its own Fabric
workspace with its own Fabric SQL database.

**The story we tell:**
1. In **Dev**, make two changes in the same piece of work: add a new view, and drop a
   table column.
2. In **Test**, that column already has real data in it (seeded/sample data — not
   empty).
3. **Bad path (the trap):** pipeline blindly pushes the Dev schema state straight to
   Test (e.g. naive DACPAC publish / force apply with no review step). The column drop
   goes through and the data in Test is silently gone. This is the "why you can't just
   YOLO deploy schema" moment.
4. **Good path (the fix):** run a **schema compare** against the Fabric SQL database
   item (Dev vs. Test) as part of the pipeline, surface the drop as a reviewable diff,
   and apply the update **manually/deliberately** once a human has seen "this will drop
   a populated column" — rather than auto-applying. Show what that gate looks like in
   the pipeline (manual approval step) and/or the schema-compare output that would have
   flagged it.

**Why this belongs in the workshop:** it's a punchy, memorable way to justify why we
teach schema-compare-and-review rather than "just publish the DACPAC and hope," and it
gives Cláudio-grade rigor to the CI/CD story instead of hand-waving over data safety.

**Open questions / to design:**
- Which tool drives the compare — SqlPackage `/Action:DeployReport` (diff without
  applying), or a dedicated schema-compare step? Needs to work against a Fabric SQL
  database item specifically.
- Whether "apply manually" means a pipeline **approval gate** (environment protection
  rule) before the same automated publish runs, or a genuinely manual/out-of-band step.
- Seed data for Test needs a populated column to make the loss visible/demonstrable.
