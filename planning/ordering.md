# Ordering — services, labs, assets, prerequisites

Track everything that must be arranged **before** the event. Tick items as confirmed.

## Cloud / subscriptions
- [ ] Azure subscription(s) for demos — with quota for Azure SQL in the demo region.
- [ ] Microsoft Fabric capacity / trial for Fabric SQL demos.
- [x] **Attendee sandbox strategy — DECIDED (D6, 2026-07-18): bring-your-own.** Attendees use
      whatever they already have. Two independent lab parts: **IaC** needs their own Azure sub;
      **DB deploy** needs a target SQL. We provide **one shared SQL endpoint on the day,
      explicitly unsupported.** See [`../notes/decisions.md`](../notes/decisions.md) **D6**.
- [ ] **The shared unsupported endpoint** — a **SQL Server on a VM** attendees push to via
      pipeline (per-attendee database on one instance). Provision + teardown = **task #19**.
- [ ] Cost estimate + spending caps / auto-teardown for **our** demo resources.

## Attendee prerequisites (from D6 — feeds the `docs/` prereqs page, task #2)
- [ ] **Everyone:** GitHub account; ability to fork/clone the template repo; a local toolchain
      (git, and for the DB part SqlPackage/`dotnet` — confirm the minimal set).
- [ ] **To do the IaC part (optional):** own **Azure subscription** with Contributor rights to
      create resources. **Fabric path also needs a Fabric capacity** — creating an F-SKU bills
      real money and a trial capacity can't be Terraform-created, so the prereq/cost story here
      needs nailing (open Q on task #1).
- [ ] **To do the DB-deploy part (optional):** a reachable **target SQL** (their own Azure SQL
      or Fabric SQL), **or** use our shared unsupported endpoint on the day.
- [ ] Cost + **teardown** guidance for attendees who deploy into their own subscription.

## Lab environment
- [ ] Confirm what attendees need locally vs. in-cloud (see attendee prerequisites in `docs/`).
- [ ] Fallback for attendees who can't provision cloud resources (read-only walkthrough?).
- [ ] GitHub org/repo access for attendees (template repo to fork/clone).

## Assets
- [ ] Slides / intro deck.
- [ ] Canonical sample database (football-themed candidate — see Ideas).
- [ ] Downloadable code bundles per module (produced by pipeline).
- [ ] Printed or on-screen quick-reference (commands cheat sheet).

## Event logistics
- [ ] Room A/V, power, and reliable WiFi confirmation (bandwidth for cloud provisioning!).
- [ ] Timings confirmed with organisers (start/end, breaks, lunch).
- [ ] Attendee count / cap.

> Anything discovered while ordering (a quota limit, a Fabric trial gotcha) → log it in
> [`../notes/LEARNINGS.md`](../notes/LEARNINGS.md).
