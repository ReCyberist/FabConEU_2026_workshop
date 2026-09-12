# Deck content for the FabCon Europe 2026 workshop.
# Kinds: SECTION (title + strapline) | CONTENT (title + bullets) | DUAL (title + two columns)
#        DARK (dual, dark background) | CMD (title + monospace command block)
#        QUOTE (title + large unbulleted lines)
#        IMAGE (title + optional bullets + a dashed box holding the prompt that makes the artwork)
#        DEMO  (the "we are going to the terminal now" slide — title, a quip, then the plain part)
#
# An IMAGE entry is (IMAGE, title, bullets, prompt, notes). Give it bullets and the picture
# takes the right-hand half; give it an empty list and the picture takes the whole slide.
# The prompt is written to be pasted straight into Napkin, Eraser or Claude — say what the
# diagram must show and what point it has to make, not what it should look like.

# A DEMO entry is (DEMO, title, quip, lines, notes). One before every demo, so the room
# knows the slides have stopped and the typing has started. The quip is the only place in
# a demo slide humour belongs; the lines under it stay plain, because they tell people
# whether to follow along or sit back.
SECTION, CONTENT, DUAL, DARK, CMD, QUOTE, IMAGE, DEMO = (
    "SECTION", "CONTENT", "DUAL", "DARK", "CMD", "QUOTE", "IMAGE", "DEMO")

# ─────────────────────────── THE WALK-IN SLIDE ───────────────────────────
# Slide 1, and the only slide most of the room reads before we say a word. It is
# on screen from the moment the doors open, so it carries the one thing someone
# arriving at 08:40 can act on: where the written steps live.
#
# Step register (CLAUDE.md 5b) throughout. It is read from the back row, in a
# second language, by somebody holding a coffee. No idioms, no jokes, no hedging.
# The URL must match `site_url` in mkdocs.yml exactly — the path is case sensitive.
WALK_IN_TITLE = "Welcome. We start at 09:00."
WALK_IN_URL = "jessandrob.github.io/FabConEU_2026_workshop"
WALK_IN_LINES = [
    "Azure SQL or Fabric SQL: Infrastructure and Databases as Code",
    "Jess Pomfret & Rob Sewell  ·  FabCon Europe 2026, Barcelona",
    "",
    "Every command we run today is written up on that site.",
    "While you wait, open it and read the Prerequisites page.",
]
# Dashed boxes on the walk-in slide. Delete one and drop a picture in its place —
# they are placeholders, not art. Any number works; they are laid out to fit.
WALK_IN_IMAGES = [
    "Photo — Jess",
    "Photo — Rob",
    "QR code → the site",
]

# Slides that carry a link strip under their content: {slide title: (lead line, address)}.
# The room hears the address at the door and again at the end — these are the two moments
# in between when somebody actually wants it.
URL_STRIPS = {
    "What today is, and what it isn't": (
        "Every command we run today is written up here:",
        "jessandrob.github.io/FabConEU_2026_workshop",
    ),
    "The run of the day": (
        "The agenda, and every page behind it:",
        "jessandrob.github.io/FabConEU_2026_workshop/setup/welcome",
    ),
}

WALK_IN_NOTES = (
    "Doors open. This slide stays up until 09:00 — do not advance past it to set up, "
    "because the URL is the only thing an early arrival can act on. "
    "Read the address out loud once when the room is about half full, and again at 09:00. "
    "Nobody writes it down the first time. "
    "If the site reveal PR has not been merged yet, only Home and Prerequisites are live — "
    "that is still the right page to send them to."
)

