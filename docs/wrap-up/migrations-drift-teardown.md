# Migrations, drift & teardown

The last section of the day pulls every piece together and runs the whole loop once, end to end:
edit Azure SQL infrastructure as code, raise a pull request, read the plan, merge, apply from
`main` — and then tear it down.

!!! tip "The hands-on part is on the demo page"
    This page is the *why*. The full loop is walked through step by step on
    **[Wrap-up demo](demo.md)**.

## The concept

- **Pull request first.** Terraform plan on the PR shows what will change before you merge.
- **Apply on intent.** Real deployment is a manual dispatch from `main`.
- **Drift awareness.** You trust code + state, then confirm the runtime result.
- **Teardown always.** Sandbox resources are disposable.

### Drift, and why the loop closes

**Drift** is the gap that opens when someone changes a deployed resource by hand. The code says one
thing, the running resource says another, and nobody finds out until the next apply quietly reverts
somebody's fix. The whole day's discipline exists to keep that gap at zero: if the only route to a
change is a pull request, then the code and the resource cannot disagree for long.

That is why the final demo ends by confirming the change in **both** places — in git, and in the
running database. Trusting the code alone is how drift hides.

### State-based and migration-based

The taught path is **state-based**: a SQL project describes the schema you want, and SqlPackage
works out the change. The alternative is **migration-based**: you write each change as an ordered
script, and the tool replays the ones a database has not run yet.

Neither is wrong. State-based gives you one readable description of the whole schema; migration-based
gives you exact control over how each change is applied, which matters when a change needs to move
data as well as shape. Both are in the repository, and the safe-retire increment in the
[Database demo](../database/demo.md) is really a migration wearing a state-based coat.

- [Flyway](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/flyway)
- [dbatools / dbops](https://github.com/JessAndRob/FabConEU_2026_workshop/tree/main/database/dbatools-dbops)

### Teardown

Workshop resources that survive the workshop become a bill. Teardown is a workflow dispatch, the
same as the deploy — `azure-sql-destroy.yml` removes everything the apply created. A nightly
scheduled run is the backstop at 21:00 UTC, but do not rely on it while you are still working:
tear down deliberately when you finish. On Fabric especially, an F-SKU capacity bills continuously
until it is paused or deleted.

## The demo

👉 **[Wrap-up demo](demo.md)** — change one Terraform variable, open the pull request, read the
plan, merge, dispatch the apply, confirm the result in code *and* in the database, then run the
teardown.

## What's next

Next: [Wrap-up demo](demo.md), then [Resources & next steps](resources.md).
