# The hardest part of IT

--8<-- "includes/clock-morning-1.md"

We are going to spend today deploying infrastructure and databases as code, and by the end of it
you will have a pipeline that provisions a SQL Server and ships a schema change without anyone
touching a portal. That is the easy half of the day.

This first part is about the other half.

## Why this goes first

Every technical idea in this workshop is, underneath, a decision about people.

Branching is a decision about who is allowed to work on what. Pull request review is a decision
about whose judgement you trust, and how much. An approval gate is a decision about who
carries the can when a deployment goes wrong at 16:55 on a Friday. And the question of who is
allowed to drop a column is not a question about `sqlpackage` at all — it is a question about your
organisation, wearing a YAML costume.

You can adopt every tool we show you today and still fail, because the tools were never the
constraint. So we would rather say that out loud at 09:00 than let you discover it in March.

!!! quote "The bit the tooling does not cover"
    We can show you the tech. Most of you could get an AI to write the Terraform, if we are honest
    about it. What no assistant knows is your organisation: the history, the egos, the person who
    still has production `sa` in a password manager they will not share. That part is on us, and
    it is the part we have learnt the hard way.

## What we will actually talk about

No commands in this section, and nothing to install. This is a conversation, and we would much
rather it were one — so please do interrupt.

- **The war stories.** Ours, mostly, and the scar tissue they left behind. Some of them are funny
  now. They were not at the time.
- **Why "just put it in source control" is never just.** The technical migration is a weekend.
  The cultural one takes considerably longer, and nobody puts that on the project plan.
- **Consent and the shared database.** The developer who wants to move fast and the DBA who has
  been paged at 03:00 are both behaving completely rationally. They are simply optimising for
  different things, and neither of them is the villain.
- **How to bring this back to a team that did not come to Barcelona.** The colleague who is happy
  with their current process is not being obstructive. They are telling you the change has a cost,
  and they are right.

## The one thing to take away

If you remember nothing else from this section: **the goal is not to remove people from the
process. It is to make the process visible to them.**

Everything after this — the branch, the pull request, the plan that tells you what will happen
before it happens, the gate that makes someone say yes — exists so that a change can be *seen* and
*discussed* rather than discovered afterwards in an audit log. The automation is not there to take
the decision away from your colleagues. It is there to give them something concrete to have the
argument about, before the change reaches production rather than after.

Which is a good moment to talk about where all of it lives.

## What's next

Next: [Source control for databases](source-control.md) — one repository as the single source of
truth, and the pull request flow the rest of the day rides on.