DECK = [
# ─────────────────────────────── OPENING ───────────────────────────────
# 09:00-09:20. Framing only. Nothing here is taught again later, and nothing
# here needs a demo behind it.
(CONTENT, "Who are we: Jess Pomfret", [
    "Microsoft MVP, Data Platform Architect",
    "Ohio, USA — Taylor Swift, and a firm view that lunch is non-negotiable",
    "Would most like to stop deploying anything at all on a Friday afternoon",
], "Ninety seconds, and the slide is yours — swap these bullets for your own. What is on it is only what the repository already knew about you. Hand off to Rob by name at the end."),

(CONTENT, "Who are we: Rob Sewell", [
    "Microsoft MVP, dbatools and dbachecks maintainer",
    "Wakefield, UK — Metallica, and never clicking 'Next' in a wizard again",
    "Between us: a lot of production databases, and a lot of scar tissue",
    "Today is the day we hand over both the code and the scars",
], "Ninety seconds, same as Jess. The room came for the tech, not our CVs, so keep the CV to one line and spend the time on the last two bullets. The scar-tissue line is what sets up 09:30."),

(DUAL, "What today is, and what it isn't", [
    "IT IS",
    "Infrastructure and databases deployed as code, start to finish",
    "Real pipelines that provision and ship, not screenshots of them",
    "Azure SQL and Fabric SQL, side by side, all day",
], [
    "IT ISN'T",
    "A managed lab — nothing is provisioned for you",
    "A tool bake-off — we lead with one path and show you the rest",
    "A click-through of the portal",
], "The 'no clicking required' promise lands here. Say it out loud — you'll be held to it all day, deliberately. The site address is on this slide because it is the first moment anyone wonders where the steps live."),

(DUAL, "The run of the day", [
    "MORNING",
    "09:00  Welcome, and why any of this",
    "09:20  Environment check",
    "09:30  The hardest part of IT",
    "10:00  Source control foundations",
    "10:30  Break — thirty minutes",
    "11:00  Infra as code — Azure SQL, Fabric SQL",
    "12:15  Database as code — SQL projects",
    "12:45  Lunch — back at 14:00",
], [
    "AFTERNOON",
    "14:00  CI/CD — build, validate, deploy",
    "14:35  Database changes — three pull requests",
    "15:15  Break — thirty minutes",
    "15:45  Retiring a column safely, end to end",
    "16:40  Migrations, drift and teardown",
    "16:52  Questions",
    "17:00  End",
], "Point at 09:30. Yes, that's a talk about feelings, and yes, it's before the Terraform. Explain why in one sentence and move on. The breaks and lunch are the venue's, not ours — say that, because it is why the teaching flexes and they don't."),

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

(DUAL, "Being good to each other", [
    "IN THE ROOM",
    "Phone calls outside — that is what doors are for",
    "Phones and laptops on silent, please",
    "Ask questions. Someone else is quietly wondering the same thing.",
    "No question here is too basic to ask",
], [
    "ABOUT EACH OTHER",
    "Some of this room swears by Bicep. Some will never give up Flyway.",
    "They are not wrong — the problem is different",
    "Argue with the idea, never the person holding it",
    "The code of conduct applies all day, and we will happily enforce it",
], "Thirty seconds, said warmly and then dropped — this is a welcome, not a lecture. It is also the first quiet trailer for 09:30: every hard part of today is a people problem before it is a technical one. The phone-call line is the one people actually act on, so say it plainly and move on."),

# ─────────────────────── 09:10 WHY ───────────────────────
(SECTION, "Why infrastructure as code for data",
    "09:10  ·  Setting the promise: no clicking required", None,
    "Ten minutes. If you have not reached this slide by 09:10, the opening ran long. The goal is agreement on the problem, not on the tooling."),

(IMAGE, "The way most data platforms actually get built", [
    "It starts with one click, for a proof of concept",
    "The proof of concept goes to production, as they always do",
    "A firewall rule gets added by hand, at 6pm, by whoever is around",
    "It ends with nobody daring to touch it",
],
    "A left-to-right decay timeline for a data platform, in four stages: someone clicks a server "
    "into existence for a proof of concept; the proof of concept goes to production; a firewall rule "
    "is added by hand at 6pm; nobody dares touch it any more. Beneath the timeline run two lines "
    "moving in opposite directions - confidence falling, time-to-make-a-change rising. Dark green and "
    "gold, calm and diagrammatic, no clip-art people.",
    "Ask for a show of hands on the firewall rule. You will get one, and that show of hands is the whole justification for the day. Do not read the bullets — tell the story over the picture."),

(CONTENT, "What 'as code' actually buys you", [
    "Repeatable — the same input produces the same environment, every time",
    "Reviewable — a change is a diff a human can argue with before it happens",
    "Recoverable — the environment is a git clone away, not a support ticket",
    "Disposable — and that is the underrated one. You can destroy it fearlessly.",
], "'Disposable' is worth dwelling on — fear of teardown is what keeps zombie environments alive and billing. The other three they have heard before; this one lands."),

(DUAL, "All of it as code. One path in the teaching.", [
    "WHAT WE TEACH TODAY",
    "Terraform for infrastructure",
    "GitHub Actions for CI/CD",
    "SQL projects (.sqlproj / DACPAC) for schema",
], [
    "WHAT'S ALSO IN THE REPO",
    "Bicep, mirroring every Terraform module",
    "Azure DevOps pipelines, mirroring every workflow",
    "Flyway and dbatools/dbops for migration-based schema",
], "Head off the 'but we use Bicep/ADO' question early. Answer: it's in the repo, tested, and we'll show it if we're ahead of time."),

# ─────────────────────── 09:20 ENVIRONMENT ───────────────────────
(SECTION, "Environment check",
    "09:20  ·  Ten minutes — then we move on", None,
    "Deliberately short. Anyone still broken gets helped at the 10:30 break, not now. Say that kindly but clearly."),

(IMAGE, "Everything you need is on one page", [
    "jessandrob.github.io/FabConEU_2026_workshop",
    "→ Getting started → Prerequisites",
    "",
    "If something will not install, you can still follow along. Just watch.",
    "We move on at 09:30 either way.",
],
    "A checklist of the six things this workshop needs on a laptop, each paired with the one "
    "command that proves it is there: git, the Azure CLI, Terraform, the .NET SDK, SqlPackage, and "
    "a signed-in Azure account. Show each with a tick. Make it clear that a missing tick means "
    "'watch today, install it tonight' rather than 'you are stuck'. Calm and diagrammatic, no "
    "terminal screenshots.",
    "No commands on the slide any more — they live on the prerequisites page, which is the only copy anyone maintains. Have that page open on the second screen and point at it. Do not debug individuals from the front; pick people up at the 10:30 break."),

# ─────────────────────── 09:30 THE HARDEST PART ───────────────────────
# The exception to the rule. No demo, no commands — thirty minutes of talking, so
# every lesson gets a picture to talk over instead of a bullet list to read out.
(SECTION, "First up: the hardest part of IT",
    "09:30  ·  It isn't the YAML", None,
    "Thirty minutes, no demo to hide behind. Watch the clock — this is the easiest module in the day to overrun. Every slide from here to 10:00 is a picture with a story attached. Tell the story; the bullets are only there to stop you losing your place."),

(QUOTE, "Here's the bits the AI doesn't know", [
    "We can show you the tech part.",
    "Most of you will probably Copilot/Claude/ChatGPT it anyway.",
    "But here's the bits the AI doesn't know —",
    "it's the blood balloons with egos… and feelings.",
    "This is what we have learnt.",
], "This is the slide. Let it sit. Don't read it word for word — say it in your own voice, then pause before the next slide."),

(DARK, "The honest split", [
    "WHAT THE MACHINE WILL DO FOR YOU",
    "Write the Terraform module",
    "Write the pipeline YAML",
    "Explain the error message",
    "Do it again tomorrow, faster",
], [
    "WHAT IT WILL NOT DO FOR YOU",
    "Tell the DBA their manual process is the bottleneck",
    "Decide who is allowed to drop a column",
    "Absorb the blame when it goes wrong at 2am",
    "Rebuild trust after it did",
], "The right-hand column is the entire reason this module exists. None of it is a tooling problem."),

(IMAGE, "Lesson 1 — It was never about the tool", [
    "Nobody resists Terraform. They resist losing control.",
    "The person guarding the manual process is usually the person who got burned",
    "Automating their job away is a threat. Automating their 2am is a gift.",
],
    "The same change, framed two ways. Show one identical Terraform change in the middle, with an "
    "arrow going left and an arrow going right. On the left it is labelled 'this automates your job "
    "away' and the person receiving it is guarded and defensive. On the right it is labelled 'this "
    "automates your 2am' and the same person is relieved. One caption underneath: same change, "
    "completely different conversation. Simple line art, no stock photography.",
    "Rob / Jess — put your own story here. The specific one beats the general point every time. The picture buys you the time to tell it."),

(IMAGE, "Lesson 2 — \"Databases are different\"", [
    "It's a feeling, with a grain of truth in it",
    "The truth: state can't be rolled back by redeploying",
    "The feeling: therefore nothing about them can be automated",
    "Take the constraint seriously and the fear loses its cover story",
],
    "Two deployments compared, stacked. On top, a stateless application: the old version is removed, "
    "a new one is deployed, and rolling back simply means deploying the previous one - nothing is "
    "lost. Underneath, a database drawn as a container of rows: deploying a new version cannot bring "
    "back rows that were thrown away, so there is no undo. Label the top 'roll back by redeploying' "
    "and the bottom 'there is no undo'. The point is that the constraint is real engineering, not a "
    "feeling.",
    "This is the bridge to the whole afternoon — state-based deploys, data-loss gates, the DeployReport. Name that now and point at the bottom half of the picture when you do."),

(IMAGE, "Lesson 3 — Review is where egos go to die, or grow", [
    "A pull request is a person saying \"check my work\" in public",
    "Comment on the change, never the changer",
    "Approve fast. A PR sat for three days teaches people not to open one.",
],
    "One pull request with two possible review comments pointing at the same line of code. The first "
    "points at the change and reads 'this drops a populated column'; follow it to a fix, and to more "
    "pull requests being opened afterwards. The second points at the author and reads 'you nearly "
    "deleted prod'; follow it to fewer pull requests being opened afterwards. Show the two "
    "consequences as diverging paths. Keep it calm and professional, not cartoonish.",
    "If you only get one lesson across today, this is a strong candidate. It is also the one that makes 15:30 work, and the one the merge-conflict demo at 10:00 pays off."),

(IMAGE, "Lesson 4 — Blame is a deployment risk", [
    "In a blaming team, the safest move is to change nothing",
    "So changes get batched, and batched changes are the dangerous kind",
    "Psychological safety isn't a poster. It's a deployment frequency metric.",
],
    "Two postmortems and the deployment pattern that follows each one. On the left, a postmortem that "
    "names a person, leading to changes being held back, batched up, and shipped rarely in large risky "
    "drops. On the right, a postmortem that names a missing guardrail, leading to the guardrail being "
    "built and changes shipping small and often. Make the difference in batch size obvious at a "
    "glance, and label the outcome on each side.",
    "Link forward: the approval gate we build at 15:30 exists so no individual has to be the last line of defence."),

(IMAGE, "Lesson 5 — Start where the pain is", [
    "Don't open with \"we're going to transform the whole estate\"",
    "Open with the thing that ruined someone's weekend last month",
    "Credibility is spent, not granted — the first win is what buys it",
],
    "A small win at the centre spreading outward. Start with one specific ruined weekend being "
    "automated away and becoming boringly reliable, then rings expanding outward to the next thing, "
    "and the next. Off to one side, drawn large but greyed out and untouched, a full estate-wide "
    "architecture diagram labelled 'can wait'. The point is that credibility is spent, not granted.",
    "Good place to invite the room in: what ruined YOUR weekend? Two or three answers, no more, then move."),

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
# Overview into demo 01, plus the merge beat: the slot is 25 minutes and the
# branch-and-PR demo runs about eight, so there is room to show a conflict.
(SECTION, "Source control foundations for databases",
    "10:00  ·  Where the team agreements become commands", None,
    "Twenty-five minutes, then five to plant plan-on-PR and send them to coffee at 10:30. Two demos in this slot: the branch-and-pull-request one, then the merge conflict. Most of the room knows git; few have put a database in it."),

(DUAL, "Why databases arrived late to source control", [
    "THE HONEST REASONS",
    "The database was the deployed artefact AND the source of truth",
    "Tooling assumed a live connection, not a file on disk",
    "Everyone had a folder of numbered .sql files that mostly worked",
], [
    "WHAT CHANGED",
    "The schema can be a project that builds, like any other code",
    "The build produces an artefact — a DACPAC — you can version and ship",
    "Which means a database change can finally be a diff",
], "The 'folder of numbered scripts' line usually gets a laugh of recognition. Use it, then go to the demo — the repository itself is the rest of this slide."),

(CONTENT, "What never goes in the repo", [
    "Connection strings, passwords, subscription IDs, tenant IDs",
    "Terraform state — it contains everything you just promised not to commit",
    "*.tfvars — the example file is committed, your real one is not",
    "The answer isn't a better .gitignore. It's not having the secret at all.",
], "This sets up the OIDC story at 14:05. 'Not having the secret at all' is the punchline — say it, then prove it this afternoon."),

(DEMO, "Demo — branch, commit, pull request",
    "Nothing is clicked. Not even the pull request.", [
    "One small file, on a branch, reviewed in public",
    "Follow along on your own fork, or just watch — both are fine",
], "demo/01-source-control.ps1, about eight minutes. Say the follow-along line BEFORE you start typing, not after. Zoom the terminal up first — git output is small and the back row is real."),

(IMAGE, "Two people, one file", [
    "Two branches from the same commit, both editing the same lines",
    "The first merges cleanly. The second stops.",
    "A conflict is not an error — it is git refusing to guess",
    "It is also the only moment git admits there are two humans involved",
],
    "A git branch diagram. One main line, with two branches taken from the same commit. Both branches "
    "edit the same lines of the same file. Show the first branch merging back cleanly, and the second "
    "stopping at a conflict. Mark the conflict clearly as an expected event rather than a failure. "
    "Include a small inset showing what the conflict markers actually look like in the file, with the "
    "two competing versions labelled by author.",
    "Say the last bullet out loud — it is the whole reason this slide sits after the 09:30 module. "
    "WHAT THE DEMO SHOWS, in order: git status names the file and tells you both ways out; open it, "
    "choose, delete the markers, commit. Run `git merge --abort` BEFORE you resolve anything — a room "
    "that knows it can undo a merge will branch, and a room that does not will avoid branches for the "
    "rest of their career. Nothing is lost either way, and that is the point of a branch. "
    "WHAT IT ACTUALLY MEANS, said while you resolve it: two people solved the same problem "
    "differently and both were reasonable. Someone has to choose, in public, and say why. Comment on "
    "the change, never the changer — that is Lesson 3, in a command. The team that resolves conflicts "
    "kindly is the team that branches at all."),

(DEMO, "Demo — the merge conflict",
    "Two presenters, one file, no winner.", [
    "Rob and Jess both edit the same lines, from the same commit",
    "Nothing to type for this one — it needs two laptops. Sit back.",
], "demo/01b-merge-conflict.ps1 — presenter-only, about nine minutes, two laptops. Say the 'nothing to type' line out loud or half the room will try and fall behind. Let the red text land and stay quiet for two seconds."),

(SECTION, "Break",
    "10:30  ·  Thirty minutes  ·  Back at 11:00", None,
    "Say the time twice. The break is the venue's and it is thirty minutes, not fifteen. Use it for individual environment problems — this is where the 09:20 stragglers get sorted, not the front of the room. Be back on stage two minutes early."),

# ─────────────────────── 11:00 AZURE SQL ───────────────────────
(SECTION, "Provisioning infrastructure as code — Azure SQL",
    "11:00  ·  Terraform, and the first real apply", None,
    "Thirty minutes, all of it after the break. There is nowhere to hide the apply any more: start it early and narrate these three slides over the top of it. Never start an apply and then go quiet. Have a completed run open in a second window as the fallback."),

(IMAGE, "What we're about to provision", [
    "Entra-only authentication — there is no admin password anywhere today",
    "A serverless database, so it costs pennies while it's idle",
    "A firewall rule declared in code, not added in a panic",
    "All of it destroyable in one command, which is the point",
],
    "An Azure architecture diagram of exactly what this Terraform module creates: a resource group "
    "containing a logical SQL server and, inside it, a serverless database, with a firewall rule "
    "attached to the server. Label each resource with its CAF-style name - rg-fabcon26-test-uks, "
    "sql-fabcon26-test-uks, sqldb-football-test. Mark the server as Entra-only authentication and "
    "make it visually obvious that no password exists anywhere in the diagram.",
    "Emphasise Entra-only: there is no admin password anywhere in this workshop, by design."),

(DEMO, "Demo — Azure SQL from nothing",
    "Four minutes of a spinner, and then a database. Genuinely the good bit.", [
    "init, plan, apply — into a real Azure subscription",
    "Following along? Start yours now. We will talk over it.",
], "demo/02-infrastructure.ps1 regions 01-10. Start the apply EARLY and narrate the next two slides over the top of it. Never start an apply and then go quiet. Fallback run open in the second window."),

(IMAGE, "Terraform in ninety seconds", [
    "init — providers and backend",
    "plan — what WOULD change, before anything does",
    "apply — do it, and record it",
    "destroy — undo it, on purpose",
],
    "The Terraform workflow as a loop: init, then plan, then apply, with destroy closing the circle "
    "back to nothing. Put state in the middle as the shared memory that all four steps read from and "
    "write to. Annotate plan as 'what would change' and apply as 'what did change'. One line beneath: "
    "lose the state and Terraform forgets what it owns.",
    "plan/apply is the same shape as the DeployReport/publish pair we use for the database this afternoon. Plant that now — it is the single most reused idea in the day."),

(DUAL, "State: the bit that bites in CI", [
    "LOCAL STATE",
    "A file on your laptop, fine for a one-shot lab",
    "Not shared, not locked, not backed up",
    "A GitHub runner is destroyed after every job, so plan and apply would share nothing",
], [
    "REMOTE STATE — WHAT WE RUN",
    "Azure Storage, versioned and soft-delete enabled",
    "Entra auth to the blob — no storage account keys",
    "Its own resource group, so nightly destroy can never eat it",
], "This is decision D5. The 'its own resource group' detail is a genuine scar — the nightly destroy would otherwise delete the state store. The last slide to narrate over a running apply."),

# ─────────────────────── 11:30 FABRIC SQL ───────────────────────
(SECTION, "Provisioning infrastructure as code — Fabric SQL",
    "11:30  ·  The same idea, a younger platform", None,
    "Twenty-five minutes, and the first thing to compress if Azure SQL ran long. Be honest about the rough edges — the room will respect it and they'll hit them anyway. The local Fabric module has not been run live end to end: do not say 'this works exactly the same'. Say what is true — the module is built, the Azure SQL half is verified, and this is the shape the Fabric one takes."),

(IMAGE, "Azure SQL and Fabric SQL, side by side", [
    "Azure SQL: resource group → server → database",
    "Fabric SQL: resource group → capacity → workspace → database",
    "The capacity is ARM. The workspace and the database are not.",
    "Which is exactly where the Bicep path runs out of road",
],
    "Two resource stacks drawn side by side for comparison. On the left, Azure SQL: resource group, "
    "then logical server, then database, with the whole stack shaded to show it is fully modelled in "
    "ARM so both Terraform and Bicep can build it. On the right, Fabric SQL: resource group, then "
    "capacity, then workspace, then SQL database - but only the capacity is shaded as ARM, with a "
    "clear horizontal line marking where ARM support stops and everything above it must be built "
    "through the Fabric provider or REST API. That line is the entire point of the diagram.",
    "The ARM / not-ARM line is the single most useful thing in this module. Point at it. It is why the Bicep path stops at the capacity, and it is the answer to the question someone will ask."),

(CONTENT, "What else bites in the Fabric path", [
    "Service principals need a tenant setting switched on before they can do anything",
    "And a workspace role — being subscription Owner buys you nothing here",
    "Young provider, moving fast: pin your versions",
    "A capacity bills while it exists, idle or not. F2 is the smallest. It is not free.",
], "The first two cost us real time — tell them the error message so they recognise it when it bites. The last bullet is the one that costs them money: say it twice, and say 'destroy it before you go to the party'. This is the first slide to drop if Morning 2 is running late."),

(DEMO, "Demo — Fabric SQL from nothing",
    "Same three commands. Younger platform. Sharper edges.", [
    "capacity → workspace → database, and two providers to build it",
    "We have not run this one live end to end. You will see what we see.",
], "demo/02-infrastructure.ps1 regions 12-19. If you are behind, show the plan and skip the apply — the contrast is the teaching point, not the second set of resources. Be honest about the rough edges; the room will respect it."),

# ─────────────────────── 12:15 SQL PROJECTS ───────────────────────
(SECTION, "Database as code — SQL projects",
    "12:15  ·  A schema that builds like any other project", None,
    "Thirty minutes, tight, and the only thing between the room and lunch. Get the DACPAC built and stop — publishing is the afternoon. Do not overrun; you will not win."),

(IMAGE, "Two ways to put a schema in source control", [
    "State-based — the repo says what the database should look like",
    "Migration-based — the repo says what to do to it, in order",
    "We teach state-based, because the review story is strongest",
    "Both are in the repo, against the same schema",
],
    "State-based versus migration-based deployment, compared side by side. On the left, state-based: "
    "the repository holds the desired shape of the database, one object per file; a tool compares that "
    "to the live target and generates the change automatically. On the right, migration-based: the "
    "repository holds an ordered, numbered list of change scripts that are applied in sequence. Show "
    "the same single change - adding one column - travelling through both routes to the same database. "
    "Neither side should look like the wrong answer.",
    "Neither is wrong. State-based is where the review story is strongest, which is why it is the taught path. Flyway and dbatools/dbops are in the repo for anyone who wants the other route."),

(IMAGE, "The sample database", [
    "Football — men's and women's competitions in one model",
    "Nine tables, three views, three stored procedures, seed data",
    "Real enough to break in interesting ways this afternoon",
    "It builds to a DACPAC. That artefact is what ships.",
],
    "An entity-relationship diagram of a football database covering both the men's and the women's "
    "game: nine tables including Player, Team, Competition, Season and Fixture, with the relationships "
    "between them. Highlight the Player table, and within it the ShirtNumber column, because that is "
    "the populated column the afternoon deliberately drops. Standard crow's-foot ER notation, clean "
    "enough to read from the back of a large room.",
    "The seeded data matters later — the 14:50 trap only works because ShirtNumber has real values in it. Point at that column now so the room recognises it after lunch."),

(DEMO, "Demo — the schema becomes an artefact",
    "Nine tables, two competitions, one artefact. No VAR.", [
    "dotnet build turns the schema into a DACPAC, and runs static analysis doing it",
    "Follow along if you have the .NET SDK — then we stop, and you eat",
], "demo/03-database.ps1 regions 01-04. Build the artefact and STOP — publishing is the afternoon. Thirty minutes, and the only thing between the room and lunch: do not overrun, you will not win."),

(CONTENT, "The quality bar, and why it's in the build", [
    "SARGable predicates — no functions wrapped around the column you're filtering",
    "Explicit column lists — never SELECT *",
    "No MERGE — the correctness and locking gotchas aren't worth it",
    "Static analysis runs on every build, and CI fails on any finding. Zero, not 'few'.",
], "Our moderator is Cláudio Silva, a performance-tuning expert, and he is sitting in the front row. Say so — it makes the point memorably. Break something on purpose if you have time and let the build fail in public."),

(SECTION, "Lunch",
    "12:45  ·  Seventy-five minutes  ·  Back at 14:00", None,
    "Say 14:00 twice. Destroy anything expensive before you go and eat — Fabric capacities especially. Lead by example."),

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
    "Open it and read it — a read-only SELECT, nothing existing touched",
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
