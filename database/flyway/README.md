# Flyway (reference / bonus)

Migration-based versioned SQL scripts (`V1__*.sql`, `V2__*.sql`, ...) building the same
canonical schema as the SQL project. Reference path for attendees who prefer migrations.
Keep the resulting schema identical to [`../sql-projects/`](../sql-projects/).

## What Flyway is

Flyway is **migration-based**. Rather than declaring the schema you want and letting a tool work
out the difference — the *state-based* model the SQL project uses — you write an ordered set of
small scripts, and Flyway applies each one exactly once, recording what it has run in a
`flyway_schema_history` table.

- **Versioned migrations** — `V1__create_clubs.sql`, `V2__add_players.sql`, … applied once, in order.
- **Repeatable migrations** — `R__*.sql` (views, procedures) re-run whenever their contents change.
- Runs from the **command line**, a container, or a build plugin, so it drops into the same kind of
  pipeline we build for the SQL project.

Same destination as the taught path, a different route to it: whichever you use, the schema must
match [`../sql-projects/`](../sql-projects/) exactly.

## Learn more

- **Flyway** — [product home](https://www.red-gate.com/products/flyway/) · [documentation](https://documentation.red-gate.com/flyway)
- **Source** — [github.com/flyway/flyway](https://github.com/flyway/flyway)
