#!/usr/bin/env python3
"""Keep the presenter scripts and the attendee demo pages honest.

There are two halves to every demo in this repo:

    demo/NN-<section>.ps1     what Jess and Rob run     (presenter)
    docs/<section>/demo.md    what attendees follow     (site)

They drift. They have drifted: a `cd` pointing at `infra/azure-sql/terraform`
after the module moved to `infra/azure-sql/terraform/demo`, and a `variables.tf`
that has not lived at that path for months. Both shipped. Neither is the kind of
thing a human spots in review.

So this script checks the mechanical half of CLAUDE.md 7a:

  1. PAIRING  every demo/*.ps1 names a real attendee page, and every
              docs/**/demo.md is claimed by exactly one script.
              A presenter-only demo -- one the room watches rather than follows,
              so it has no attendee page at all -- declares
              `ATTENDEE PAGE: none` and is skipped by this half. Its paths are
              still checked.
  2. PATHS    every repository path either half mentions actually exists.

Paths are resolved the way the demo would resolve them: the script walks each
file top to bottom, tracks `cd`, and resolves relative paths against wherever
the demo has got to. So `Copy-Item ..\\demo\\ship-changes\\x.sql` is checked as
`database/demo/ship-changes/x.sql` when the demo is sitting in
`database/sql-projects` -- and a wrong `cd` is caught by everything that follows
it, which is exactly how the shipped bugs behaved.

It cannot tell you the prose has drifted. It can tell you the command is wrong,
which is the bug we have actually shipped.

Run it:  python .github/scripts/check-demo-paths.py
Exit 0 = clean, 1 = findings.
"""

from __future__ import annotations

import posixpath
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DEMO_DIR = REPO / "demo"
DOCS_DIR = REPO / "docs"

# ---------------------------------------------------------------------------
# Paths a demo CREATES as it runs, so they are correctly absent from a clean
# checkout. Every entry needs a reason -- an unexplained entry here is how a
# real bug gets silenced.
# ---------------------------------------------------------------------------
EXPECTED_ABSENT = {
    "notes/fabcon.md": "created by demo 01, step 3",
    "notes/team-notes.md": "created by demo 01b on both branches, which is the whole point",
    "database/sql-projects/Views/vw_SquadAges.sql": "created by demo 03, increment 1",
    "database/sql-projects/Views/vw_TeamRosterSizes.sql": "created by demo 03, increment 2",
    "database/sql-projects/Views/vw_Standings.sql": "copied in by demo 05, the wrap-up database change; removed on reset",
    "database/sql-projects/Scripts/PreDeployment": "created by demo 03, increment 3A",
    "database/sql-projects/Scripts/PreDeployment/Migrate-ShirtNumber.sql": "created by demo 03, increment 3A",
    "database/sql-projects/FabConFootball.refactorlog": "created by demo 03, increment 3B",
    "database/sql-projects/bin/Release/FabConFootball.dacpac": "build output of demo 03, part 1",
    "database/sql-projects/bin/Release/FabConFootball.StaticCodeAnalysis.Results.xml": "build output of demo 03, part 1",
    "database/sql-projects/deploy-report.xml": "written by demo 03; gitignored",
    "database/sql-projects/deploy-report-increment-0.xml": "written by demo 03; gitignored",
    "infra/azure-sql/terraform/demo/terraform.tfvars": "copied from the .example by demo 02; gitignored",
    "infra/azure-sql/terraform/demo/backend_local_override.tf": "copied from the .example by demo 02; gitignored",
    "infra/fabric-sql/terraform/terraform.tfvars": "copied from the .example by demo 02; gitignored",
    "infra/fabric-sql/terraform/backend_local_override.tf": "copied from the .example by demo 02; gitignored",
}

# A token only looks like a repo path if it lands under one of these once
# resolved. Everything else is prose, a URL, or a shell argument.
REPO_ROOTS = (
    "agenda/", "database/", "demo/", "docs/", "includes/", "infra/",
    "notes/", "planning/", "slides/", ".github/",
)

