# Morning-of readiness checklist — workshop day, Barcelona

What Jess & Rob run through **before doos open** to be demo-ready. Grounded in the
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
authenticate from `main` — OIDC federated credentials don't trust branches. `fabric-sql-apply`
resumes the paused Fabric capacity itself, so there is nothing to resume by hand.)*

- [ ] `az login` to **both tenants** — Tenant A (Terraform state + Azure SQL) **and** Tenant B
      (Fabric). The Fabric path is cross-tenant; forgetting Tenant B is the classic morning trap.
- [ ] **Refresh the presenter IP secrets _before_ you dispatch apply.** The firewall rules that let
      Jess & Rob's laptops reach the Azure SQL server are built as code by Terraform from the
      `ROB_CLIENT_IP` / `JESS_CLIENT_IP` GitHub **secrets** (fed into `presenter_client_ips` by
      [`azure-sql-apply.yml`](../.github/workflows/azure-sql-apply.yml)). They were last set from
      home, so on the day in Barcelona they're stale — and secret **values can't be read back**, so
      don't try to "check" them, just re-set them to today's egress IP. Apply won't re-open the
      firewall if you fix them afterwards, so this comes first.
      ```powershell
      # your current public egress IP (run on each laptop, on the venue WiFi)
      Invoke-RestMethod https://api.ipify.org

      # push it — Rob on his laptop, Jess on hers
      gh secret set ROB_CLIENT_IP  --body "<rob-ip>"
      gh secret set JESS_CLIENT_IP --body "<jess-ip>"

      # confirm both exist (shows names + last-updated, not values)
      gh secret list
      ```

- [ ] Dispatch **`azure-sql-apply`** from `main` and watch it green — `apply` + DACPAC `publish` +
      smoke test.

      ```powershell
      gh workflow run azure-sql-apply.yml --ref main -f target=both
      ```

- [ ] Dispatch **`fabric-sql-apply`** from `main` and watch it green — it resumes the capacity,
      recreates the workspace + SQL DB, publishes, smoke-tests, and re-applies the
      **workspace-admin grant** (the workspace is recreated on every apply, so Jess/Rob's visibility
      depends on the as-code `fabric_workspace_role_assignment`):

      ```powershell
      gh workflow run fabric-sql-apply.yml --ref main
      ```
- [ ] **Disable the every-2h Fabric auto-pause** so the capacity stays `Active` all day instead of
      pausing mid-demo (re-enable it after the event). Target the Fabric subscription (Tenant B):

      ```powershell
      az automation schedule update --resource-group rg-fabcon26-automation-uks `
        --automation-account-name aa-fabcon26-dev-uks --name pause-every-2h --is-enabled false
      ```
- [ ] Sanity-check both smoke tests actually returned rows (not just "workflow succeeded").

      ```powershell
      gh run list  --limit 2
      ```
- [ ] **Confirm the databases exist and are reachable** — the demo Azure SQL DB, all ten attendee
      DBs, and the Fabric capacity:

      ```powershell
      # demo Azure SQL database (Tenant A)
      $demoServer = az sql server list -g rg-fabcon26-dev-uks --query "[0].name" -o tsv
      az sql db list -g rg-fabcon26-dev-uks --server $demoServer `
        --query "[?name!='master'].{db:name, status:status}" -o table

      # attendee databases — expect sqldb-attendee01 .. attendee10 (Tenant A)
      $attServer = az sql server list -g rg-fabcon26-shared-uks --query "[0].name" -o tsv
      az sql db list -g rg-fabcon26-shared-uks --server $attServer `
        --query "[?starts_with(name,'sqldb-attendee')].{db:name, status:status}" -o table

      # Fabric capacity is alive (Tenant B — select that subscription first)
      az resource show -g fabcon-demo-rg -n cappymccapface `
        --resource-type Microsoft.Fabric/capacities --query "properties.state" -o tsv
      ```

      You see the demo database, ten `sqldb-attendee*` rows, and Fabric state `Active`. Azure SQL
      rows read `Online`; a serverless database may read `Paused` until the first query wakes it,
      which is fine.

## 2 · Pipelines & attendee site
- [ ] CI green on `main`; GitHub Pages site deployed and reachable.
- [ ] **Reveal the full site (if going public today) — pre-stage the PR, merge it on the morning.**
      The reveal is one change to [`../mkdocs.yml`](../mkdocs.yml): drop the `exclude_docs` block and
      un-comment the full `nav` (it mirrors [`../mkdocs.local.yml`](../mkdocs.local.yml)). Prepare it
      on a branch **days before** — never edit `mkdocs.yml` live in front of the room — and open the
      PR ahead of time so CI has already proven it green:

      ```powershell
      # days before: on a reveal branch with the mkdocs.yml edit committed and pushed
      gh pr create --base main --head reveal-site `
        --title "Reveal the full workshop site" `
        --body "Drop exclude_docs and un-comment the full nav in mkdocs.yml."
      ```

      On the morning, once you have decided to go public, merge it:

      ```powershell
      gh pr merge reveal-site --squash --delete-branch
      ```

      The push to `main` triggers [`pages.yml`](../.github/workflows/pages.yml); confirm that deploy
      is green and the live site shows every page.
- [ ] Publish / verify **checkpoint states** so anyone following along on their own kit (or just
      watching) can catch up at each "we move on" line.

## 3 · Presenter machines
- [ ] **Reset the demo repo and confirm it's ready on _both_ laptops** — a previous run's throwaway
      branch or scratch file (including gitignored `tfvars`/`*_override.tf` a clean `git status` hides)
      will break a re-run. On a clean `main`:

      ```powershell
      ./demo/Reset-DemoEnvironment.ps1                 # add -SkipRemote if offline
      Invoke-Pester ./tests/DemoEnvironment.Tests.ps1  # git state, tooling, sign-in
      ```

      The Pester run is the toolchain sanity check: it asserts `git`, `gh`, `az`, `terraform`,
      `dotnet`, `sqlpackage`, `code`, `pwsh` and the `dbatools` module are present, the `.NET` SDK
      matches [`../global.json`](../global.json), and `gh`/`az` are signed in. All green means the
      environment is demo-ready. See [`../demo/README.md`](../demo/README.md) § Reset.
- [ ] **Open the slide deck** on the presenting laptop, ready to go.

## 4 · Room & attendees
- [ ] WiFi bandwidth confirmed (cloud provisioning is bandwidth-hungry), A/V, and power all working.
- [ ] Template repo forkable/clonable; prerequisites page live; commands cheat-sheet to hand.
- [ ] Shared **unsupported** SQL endpoint (task #19) up **if built** — otherwise be explicit up
      front that the DB-deploy follow-along needs the attendee's own target SQL.
- [ ] **Confirm Cláudio (moderator) can connect to the shared endpoint** — his laptop's egress IP
      is allowed and a test connection returns rows, so he can follow the DB-deploy demo from the
      front row rather than discovering he's firewalled off mid-session.

## 5 · Fallbacks ready
- [ ] "Just watch" path rehearsed for anyone who can't provision — bring-your-own (D6) means some
      won't.
- [ ] Backup/stretch material staged (Bicep, Azure DevOps, Flyway/dbops) in case a section runs
      short — and the "take SQL-projects time back from the 16:15 block" contingency from the dry-run
      note (#13) kept in mind if the squeezed module overruns.

---

**One-line go/no-go before 09:00:** both `*-apply` runs green with smoke tests returning rows,
Fabric capacity `Active`, site in its intended state, both laptops `az login`'d to both tenants.
