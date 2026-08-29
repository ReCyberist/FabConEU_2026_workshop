# Deck content for the FabCon Europe 2026 workshop.
# Kinds: SECTION (title + strapline) | CONTENT (title + bullets) | DUAL (title + two columns)
#        DARK (dual, dark background) | CMD (title + monospace command block)

SECTION, CONTENT, DUAL, DARK, CMD, QUOTE = "SECTION", "CONTENT", "DUAL", "DARK", "CMD", "QUOTE"

DECK = [

# ─────────────────────────────── OPENING ───────────────────────────────
(CONTENT, "Two presenters, one opinionated path", [
    "Jess Pomfret — Microsoft MVP, Data Platform Architect",
    "Rob Sewell — Microsoft MVP, dbatools and dbachecks maintainer",
    "Between us: a lot of production databases, and a lot of scar tissue",
    "Today is the day we hand over both the code and the scars",
], "Keep this short — 90 seconds. The room came for the tech, not our CVs. The scar-tissue line sets up the 09:30 module."),

(DUAL, "What today is, and what it isn't", [
    "IT IS",
    "Infrastructure and databases deployed as code, start to finish",
    "Real pipelines that provision and ship, not screenshots of them",
    "Azure SQL and Fabric SQL, side by side, all day",
    "Every step runnable later, on your own kit",
], [
    "IT ISN'T",
    "A managed lab — nothing is provisioned for you",
    "A tool bake-off — we lead with one path and show you the rest",
    "A click-through of the portal",
    "A day of us talking at you",
], "The 'no clicking required' promise lands here. Say it out loud — you'll be held to it all day, deliberately."),

(CONTENT, "What you'll leave with", [
    "A repo you can fork that provisions Azure SQL and Fabric SQL from scratch",
    "A pipeline that plans on a PR and applies on purpose",
    "A database schema that ships through that pipeline, safely",
    "The judgement to know when NOT to let the pipeline apply it",
    "A site full of the written steps, so today doesn't evaporate by Friday",
], "The fourth bullet is the one that matters and the one nobody else teaches. Flag it now, pay it off at 15:30."),

(DUAL, "The run of the day", [
    "MORNING",
    "09:00  Welcome, and why any of this",
    "09:20  Environment check",
    "09:30  The hardest part of IT",
    "10:00  Source control foundations",
    "10:30  Infra as code — Azure SQL",
    "11:30  Infra as code — Fabric SQL",
    "12:15  Database as code — SQL projects",
], [
    "AFTERNOON",
    "13:45  CI/CD 1 — build and validate",
    "14:30  CI/CD 2 — deploy infrastructure",
    "15:30  CI/CD 3 — ship database changes",
    "16:15  Migrations, drift and teardown",
    "16:45  Wrap-up, resources, questions",
    "",
    "Breaks at 11:00 and 15:15. Lunch at 12:45.",
], "Point at 09:30. Yes, that's a talk about feelings, and yes, it's before the Terraform. Explain why in one sentence and move on."),

(DUAL, "Housekeeping: it's bring-your-own", [
    "PART 1 — INFRASTRUCTURE",
    "Needs your own Azure subscription with rights to create resources",
    "For the Fabric path, a Fabric capacity — it bills, so we pause and destroy",
    "No subscription? Watch this part, replay it later — everything is published",
], [
    "PART 2 — DATABASE DEPLOYMENT",
    "Needs any SQL target you can reach — Azure SQL or Fabric SQL",
    "The two parts are independent — you can do part 2 without part 1",
    "We have one shared endpoint as a best-effort target. It is UNSUPPORTED.",
], "Be blunt about 'unsupported' — it means we will not troubleshoot it during the day. Nobody should be surprised at 15:30."),

# ─────────────────────── 09:00 WHY ───────────────────────
(SECTION, "Why infrastructure as code for data",
    "09:00  ·  Setting the promise: no clicking required", None,
    "Twenty minutes. The goal is agreement on the problem, not on the tooling."),

(DUAL, "The way most data platforms actually get built", [
    "HOW IT STARTS",
    "Someone clicks a server into existence for a proof of concept",
    "The proof of concept goes to production, as they always do",
    "A firewall rule gets added by hand, at 6pm, by whoever is around",
    "The schema drifts because prod is the only place it's real",
], [
    "HOW IT ENDS",
    "Nobody can rebuild it, so nobody dares touch it",
    "The person who knows why it's like that has left",
    "Every change is a change-request and a Friday night",
    "\"I'll do it manually\" — four of the most expensive words in IT",
], "Ask for a show of hands on the firewall rule. You will get one. That's the whole justification for the day."),

(CONTENT, "What 'as code' actually buys you", [
    "Repeatable — the same input produces the same environment, every time",
    "Reviewable — a change is a diff a human can argue with before it happens",
    "Recoverable — the environment is a git clone away, not a support ticket",
    "Auditable — who changed what, when, and who agreed to it",
    "Disposable — and that is the underrated one. You can destroy it fearlessly.",
], "'Disposable' is worth dwelling on — fear of teardown is what keeps zombie environments alive and billing."),

(DUAL, "All of it as code. One path in the teaching.", [
    "WHAT WE TEACH TODAY",
    "Terraform for infrastructure",
    "GitHub Actions for CI/CD",
    "SQL projects (.sqlproj / DACPAC) for schema",
    "One opinionated path, followed end to end",
], [
    "WHAT'S ALSO IN THE REPO",
    "Bicep, mirroring every Terraform module",
    "Azure DevOps pipelines, mirroring every workflow",
    "Flyway and dbatools/dbops for migration-based schema",
    "Working code, not hand-waving — go read it on the train home",
], "Head off the 'but we use Bicep/ADO' question early. Answer: it's in the repo, tested, and we'll show it if we're ahead of time."),

# ─────────────────────── 09:20 ENVIRONMENT ───────────────────────
(SECTION, "Environment check",
    "09:20  ·  Ten minutes — then we move on", None,
    "Deliberately short. Anyone still broken gets helped at the 11:00 break, not now. Say that kindly but clearly."),

(CMD, "Check your toolchain", [
    "# Everything today is PowerShell on Windows.",
    "# If any of these fail, you can still follow along — just watch.",
    "",
    "git --version",
    "az --version",
    "terraform --version",
    "dotnet --version",
    "sqlpackage /version",
    "",
    "az login",
    "az account show --query name -o tsv",
], "Have the prerequisites page open on the second screen. Don't debug individuals from the front — point them at the page."),

# ─────────────────────── 09:30 THE HARDEST PART ───────────────────────
(SECTION, "First up: the hardest part of IT",
    "09:30  ·  It isn't the YAML", None,
    "Thirty minutes, no demo to hide behind. Watch the clock — this is the easiest module in the day to overrun."),

(QUOTE, "Here's the bits Copilot doesn't know", [
    "We can show you the tech part.",
    "Hell, most of you will probably Copilot it anyway.",
    "But here's the bits Copilot doesn't know —",
    "it's the blood balloons with egos… and feelings.",
    "This is what we have learnt.",
], "This is the slide. Let it sit. Don't read it word for word — say it in your own voice, then pause before the next slide."),

(DARK, "The honest split", [
    "WHAT THE MACHINE WILL DO FOR YOU",
    "Write the Terraform module",
    "Write the pipeline YAML",
    "Explain the error message",
    "Generate the schema, the tests, the docs",
    "Do it again tomorrow, faster",
], [
    "WHAT IT WILL NOT DO FOR YOU",
    "Tell the DBA their manual process is the bottleneck",
    "Convince a team that review isn't an insult",
    "Decide who is allowed to drop a column",
    "Absorb the blame when it goes wrong at 2am",
    "Rebuild trust after it did",
], "The right-hand column is the entire reason this module exists. None of it is a tooling problem."),

(CONTENT, "Lesson 1 — It was never about the tool", [
    "Nobody resists Terraform. They resist losing control.",
    "The objection is never really \"this tool is wrong\"",
    "It's \"this tool takes away the part of the job I'm valued for\"",
    "The person guarding the manual process is usually the person who got burned",
    "Automating their job away is a threat. Automating their 2am is a gift.",
    "Same change. Completely different conversation.",
], "Rob / Jess — put your own story here. The specific one beats the general point every time."),

(CONTENT, "Lesson 2 — \"Databases are different\"", [
    "It's a feeling — with a grain of truth in it",
    "The grain of truth: databases hold state, and state can't be rolled back by redeploying",
    "The feeling: therefore nothing about them can be automated",
    "The first is a real engineering constraint — we design around it all afternoon",
    "The second is how teams end up with a spreadsheet of scripts and a change window",
    "Take the constraint seriously and the fear loses its cover story",
], "This is the bridge to the whole afternoon — state-based deploys, data-loss gates, the DeployReport. Name that now."),

(CONTENT, "Lesson 3 — Review is where egos go to die, or grow", [
    "A pull request is a person saying \"check my work\" in public",
    "That is emotionally expensive, and we mostly pretend it isn't",
    "Comment on the change, never the changer — \"this drops a populated column\", not \"you nearly deleted prod\"",
    "Approve fast. A PR sat for three days teaches people not to open one.",
    "The team that reviews kindly is the team that reviews at all",
], "If you only get one lesson across today, this is a strong candidate. It's also the one that makes 15:30 work."),

(CONTENT, "Lesson 4 — Blame is a deployment risk", [
    "In a blaming team, the safest move is to change nothing",
    "So changes get batched, and batched changes are the dangerous kind",
    "The outage postmortem that names a person teaches everyone to hide",
    "The one that names a missing guardrail gets you the guardrail",
    "Psychological safety isn't a poster. It's a deployment frequency metric.",
], "Link forward: the approval gate we build at 15:30 exists so no individual has to be the last line of defence."),

(CONTENT, "Lesson 5 — Start where the pain is", [
    "Don't open with \"we're going to transform the whole estate\"",
    "Open with the thing that ruined someone's weekend last month",
    "Automate that one thing, in public, and let it be boringly reliable",
    "Credibility is spent, not granted — and the first win is what buys it",
    "The architecture diagram can wait. It always waits.",
], "Good place to invite the room in: what ruined YOUR weekend? Two or three answers, no more, then move."),

(DUAL, "So — why the rest of today looks like it does", [
    "EVERY TECHNICAL CHOICE TODAY",
    "Plan on a PR, so change is visible before it's real",
    "Apply on purpose, so nothing surprises anyone",
    "A deploy report before every publish, so nobody guesses",
    "An approval gate on destructive change, so it's a decision",
], [
    "IS ALSO A PEOPLE CHOICE",
    "Makes the change reviewable without a meeting",
    "Removes \"who ran that?\" from the postmortem",
    "Turns \"trust me\" into evidence",
    "Shares the weight of the scary ones",
], "Land the module here. Everything after this is the tooling that makes the human stuff possible. Then break the tension and get into git."),

# ─────────────────────── 10:00 SOURCE CONTROL ───────────────────────
(SECTION, "Source control foundations for databases",
    "10:00  ·  Where the team agreements become commands", None,
    "Thirty minutes. Keep it moving — most of the room knows git, few have put a database in it."),

(DUAL, "Why databases arrived late to source control", [
    "THE HONEST REASONS",
    "The database was the deployed artefact AND the source of truth",
    "Tooling assumed a live connection, not a file on disk",
    "Data and schema live in the same object, and only one of them is code",
    "Everyone had a folder of numbered .sql files that mostly worked",
], [
    "WHAT CHANGED",
    "The schema can be a project that builds, like any other code",
    "The build produces an artefact — a DACPAC — you can version and ship",
    "Deployment became a comparison, not a hopeful script",
    "Which means a database change can finally be a diff",
], "The 'folder of numbered scripts' line usually gets a laugh of recognition. Use it."),

(CONTENT, "How this repo is laid out", [
    "infra/ — Terraform and Bicep, per platform, per module",
    "database/ — the SQL project, plus the migration-based alternatives",
    ".github/workflows/ — CI, plan, apply, destroy",
    "docs/ — the written steps you're following, published as a site",
    "One rule: if an instruction says \"click\", it's a bug",
], "Show the actual repo here rather than reading the slide. The last line is the workshop's thesis in eight words."),

(CONTENT, "What never goes in the repo", [
    "Connection strings, passwords, subscription IDs, tenant IDs",
    "Terraform state — it contains everything you just promised not to commit",
    "*.tfvars — the example file is committed, your real one is not",
    "The answer isn't a better .gitignore. It's not having the secret at all.",
    "Passwordless everywhere today: Entra auth locally, OIDC from the pipeline",
], "This sets up the OIDC story at 13:45. 'Not having the secret at all' is the punchline — say it, then prove it this afternoon."),

(CMD, "Getting started", [
    "# Fork it, clone it, branch it. Same as any other code.",
    "",
    "git clone https://github.com/JessAndRob/FabConEU_2026_workshop.git",
    "cd FabConEU_2026_workshop",
    "",
    "git switch -c my-first-change",
    "git add .",
    "git commit -m 'Add a view'",
    "git push -u origin my-first-change",
    "",
    "# Then open a pull request — and watch CI have an opinion.",
], "The last comment is the hook into the afternoon. CI having an opinion is the point of the whole pipeline."),

# ─────────────────────── 10:30 AZURE SQL ───────────────────────
(SECTION, "Provisioning infrastructure as code — Azure SQL",
    "10:30  ·  Terraform, and the first real apply", None,
    "Thirty minutes before the break, fifteen after. Aim to have apply running as people stand up."),

(CONTENT, "What we're about to provision", [
    "A resource group, named to CAF conventions and prefixed fabcon26-",
    "A logical SQL server, with Entra-only authentication — no SQL logins at all",
    "A serverless database, so it costs pennies while it's idle",
    "A firewall rule, declared in code rather than added in a panic",
    "All of it destroyable in one command, which is the point",
], "Emphasise Entra-only: there is no admin password anywhere in this workshop, by design."),

(CONTENT, "Terraform in ninety seconds", [
    "init — download the providers, wire up the backend",
    "plan — what WOULD change, printed before anything does",
    "apply — do it, and record what you did in state",
    "destroy — undo it, completely and on purpose",
    "State is the memory. Lose it and Terraform forgets what it owns.",
], "plan/apply is the same shape as the DeployReport/publish pair we use for the database this afternoon. Plant that now."),

(CMD, "Run it on your own kit", [
    "cd infra/azure-sql/terraform/demo",
    "",
    "Copy-Item terraform.tfvars.example terraform.tfvars",
    "# fill in the Entra admin identity",
    "",
    "$env:ARM_SUBSCRIPTION_ID = '<your-subscription-id>'",
    "",
    "terraform init -backend=false",
    "terraform plan",
    "terraform apply",
], "-backend=false is what lets attendees run locally without our state account. Call that out or someone will copy the CI config."),

(DUAL, "State: the bit that bites in CI", [
    "LOCAL STATE",
    "A file on your laptop, fine for a one-shot lab",
    "Not shared, not locked, not backed up",
    "A GitHub runner is destroyed after every job",
    "So the plan job and the apply job would have no shared memory at all",
], [
    "REMOTE STATE — WHAT WE RUN",
    "Azure Storage, versioned and soft-delete enabled",
    "Entra auth to the blob — no storage account keys",
    "Its own resource group, so nightly destroy can never eat it",
    "One state file per module, per environment",
], "This is decision D5. The 'its own resource group' detail is a genuine scar — the nightly destroy would otherwise delete the state store."),

(CONTENT, "Off it goes — see you after coffee", [
    "terraform apply is running now",
    "It provisions while we're at the break, which is the only good use of a spinner",
    "Following along? Start yours before you stand up",
    "Watching? Nothing to do — you'll see the result at 11:15",
    "Back at 11:15",
], "Genuinely start the apply here. If it's finished before the break, you've mistimed the module."),

(SECTION, "Break",
    "11:00  ·  Fifteen minutes  ·  Your apply is running", None,
    "Use the break for individual environment problems. Be back on stage two minutes early."),

(CONTENT, "So what did we just build?", [
    "terraform output — the server name, the database, what to connect to",
    "The portal, once, purely to prove the code did what it said",
    "terraform plan again — no changes, because reality matches the code",
    "Now change something in the portal and re-plan. That's drift.",
    "The code is the source of truth. The portal is just a view of it.",
], "The deliberate drift demo is worth the ninety seconds — it's the moment 'as code' stops being abstract."),

# ─────────────────────── 11:30 FABRIC SQL ───────────────────────
(SECTION, "Provisioning infrastructure as code — Fabric SQL",
    "11:30  ·  The same idea, a younger platform", None,
    "Forty-five minutes. Be honest about the rough edges — the room will respect it and they'll hit them anyway."),

(DARK, "Azure SQL and Fabric SQL, side by side", [
    "AZURE SQL",
    "Resource group → logical server → database",
    "Fully modelled in ARM, so Terraform and Bicep both work",
    "Serverless billing, pauses when idle",
    "Mature provider, predictable behaviour",
], [
    "FABRIC SQL",
    "Resource group → capacity → workspace → SQL database",
    "The capacity is ARM. The workspace and database are not.",
    "An F-SKU capacity bills while it runs, idle or not",
    "Young provider, moving fast — pin your versions",
], "The ARM/not-ARM split is the single most useful thing on this slide. It's why the Bicep path stops at the capacity."),

(CONTENT, "What's genuinely different in the Fabric path", [
    "Bicep can create the capacity — and then it runs out of road",
    "The workspace and the SQL database have no ARM resource type",
    "So the Fabric path is Terraform (or the Fabric REST API), not Bicep",
    "Service principals need a tenant setting switched on before they can do anything",
    "And a workspace role — being subscription Owner buys you nothing here",
], "Both of the last two cost us real time. Tell them the error message so they recognise it when it bites."),

(CMD, "The Fabric module", [
    "cd infra/fabric-sql/terraform",
    "",
    "Copy-Item terraform.tfvars.example terraform.tfvars",
    "az login",
    "$env:ARM_SUBSCRIPTION_ID = '<your-subscription-id>'",
    "# optional: $env:FABRIC_TENANT_ID = '<your-tenant-id>'",
    "",
    "terraform init",
    "terraform plan",
    "terraform apply",
], "Same three commands as Azure SQL. That symmetry is the reassuring part — say it."),

(CONTENT, "A word about the bill", [
    "A Fabric capacity bills while it exists, whether you're using it or not",
    "F2 is the smallest SKU. It is not free.",
    "Terraform manages whether the capacity exists — not whether it's paused",
    "We run scheduled automation to pause it, and a nightly destroy as a backstop",
    "If you deploy one today, destroy it before you go to the party",
], "Say the last line twice. Someone will otherwise go home to a surprise, and they'll blame the workshop."),

# ─────────────────────── 12:15 SQL PROJECTS ───────────────────────
(SECTION, "Database as code — SQL projects",
    "12:15  ·  A schema that builds like any other project", None,
    "Thirty minutes, tight, right before lunch. Get the DACPAC built and stop — publishing is the afternoon."),

(DARK, "Two ways to put a schema in source control", [
    "STATE-BASED  (what we teach)",
    "The repo describes what the database should look like",
    "A tool works out the difference and generates the change",
    "Reviewable as a diff of the object, not a pile of scripts",
    "SQL projects, DACPAC — native to SQL Server, Azure SQL and Fabric",
], [
    "MIGRATION-BASED  (also in the repo)",
    "The repo is an ordered list of changes to apply",
    "You write the change; nothing is inferred",
    "Total control, especially over data movement",
    "Flyway, dbatools/dbops — both working, both demoed if time allows",
], "Neither is wrong. State-based is where the review story is strongest, which is why it's the taught path."),

(CONTENT, "The sample database", [
    "A football schema — men's and women's competitions in one model",
    "Nine tables, three views, three stored procedures, and seed data",
    "Real enough to break in interesting ways this afternoon",
    "Jess brings Taylor Swift, Rob brings Metallica, we agreed on football",
    "It builds to a DACPAC. That artefact is what ships.",
], "The seeded data matters later — the 15:30 trap only works because a column has real values in it."),

(CMD, "Build the DACPAC", [
    "dotnet build database/sql-projects/FabConFootball.sqlproj -warnaserror",
    "",
    "# Produces bin/Release/FabConFootball.dacpac",
    "# AND runs T-SQL static code analysis on every build.",
    "",
    "# -warnaserror means a code smell fails the build,",
    "# which is exactly what CI does on every push and PR.",
], "Break something on purpose if you have the time — a SELECT * or a non-SARGable predicate — and let the build fail in public."),

(CONTENT, "The quality bar, and why it's in the build", [
    "SARGable predicates — no functions wrapped around the column you're filtering",
    "Explicit column lists — never SELECT *",
    "Set-based, not row-by-row — no cursors",
    "No MERGE — the correctness and locking gotchas aren't worth it",
    "Static analysis runs on every build, and CI fails on any finding. Zero, not 'few'.",
], "Our moderator is Cláudio Silva, a performance-tuning expert, and he is sitting in the front row. Say so — it makes the point memorably."),

(SECTION, "Lunch",
    "12:45  ·  Sixty minutes  ·  Back at 13:45", None,
    "Destroy anything expensive before you go and eat. Lead by example."),

# ─────────────────────── 13:45 CI/CD 1 ───────────────────────
(SECTION, "CI/CD part 1 — build and validate",
    "13:45  ·  Making the pipeline have an opinion", None,
    "Forty-five minutes. The goal is a red build, then a green one, on a real PR."),

(CONTENT, "What CI checks on every push and PR", [
    "The SQL project builds — schema errors surface in seconds, not at deploy",
    "T-SQL static analysis runs, with warnings as errors",
    "terraform fmt and validate — formatting is not a matter of taste in a shared repo",
    "terraform plan on a pull request, read-only, with locking disabled",
    "The docs site builds strictly, so a broken link fails the build",
], "Run the PR live if you can. Watching the checks tick over is more persuasive than any slide."),

(DUAL, "Plan on a PR. Apply on purpose.", [
    "ON THE PULL REQUEST",
    "Read-only: fmt, validate, plan",
    "Runs automatically, on every push to the branch",
    "The plan output is the review artefact",
    "Nothing is created, so nothing can surprise you",
], [
    "ON THE APPLY",
    "Manual dispatch from main — a human decides",
    "Same code, same state, no new surprises",
    "The deliberate act is the safety feature",
    "This is the people lesson from 09:30, in YAML",
], "Explicitly call back to the morning here. The room should feel the two halves of the day joining up."),

(CONTENT, "No secrets. Not one.", [
    "GitHub Actions authenticates to Azure with OIDC — a short-lived federated token",
    "No client secret, no password, nothing to rotate or leak",
    "The app registration trusts a specific repo and a specific branch or event",
    "A PR run's identity is different from a main-branch run's identity — that's the point",
    "Getting that subject string wrong cost us an afternoon. It's in our learnings log.",
], "The AADSTS700213 story is a good one — the credential existed, but the subject was silently mangled by PowerShell string parsing."),

# ─────────────────────── 14:30 CI/CD 2 ───────────────────────
(SECTION, "CI/CD part 2 — deploy infrastructure automatically",
    "14:30  ·  From merged PR to running infrastructure", None,
    "Forty-five minutes. One dispatch should provision infra and publish the schema, passwordless, end to end."),

(CONTENT, "The apply workflow, end to end", [
    "Authenticate with OIDC — no secrets in the repo or the runner",
    "terraform init against the remote state, with Entra auth to the blob",
    "terraform apply, taking a lock so two runs can't collide",
    "Then publish the DACPAC into the database it just created",
    "One dispatch. Infrastructure and schema. Nothing typed by hand.",
], "This is the money demo of the afternoon. If anything is going to be rehearsed to death, make it this one."),

(CONTENT, "Environments, approvals and who holds the button", [
    "A GitHub Environment can require a named reviewer before a job runs",
    "It can hold the run open for a wait timer, or restrict it to a branch",
    "It turns 'who is allowed to do this' into configuration, not convention",
    "Note: required reviewers need a paid plan on private repos — check before you promise it",
    "Where the plan blocks it, describe the pattern even if you can't demo it",
], "Be honest that we hit the plan limitation ourselves. Describing the pattern beats pretending it's wired up."),

(CONTENT, "Teardown is part of the pipeline", [
    "A destroy workflow, scheduled nightly and available on demand",
    "Because a workshop environment that survives the workshop is just a bill",
    "It also proves the code can rebuild from nothing, every single day",
    "The state account deliberately lives outside the blast radius",
    "If you can't destroy it confidently, you don't really have it as code",
], "The last line is the sharpest test of infrastructure-as-code anyone will offer them today."),

# ─────────────────────── 15:30 CI/CD 3 ───────────────────────
(SECTION, "CI/CD part 3 — ship database changes automatically",
    "15:30  ·  Three pull requests, one of them a trap", None,
    "Forty-five minutes and the emotional peak of the day. Do not rush increment 2."),

(CONTENT, "Three increments, three pull requests", [
    "One — add a view. Additive, safe, fully automatable.",
    "Two — drop a column that has data in it. Bundled with something harmless.",
    "Three — ship that same destructive change, safely and on purpose.",
    "Each one is a real PR against the real schema",
    "The middle one is where the day earns its keep",
], "Set the three up front so nobody thinks increment 2 is a mistake when it goes wrong."),

(CONTENT, "Increment 1 — additive change", [
    "Add a view: vw_SquadAges",
    "Rebuild the project, produce a new DACPAC",
    "Run a deploy report — one object to create, no data issues",
    "Publish it. It just works, and that's the confidence-builder.",
    "This is the one to try on your own target while we talk",
], "Invite the follow-along crowd to actually run this one. It's safe and it feels good."),

(DARK, "Increment 2 — the trap", [
    "WHAT THE PULL REQUEST LOOKS LIKE",
    "A useful new view — vw_TeamRosterSizes",
    "And a column removed from the Player table",
    "Two files. Looks tidy. Reviewer approves in nine seconds.",
    "Nobody typed the word DROP anywhere.",
], [
    "WHAT ACTUALLY HAPPENS",
    "The target column is populated with real data",
    "A naive publish drops the column and the data with it",
    "No error. No warning. A green tick.",
    "You find out when someone asks where the shirt numbers went.",
], "Show the data existing before you deploy. The silence of the green tick is the whole lesson."),

(CMD, "The database's plan", [
    "# Never publish blind. Ask what WOULD happen first.",
    "",
    "sqlpackage /Action:DeployReport `",
    "  /SourceFile:'bin/Release/FabConFootball.dacpac' `",
    "  /Profile:'PublishProfiles/AzureSql.publish.xml' `",
    "  /TargetServerName:$server /TargetDatabaseName:$db `",
    "  /AccessToken:$token `",
    "  /OutputPath:'deploy-report.xml'",
    "",
    "# Look for <Alert Name=\"DataIssue\"> — that's your weekend calling.",
], "This is terraform plan for the database. Make that comparison explicitly — it's the sentence people will remember."),

(CONTENT, "Increment 3 — ship it safely anyway", [
    "BlockOnPossibleDataLoss is on by default — let it stop you",
    "Move the data first, in a pre-deploy script, then retire the column",
    "Publish the deploy report as a build artefact, so the diff is reviewable",
    "Put an approval gate in front of the destructive step",
    "The change still ships. It just stops being an accident.",
], "Land the day's thesis: automation isn't about removing humans, it's about putting them where they add judgement."),

(DUAL, "Who is allowed to drop a column?", [
    "THE TECHNICAL ANSWER",
    "Whoever the environment protection rule names",
    "Enforced by the pipeline, not by convention",
    "Logged, timestamped, attached to a specific run",
    "Reversible up to the moment they click approve",
], [
    "THE REAL ANSWER",
    "Whoever the team has agreed should carry that decision",
    "The pipeline just makes the agreement enforceable",
    "And makes it a shared decision instead of one person's fault",
    "That's the 09:30 talk again — this is what it was for",
], "Close the loop that opened at 09:30. This is the callback that makes the whole day feel designed."),

# ─────────────────────── 16:15 TOGETHER ───────────────────────
(SECTION, "Migrations, drift and teardown",
    "16:15  ·  The rest of the map", None,
    "Thirty minutes, flexible. This is the module to trim if you're running late."),

(DUAL, "The alternatives, honestly", [
    "FLYWAY",
    "Migration-based, versioned scripts, applied in order",
    "Excellent when data movement is the hard part",
    "Strong story for teams already living in that model",
    "Working example in the repo, against the same schema",
], [
    "DBATOOLS / DBOPS",
    "PowerShell-native, familiar to a lot of this room",
    "Migration-based, scriptable, easy to embed anywhere",
    "Our own heritage, so we can be honest about the edges",
    "Also in the repo, also against the same schema",
], "One schema, three tooling paths. That's the credibility play — nothing here is theoretical."),

(CONTENT, "Drift, and what to actually do about it", [
    "Drift is what happened between your code and someone's Tuesday",
    "Detect it: run plan on a schedule and fail loudly if it isn't empty",
    "Then decide — was the change wrong, or is the code out of date?",
    "Reverting good manual fixes is how you lose the room",
    "Absorb the fix into code, then re-apply. Every time.",
], "The fourth bullet is a people lesson hiding in an operations slide. Worth naming as such."),

(CONTENT, "Destroy it. Really.", [
    "Everything you built today can be removed with one command",
    "Fabric capacities in particular — pause or destroy before you leave",
    "The teardown path is code too, and it gets tested nightly",
    "An environment you're afraid to delete is an environment you don't control",
    "Go and check your subscription tonight. Please.",
], "Say it plainly. Every workshop generates at least one surprised person and one surprising invoice."),

# ─────────────────────── 16:45 WRAP ───────────────────────
(SECTION, "Wrap-up",
    "16:45  ·  What to take home", None,
    "Fifteen minutes including questions. Get them to the resources page before anyone starts packing."),

(DUAL, "What you can take home today", [
    "THE CODE",
    "Terraform and Bicep for Azure SQL and Fabric SQL",
    "GitHub Actions and Azure DevOps pipelines, both working",
    "A SQL project, plus Flyway and dbatools/dbops equivalents",
    "The three-increment demo, exactly as we ran it",
], [
    "THE WRITTEN STEPS",
    "Every module as a page, with the real commands",
    "Prerequisites, so you can start from a clean machine",
    "Our learnings log — the gotchas, with the fixes",
    "All of it public, all of it replayable at your own pace",
], "Give them the URL twice and put it on the next slide too. Nobody writes it down the first time."),

(CONTENT, "Where everything lives", [
    "The site: the written steps for every module in today's agenda",
    "The repo: github.com/JessAndRob/FabConEU_2026_workshop",
    "Code bundles: downloadable per module, no copy-paste from slides",
    "Our learnings log: every gotcha we hit building this, with the fix",
    "Find us both here today — and on the internet forever after",
], "Have the QR code on screen while you take questions. Don't take it down until the room is empty."),

(QUOTE, "Thank you", [
    "You gave us a whole day. We hope it saves you several.",
    "Deploy the infrastructure as code.",
    "Deploy the database as code.",
    "And be kind to the humans in the change window.",
    "Questions — and then please rate the session",
], "Then hand over to the rating slide. Stay at the front — the best conversations happen in the ten minutes after."),
]