# Commands whose arguments are paths. Copy-Item takes two; both are checked.
PATH_COMMAND = re.compile(
    r"^\s*(?:cd|code|Get-Item|Copy-Item|Remove-Item|git\s+restore"
    r"|New-Item\s+-(?:Path|ItemType\s+\S+\s+-Path)"
    r"|Select-String\s+-Path)\s+(.+?)(?:\s+#.*)?$",
    re.MULTILINE,
)
CD_COMMAND = re.compile(r"^\s*cd\s+(\S+)", re.MULTILINE)
MD_BACKTICK = re.compile(r"`([^`\n]+)`")
TERRAFORM_CMD = re.compile(r"^\s*terraform\s+(?:init|plan|apply|destroy)\b", re.MULTILINE)

# Git refs are not paths, and `demo/source-control` looks exactly like one.
GIT_BRANCH_DECL = re.compile(
    r"git\s+(?:switch\s+(?:-c|--create)|checkout\s+-b|branch\s+-D"
    r"|push\s+origin\s+--delete)\s+(\S+)"
)
BRANCH_NAME_EXAMPLE = re.compile(r"branch name \(for example, `([^`]+)`\)", re.IGNORECASE)


def clean(token: str) -> str:
    return token.strip().strip("\"'`,;:").rstrip(".")


def resolve(token: str, cwd: str) -> str | None:
    r"""Resolve a raw token to a repo-relative POSIX path, or None.

    Three cases, and only three:
      infra/azure-sql/...   already repo-rooted  -> check as-is
      ..\demo\x.sql  /  .\Tables\y.sql        -> resolve against cwd
      anything else (sqlpackage, microsoft/fabric, main) -> not a path
    """
    tok = clean(token)
    if not tok or tok.startswith(("-", "$", "@", "http", "/")):
        return None
    if any(c in tok for c in "$*?<>|"):
        return None
    tok = tok.replace("\\", "/")

    if tok.startswith(REPO_ROOTS):
        candidate = tok
    elif tok.startswith(("../", "./")):
        candidate = posixpath.join(cwd, tok)
    else:
        return None  # a bare word, a provider name, a branch -- not a path

    candidate = posixpath.normpath(candidate)
    if candidate.startswith("..") or not candidate.startswith(REPO_ROOTS):
        return None
    return candidate.rstrip("/")


def command_tokens(line: str) -> list[str]:
    """Path-shaped arguments from a command line, ignoring switches."""
    match = PATH_COMMAND.search(line)
    if not match:
        return []
    args = match.group(1).split("|")[0].split("#")[0]
    tokens, skip_next = [], False
    # PowerShell takes comma-separated arrays too: -Path a.sql,b.sql
    for token in re.split(r"[\s,]+", args):
        if not token:
            continue
        if skip_next:
            skip_next = False
            continue
        if token.startswith("-"):
            # -Path takes a path; -ErrorAction, -ItemType etc. do not.
            skip_next = token.lower() not in ("-path", "-force", "-recurse")
            continue
        tokens.append(token)
    return tokens


def scan(text: str, is_markdown: bool) -> tuple[set[str], set[str]]:
    """Walk the file in order, tracking cd, collecting resolved paths.

    Returns (all paths, cd targets that a terraform command is then run in).
    The second set exists because the worst bug we shipped was a `cd` to a
    directory that DID exist -- it was just the container folder, one level
    above the actual module, with no .tf files in it. "The path exists" was
    true and useless.
    """
    branches = set(GIT_BRANCH_DECL.findall(text))
    branches.update(BRANCH_NAME_EXAMPLE.findall(text))
    found: set[str] = set()
    tf_modules: set[str] = set()
    cwd = ""

    for line in text.splitlines():
        if TERRAFORM_CMD.search(line) and cwd:
            tf_modules.add(cwd)

        cd_match = CD_COMMAND.search(line)
        if cd_match:
            raw = clean(cd_match.group(1))
            if raw.startswith("$PSScriptRoot"):
                cwd = ""          # scripts use this to return to the repo root
                continue
            moved = resolve(raw, cwd)
            if moved is not None:
                found.add(moved)
                cwd = moved
            continue

        tokens = command_tokens(line)
        if is_markdown:
            for backticked in MD_BACKTICK.findall(line):
                if "/" in backticked or "\\" in backticked:
                    tokens += re.split(r"[\s,]+", backticked)

        for token in tokens:
            if clean(token) in branches:
                continue
            path = resolve(token, cwd)
            if path:
                found.add(path)

    return found, tf_modules


