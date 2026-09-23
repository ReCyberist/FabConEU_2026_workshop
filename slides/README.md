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
| `IMAGE` | Main Content : Title + Text Box | A learning that lands better as a picture |
| `DEMO` | Section Break | The "slides have stopped, watch the terminal" slide |

An `IMAGE` entry is `(IMAGE, title, bullets, prompt, notes)`. Give it bullets and the picture takes
the right-hand half; give it an empty list and the picture takes the whole body. It renders a dashed
box holding the **prompt** — write that prompt to be pasted straight into Napkin, Eraser or Claude,
and say what the diagram must *show* and what point it has to *make*, not what it should look like.
Generate the picture, delete the box, paste the picture in its place. The prompt stays in
`content.py` so the next person can see what the picture was meant to say.

**The morning leads into demos, it does not duplicate them.** Command slides were removed from every
module that has a `demo/` script behind it — the commands are typed live and written up on the site,
and a slide was only ever a third copy waiting to drift. `Check your toolchain` is the exception: the
room types that one themselves.

Every entry's last element is the **speaker note**. Keep them honest and specific — they
carry the timing warnings and the "say this out loud" prompts.

## The four slides that aren't in `DECK`

`build.py` writes these around the body, in this order:

| # | Slide | Where its content lives |
|---|-------|-------------------------|
| 1 | **Walk-in** — up from doors open until 09:00 | `WALK_IN_*` in [`content.py`](content.py) |
| 2 | Conference splash | the template's own layout |
| 3 | Title slide | `TITLE_LINES` / `PRESENTERS` in [`build.py`](build.py) |
| last | Rate this session | the template's own layout |

The **walk-in slide comes before the conference splash on purpose**: it is what the room reads
while it fills up, and the only thing on it an early arrival can act on is the site address. That
address must match `site_url` in [`mkdocs.yml`](../mkdocs.yml) exactly — the path is case
sensitive, so `FabConEU_2026_workshop` is not `fabconeu_2026_workshop`.

It is the one slide `build.py` lays out by hand rather than through a layout placeholder: rainbow
bands full-bleed, the text on a solid panel over them (a rainbow is a fine thing to walk into and a
hopeless thing to read 15pt text off), and a row of dashed **image placeholders** from
`WALK_IN_IMAGES`. Delete a box and paste a picture in its place; add or remove entries and the row
re-spaces itself. The bands stop at 92.7% of the slide height so the conference footer band
survives underneath.

A `DEMO` entry is `(DEMO, title, quip, lines, notes)`, and **there is one before every demo**. The
quip is the one place humour belongs on a demo slide; the lines under it stay plain, because their
job is to tell the room whether to follow along or sit back. For a presenter-only demo — one that
needs two laptops, so there is nothing an attendee can follow — the slide must say *sit back*, and
the script declares `ATTENDEE PAGE: none` (`CLAUDE.md` §7a).

**`URL_STRIPS`** in `content.py` maps a slide title to `(lead line, address)` and `build.py` stamps
a link strip under that slide's content — no per-slide markup. Two use it today: *What today is*
points at the site root, and *The run of the day* points at the agenda page.

## Conventions

- Commands are **PowerShell**, matching [`CLAUDE.md`](../CLAUDE.md) §4, and are copied from
  the module READMEs — not invented. If a command changes there, change it here.
- **A command slide mirrors its demo.** Every `CMD` slide in a taught module is the same
  commands, in the same order, as the matching [`demo/`](../demo/) script and its attendee page
  (`CLAUDE.md` §7a). Name the script and the regions in the speaker note so the next person can
  check. Three places now, not two — the script, the page, and the slide.
- **Times come from [`agenda/agenda.md`](../agenda/agenda.md)** — the single source for the
  clock, mirrored by the site's session clocks (`includes/clock-*.md`). Change them there first,
  then here. The venue fixes the break and lunch anchors; only the teaching flexes.
- Signposts on the slide, detail on the docs site. Don't grow the bullets.
- **After building, look at it.** The deck is generated and gitignored, so nothing else will
  ever show you that a slide overflowed or that a command went stale. Export the slides you
  changed to PNG and eyeball them:

```powershell
$deck = "$PWD\FabConEU2026-Workshop-Deck.pptx"
$out  = "$env:TEMP\deck-check"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$app  = New-Object -ComObject PowerPoint.Application
$pres = $app.Presentations.Open($deck, -1, 0, 0)   # read-only, no window
foreach ($n in 1, 7, 28, 33, 44) {                 # the slides you touched
    $pres.Slides.Item($n).Export((Join-Path $out ("slide{0:D2}.png" -f $n)), "PNG", 1400, 788)
}
$pres.Close(); $app.Quit()
Invoke-Item $out
```

  Check three things: nothing overflows its placeholder, no line wraps that shouldn't, and every
  command still matches its `demo/` script.
