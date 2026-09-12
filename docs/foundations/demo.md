# Source control demo

--8<-- "includes/clock-morning-1.md"

This is the shortest possible version of the workflow we use all day: make one small change in
your fork, review it, commit it on a branch, push it, and open a pull request. Later, the file you
change will be Terraform or T-SQL; the workflow stays the same.

!!! note "Follow along — or just watch"
	You need a local clone of **your fork** and the **GitHub CLI** signed in. See
	[Prerequisites](../setup/prerequisites.md) and [Source control for databases](source-control.md).

!!! note "Run these commands in PowerShell"
	Every command on this page is PowerShell. If your prompt is bash or zsh, start PowerShell
	first:

	```powershell
	pwsh
	```

	The prompt changes to `PS>`. PowerShell 7 runs on Windows, macOS and Linux, and every
	command on this page works the same on all three.

## What you'll do

Create a branch, add one harmless note to the repository, commit it with a clear message, push the
branch to your fork, and open a pull request against `main`.

## The concept

- A **branch** isolates your work from `main`.
- A **commit** is the smallest reviewable unit of change.
- A **pull request** is where review, checks and discussion happen before anything merges.

## Run it

1. In the repository root folder, confirm that `origin` points to **your** fork and that your
   working tree is clean.

	```powershell
	git remote -v
	git status
	```

	`origin` points at your GitHub account, and `git status` prints nothing.

2. In the repository root folder, create a branch for the demo work.

	```powershell
	git switch -c demo/source-control
	git branch --show-current
	```

	The second command prints `demo/source-control`.

3. In the `notes` folder, create a new file called `fabcon.md` and add something you have learnt so far.

	```powershell
	New-Item -Path notes/fabcon.md -ItemType File
	code notes/fabcon.md
	```

	Add your notes:

	```markdown
	# Fabcon 2026 - Best Workshop so far!

	So far I have learnt:
	- Jess loves breakfast
	- Rob has a beard
	```

	Save the file.

4. In the repository root folder, confirm that Git sees the new file, then stage it and review the
   staged diff.

	```powershell
	git status --short
	git add notes/fabcon.md
	git diff --cached -- notes/fabcon.md
	```

	The first command shows `?? notes/fabcon.md`. The staged diff then shows `notes/fabcon.md` as a
	new file with the lines you added.

5. In the repository root folder, confirm that only the new file is queued for commit.

	```powershell
	git status
	```

	The status output shows:

	```text
	On branch demo/source-control
	Changes to be committed:
	(use "git restore --staged <file>..." to unstage)
	        new file:   notes/fabcon.md
	```

6. In the repository root folder, commit the change with a message that says what changed.

	```powershell
	git commit -m "docs: add FabCon source control demo note"
	```

	Git prints a new commit ID and reports `1 file changed`. Because this is a new file, it also
	reports `create mode` for `notes/fabcon.md`.

7. In the repository root folder, push the branch to your fork.

	```powershell
	git push --set-upstream origin demo/source-control
	```

	Git reports that a new branch was pushed and that `demo/source-control` now tracks `origin/demo/source-control`.

8. In the repository root folder, open a pull request from your branch to `main`.

	```powershell
	gh pr create --fill --base main
	```

	The command creates the pull request and prints the pull request URL.

9. In the repository root folder, inspect the pull request details from the command line.

	```powershell
	gh pr view
	```

	You see the pull request title, branch names, state and URL.

## Checkpoint

You now have one branch, one commit on that branch, and one pull request against `main`. The
change is small, reviewable and isolated from the default branch.

## Gotchas

- If `git status` is not empty at the start, do not mix this demo with unrelated work.
  Commit or stash your own changes first.
- If `gh pr create` says there are no commits to compare, check that you are still on
  `demo/source-control` and that the commit succeeded.
- Do not stage `*.tfvars`, `*.tfstate`, `.env`, publish profiles with secrets, or any other local
  credentials. The repo's ignore rules exist to keep those out.

## What's next

Next: [Azure SQL (Terraform)](../infra/azure-sql.md).
