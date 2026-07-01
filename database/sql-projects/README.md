# SQL Projects — `.sqlproj` / DACPAC (content focus)

The **taught path** for database-as-code. An SDK-style SQL project defines the canonical
sample schema; the pipeline builds a DACPAC and deploys it with SqlPackage.

To build here:
- `.sqlproj` (Microsoft.Build.Sql SDK-style) with the sample schema objects.
- Build → DACPAC in CI (see [`../../infra/pipelines/github-actions/`](../../infra/pipelines/github-actions/)).
- Publish profiles for Azure SQL and Fabric SQL targets.

Note any schema object that Fabric SQL treats differently so the attendee content can
explain it.
