<!--
  Site-wide glossary. Auto-appended to EVERY page by pymdownx.snippets (see mkdocs.yml),
  so a term defined here gets a hover tooltip wherever it appears — no per-page markup.

  Two kinds of entry live here:
    1. Acronyms and product terms — expanded on hover for anyone skimming.
    2. British idioms and informal words — given a straight-English translation, so the
       discussion prose can keep its flavour without leaving anyone behind.

  RULES
    - Keep it short and deliberate. Every entry applies to EVERY occurrence on EVERY page,
      including inside numbered steps, so only add words we are happy to see underlined there.
    - Matching is case-sensitive and exact. Add both "Kit" and "kit" if you need both.
    - A tooltip is a nicety, never the meaning. Tooltips do not appear on touch devices,
      so the sentence must still read correctly with the tooltip removed. (CLAUDE.md §5)
-->

*[IaC]: Infrastructure as Code — describing your cloud resources in files you keep in source control
*[CI]: Continuous Integration — automatically building and checking your code on every change
*[CD]: Continuous Deployment — automatically releasing those checked changes
*[CI/CD]: Continuous Integration and Continuous Deployment — automatically building, checking and releasing your changes
*[DACPAC]: Data-tier Application Package — the single file a SQL project builds into, containing your whole schema
*[SQL project]: A project file that holds your database schema as code and builds it into a DACPAC
*[drift]: The gap that opens up when someone changes a deployed resource by hand, so it no longer matches the code
*[teardown]: Deleting the resources you created, so they stop costing money

*[kit]: British informal — equipment. Here it means your own laptop, subscription and tools
*[faff]: British informal — fiddly, tedious work
*[sorted]: British informal — done, finished, working
*[carries the can]: British informal — takes the blame, is held responsible
*[football]: This is proper football, Association Football, known also as soccer by some.  British informal — soccer
*[a good deal more]: much more

*[OIDC]: OpenID Connect — it lets GitHub Actions sign in to Azure without you storing a password or secret
*[F-SKU]: The paid capacity sizes for Microsoft Fabric (F2, F4, F8 and so on). They bill continuously until paused or deleted
*[CLI]: Command-Line Interface — a tool you use by typing commands rather than clicking
*[SDK]: Software Development Kit — the tools needed to build and run code
*[Contributor]: The Azure role that allows creating and deleting resources, but not granting access to others

*[winget]: The package manager built into Windows. It installs a tool from one command instead of a download-and-click
*[Homebrew]: The package manager most people use on macOS. It installs a tool from one command instead of a download-and-click

*[PR]: Pull request — a proposed change to a repository, reviewed and discussed before it is merged
*[YAML]: A plain-text file format, used here to describe pipelines and configuration