def tracked_tf_files(directory: str) -> list[str]:
    """Tracked *.tf files directly in a directory (not in its subfolders).

    Uses git rather than the filesystem on purpose: a leftover gitignored
    backend_local_override.tf from somebody's demo run must not make a wrong
    directory look right.
    """
    result = subprocess.run(
        ["git", "-C", str(REPO), "ls-files", f"{directory}/*.tf"],
        capture_output=True, text=True, check=False,
    )
    return [
        line for line in result.stdout.splitlines()
        if posixpath.dirname(line) == directory
    ]


def main() -> int:
    findings: list[str] = []

    # Demo scripts follow the NN-<section>.ps1 convention (they start with a digit,
    # in run order). Other .ps1 files in demo/ are tooling (e.g. Reset-DemoEnvironment.ps1),
    # not presenter demos, so they carry no ATTENDEE PAGE and are not pair-checked.
    scripts = sorted(p for p in DEMO_DIR.glob("*.ps1") if p.name[:1].isdigit())
    pages = sorted(DOCS_DIR.glob("*/demo.md"))

    if not scripts:
        print("no demo/NN-*.ps1 found -- is this running from the repo root?")
        return 1

    # --- 1. pairing --------------------------------------------------------
    claimed: dict[str, Path] = {}
    for script in scripts:
        text = script.read_text(encoding="utf-8")
        rel = script.relative_to(REPO)
        match = re.search(r"ATTENDEE PAGE:\s*(\S+)", text)
        if not match:
            findings.append(f"{rel}: no 'ATTENDEE PAGE:' line in the header block")
            continue
        page = match.group(1)
        if page.lower() == "none":
            # Presenter-only: the room watches, so there is nothing to pair with.
            continue
        if not (REPO / page).is_file():
            findings.append(f"{rel}: ATTENDEE PAGE names {page}, which does not exist")
            continue
        if page in claimed:
            findings.append(
                f"{rel}: {page} is already claimed by {claimed[page].relative_to(REPO)}"
            )
        claimed[page] = script

    for page in pages:
        rel = page.relative_to(REPO).as_posix()
        if rel not in claimed:
            findings.append(f"{rel}: no presenter script names this page (CLAUDE.md 7a)")

    # --- 2. paths ----------------------------------------------------------
    sources = [(s, *scan(s.read_text(encoding="utf-8"), False)) for s in scripts]
    sources += [(p, *scan(p.read_text(encoding="utf-8"), True)) for p in pages]

    for source, found, tf_modules in sources:
        rel = source.relative_to(REPO)
        for module in sorted(tf_modules):
            if tracked_tf_files(module):
                continue
            hint = ""
            for candidate in (f"{module}/demo", f"{module}/terraform/demo"):
                if tracked_tf_files(candidate):
                    hint = f"\n      did you mean {candidate} ?"
                    break
            findings.append(
                f"{rel}: runs terraform in {module}/, which holds no tracked .tf "
                f"files{hint}"
            )

    for source, found, _ in sources:
        rel = source.relative_to(REPO)
        for path in sorted(found):
            if (REPO / path).exists() or path in EXPECTED_ABSENT:
                continue
            hint = ""
            # The bug we shipped twice was a missing trailing path segment.
            for candidate in (f"{path}/demo", f"{path}/terraform/demo"):
                if (REPO / candidate).exists():
                    hint = f"\n      did you mean {candidate} ?"
                    break
            findings.append(f"{rel}: references {path}, which does not exist{hint}")

    # --- report ------------------------------------------------------------
    if findings:
        print(f"demo path check: {len(findings)} finding(s)\n")
        for finding in findings:
            print(f"  x {finding}")
        print(
            "\nA demo change touches BOTH the presenter script and the attendee"
            "\npage -- see CLAUDE.md 7a. If a path is created BY the demo, add it"
            "\nto EXPECTED_ABSENT in this script, with a reason."
        )
        return 1

    print(
        f"demo path check: clean "
        f"({len(scripts)} scripts, {len(pages)} pages, all paths resolve)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
