# Morning-of readiness checklist — workshop day, Barcelona

What Jess & Rob run through **before doors open** to be demo-ready. Grounded in the
operational realities logged in [`../notes/LEARNINGS.md`](../notes/LEARNINGS.md) — the demo
infra is torn down nightly and the Fabric capacity auto-pauses, so the environment is **not**
standing when you walk in. Work top to bottom; the cloud steps have wait times, so start them
first and let them run while you set up the room.

> Related: run-of-day in [`../agenda/agenda.md`](../agenda/agenda.md) · task status in
> [`tasks.md`](tasks.md) · attendee prereqs in [`../docs/setup/prerequisites.md`](../docs/setup/prerequisites.md).
> Anything that surprises you on the day → log it in [`../notes/LEARNINGS.md`](../notes/LEARNINGS.md).

---

## 1 · Bring the demo environment back up
*(The nightly destroy runs at 21:00 UTC, so infra is gone each morning. Deploy workflows only
authenticate from `main` — OIDC federated credentials don't trust branches.)*

- [ ] `az login` to **both tenants** — Tenant A (Terraform state + Azure SQL) **and** Tenant B
      (Fabric). The Fabric path is cross-tenant; forgetting Tenant B is the classic morning trap.
- [ ] **Resume the Fabric capacity** (`cappymccapface`, `fabcon-demo-rg`, Tenant B) and wait for
      state `Active`. It auto-pauses every 2h, and both `data.fabric_capacity` **and** the SQL DB
      are unreachable while it's suspended.
- [ ] Dispatch **`azure-sql-apply`** from `main` → confirm `apply` + DACPAC `publish` + smoke test
      all green.
- [ ] Dispatch **`fabric-sql-apply`** from `main` → confirm workspace + SQL DB recreated, publish +
      smoke green, and the **workspace-admin grant re-applied** (the workspace is recreated on every
      apply, so Jess/Rob's visibility depends on the as-code `fabric_workspace_role_assignment`).
- [ ] Sanity-check both smoke tests actually returned rows (not just "workflow succeeded").

## 2 · Pipelines & attendee site
- [ ] CI green on `main`; GitHub Pages site deployed and reachable.
- [ ] **Reveal the full site if going public today** — one PR: drop the `exclude_docs` block and
      un-comment the `nav` in [`../mkdocs.yml`](../mkdocs.yml). Do this **early**, not live — never
      the first time in front of the room.
- [ ] Publish / verify **checkpoint states** so anyone following along on their own kit (or just
      watching) can catch up at each "we move on" line.

## 3 · Presenter machines
- [ ] Toolchain sanity on **both** laptops: `terraform`, `sqlpackage` / `dotnet` (the repo pins
      .NET 8 via [`../global.json`](../global.json)), `mkdocs`, `gh auth status`, `az`.
- [ ] Rebuild the slide deck — it's gitignored, so regenerate it, don't assume it's there:

      ```powershell
      python slides/build.py
      ```

      Then eyeball it against the FabCon speaker template.
- [ ] For any demo that hits a DB **from a laptop** (not a GitHub-hosted runner), add a temporary
      firewall rule for the room's egress IP — external clients are blocked even with a valid Entra
      token, because only the "allow Azure services" rule is open:

      ```powershell
      az sql server firewall-rule create `
        --resource-group rg-fabcon26-dev-uks `
        --server <server-name> `
        --name room-temp `
        --start-ip-address <room-ip> --end-ip-address <room-ip>
      ```

      Remove it after the session.

## 4 · Room & attendees
- [ ] WiFi bandwidth confirmed (cloud provisioning is bandwidth-hungry), A/V, and power all working.
- [ ] Template repo forkable/clonable; prerequisites page live; commands cheat-sheet to hand.
- [ ] Shared **unsupported** SQL endpoint (task #19) up **if built** — otherwise be explicit up
      front that the DB-deploy follow-along needs the attendee's own target SQL.

## 5 · Fallbacks ready
- [ ] "Just watch" path rehearsed for anyone who can't provision — bring-your-own (D6) means some
      won't.
- [ ] Backup/stretch material staged (Bicep, Azure DevOps, Flyway/dbops) in case a section runs
      short — and the "take SQL-projects time back from the 16:15 block" contingency from the dry-run
      note (#13) kept in mind if the squeezed module overruns.

---

**One-line go/no-go before 09:00:** both `*-apply` runs green with smoke tests returning rows,
Fabric capacity `Active`, site in its intended state, both laptops `az login`'d to both tenants.
