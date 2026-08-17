# Slides — the workshop deck, as code

The deck is **generated**, not hand-edited. Same rule as the rest of the repo: if the
answer to "how do I change this" is "click here", it's a bug.

- [`content.py`](content.py) — every slide's title, body and speaker notes. **Edit this.**
- [`build.py`](build.py) — maps that content onto the official FabCon speaker template's
  layouts and writes the `.pptx`.

## Build it

```powershell
pip install python-pptx

# build.py <template.pptx> <output.pptx>
python slides/build.py "EMFCC26_SpeakerPPT_TemplateA.pptx" "FabConEU2026-Workshop-Deck.pptx"
```

## Why no .pptx in the repo

Neither the conference template nor the generated deck is committed — they're large
binaries that can't be diffed or merged, and the template isn't ours to redistribute.
`*.pptx` is in [`.gitignore`](../.gitignore). Keep the template in the repo root (ignored)
and rebuild the deck whenever `content.py` changes.

## Slide kinds

| Kind | Template layout | Use for |
|------|-----------------|---------|
| `SECTION` | Section Break | Module dividers — big white title, gold time strapline |
| `CONTENT` | Main Content : Title + Text Box | Light background, bulleted signposts |
| `QUOTE` | Main Content : Title + Text Box | Light background, large text, no bullets |
| `DUAL` | Title + Dual Text Box | Light background, two labelled columns |
| `DARK` | Dark BKG : Title + Dual Text Box | Dark background, two labelled columns — for emphasis |
| `CMD` | 1_Main Content : Title + Text Box | Dark background, Courier New — command reference |

Every entry's last element is the **speaker note**. Keep them honest and specific — they
carry the timing warnings and the "say this out loud" prompts.

## Conventions

- Commands are **PowerShell**, matching [`CLAUDE.md`](../CLAUDE.md) §4, and are copied from
  the module READMEs — not invented. If a command changes there, change it here.
- Signposts on the slide, detail on the docs site. Don't grow the bullets.
- After building, sanity-check it:

```powershell
python /mnt/skills/public/pptx/scripts/office/validate.py FabConEU2026-Workshop-Deck.pptx --original "EMFCC26_SpeakerPPT_TemplateA.pptx"
```
