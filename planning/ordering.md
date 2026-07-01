# Ordering — services, labs, assets, prerequisites

Track everything that must be arranged **before** the event. Tick items as confirmed.

## Cloud / subscriptions
- [ ] Azure subscription(s) for demos — with quota for Azure SQL in the demo region.
- [ ] Microsoft Fabric capacity / trial for Fabric SQL demos.
- [ ] Attendee sandbox strategy — do attendees use their own subscription, a shared one,
      or a lab provider? **Decide early — it gates the prerequisites we publish.**
- [ ] Cost estimate + spending caps / auto-teardown for demo resources.

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
