# Run this site on your own laptop

The repository you cloned **is** this website. The pages you are reading are Markdown files in its
`docs/` folder, built by [MkDocs Material](https://squidfunk.github.io/mkdocs-material/). If you
want your own copy — to read on the train home, or after the hosted site comes down — you can serve
it from your clone. This needs **Python**, and nothing to do with Azure: it only builds and serves
the pages.

You already have the code from the [Prerequisites](../setup/prerequisites.md) page. If you have not
cloned the repository yet, do that first.

1. Install **[Python](https://www.python.org/downloads/)**, version **3.9 or later**, if you do not
   have it:

    === "Windows"

        ```powershell
        winget install --exact --id Python.Python.3.12
        ```

    === "macOS"

        ```bash
        brew install python
        ```

    === "Debian & Ubuntu"

        ```bash
        sudo apt install python3 python3-pip python3-venv
        ```

    Close and reopen your terminal, then confirm it is installed:

    ```powershell
    python --version
    ```

    The output starts with `Python 3.`, for example `Python 3.12.0`.

2. In the `FabConEU_2026_workshop` folder you cloned, install the site's tools:

    ```powershell
    pip install -r requirements.txt
    ```

    pip installs MkDocs Material and its dependencies. The last line reads `Successfully installed`.

3. Start the site:

    ```powershell
    mkdocs serve
    ```

    The output ends with `Serving on http://127.0.0.1:8000/`. Open that address in your browser and
    the site runs on your own machine. Leave the command running, and stop it with `Ctrl+C` when you
    are done.
