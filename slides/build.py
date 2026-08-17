#!/usr/bin/env python3
"""Build the FabCon Europe 2026 workshop deck on the official speaker template."""
import copy
import sys
from pptx import Presentation
from pptx.util import Pt
from pptx.dml.color import RGBColor
from pptx.oxml.ns import qn

from content import DECK, SECTION, CONTENT, DUAL, DARK, CMD, QUOTE

TEMPLATE = sys.argv[1] if len(sys.argv) > 1 else "template.pptx"
OUT = sys.argv[2] if len(sys.argv) > 2 else "FabConEU2026-Workshop-Deck.pptx"

TITLE_LINES = ["Azure SQL or Fabric SQL:", "Infrastructure and Databases as Code"]
PRESENTERS = "JESS POMFRET & ROB SEWELL"
PRESENTER_SUB = "MICROSOFT MVPs  ·  FULL-DAY WORKSHOP  ·  FABCON EUROPE 2026"

prs = Presentation(TEMPLATE)
slides = prs.slides

L_SPLASH = prs.slide_masters[0].slide_layouts[0]
L_SECTION = prs.slide_masters[1].slide_layouts[0]
L_CONTENT = prs.slide_masters[2].slide_layouts[0]
L_CONTENT2 = prs.slide_masters[2].slide_layouts[1]
L_DUAL = prs.slide_masters[2].slide_layouts[2]
L_DARK = prs.slide_masters[2].slide_layouts[3]
L_RATE = prs.slide_masters[3].slide_layouts[0]

# ── capture the template artwork we want to reuse, before wiping the slides ───
tmpl = list(slides)
title_slide_shapes = [copy.deepcopy(sh._element) for sh in tmpl[2].shapes]
section_title_xml = next(
    copy.deepcopy(sh._element)
    for sh in tmpl[3].shapes
    if sh.has_text_frame and sh.text_frame.text.strip() == "Section title"
)

# ── wipe every template slide; we rebuild from layouts ───────────────────────
sld_id_lst = slides._sldIdLst
for el in list(sld_id_lst):
    prs.part.drop_rel(el.rId)
    sld_id_lst.remove(el)


# ── helpers ───────────────────────────────────────────────────────────────────
def _no_bullet(p):
    pPr = p._p.get_or_add_pPr()
    for tag in ("a:buChar", "a:buAutoNum", "a:buNone"):
        for e in pPr.findall(qn(tag)):
            pPr.remove(e)
    pPr.append(pPr.makeelement(qn("a:buNone"), {}))


def fill(ph, lines, mono=False, header_first=False, size=17):
    tf = ph.text_frame
    tf.clear()
    tf.word_wrap = True
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        run = p.add_run()
        run.text = line if line else " "
        if mono:
            run.font.name = "Courier New"
            run.font.size = Pt(14)
            _no_bullet(p)
        else:
            run.font.size = Pt(size)
            if not line:
                _no_bullet(p)
            elif header_first and i == 0:
                run.font.bold = True
                run.font.size = Pt(14)
                _no_bullet(p)


def by_idx(slide):
    return {p.placeholder_format.idx: p for p in slide.placeholders}


def strip_placeholders(slide):
    for ph in list(slide.placeholders):
        ph._element.getparent().remove(ph._element)


def set_title(shape, text):
    tf = shape.text_frame
    tf.clear()
    tf.paragraphs[0].add_run().text = text


def retext(shape, lines):
    """Replace a shape's text while keeping the template's own run formatting."""
    txBody = shape.text_frame._txBody
    ps = txBody.findall(qn("a:p"))
    proto = copy.deepcopy(ps[0])
    if proto.find(qn("a:r")) is None:
        raise ValueError("prototype paragraph has no run to clone")
    for p in ps:
        txBody.remove(p)
    for line in lines:
        newp = copy.deepcopy(proto)
        runs = newp.findall(qn("a:r"))
        for extra in runs[1:]:
            newp.remove(extra)
        runs[0].find(qn("a:t")).text = line
        txBody.append(newp)


# ── 1. splash ─────────────────────────────────────────────────────────────────
slides.add_slide(L_SPLASH)

# ── 2. title slide (template slide 3's shapes, retexted) ─────────────────────
s = slides.add_slide(L_SECTION)
strip_placeholders(s)
for el in title_slide_shapes:
    s.shapes._spTree.append(copy.deepcopy(el))
for sh in s.shapes:
    if not sh.has_text_frame:
        continue
    t = sh.text_frame.text.strip()
    if t.startswith("PRESENTATION TITLE"):
        retext(sh, TITLE_LINES)
    elif t == "YOUR NAME":
        retext(sh, [PRESENTERS])
    elif t.startswith("TITLE, COMPANY"):
        retext(sh, [PRESENTER_SUB])
s.notes_slide.notes_text_frame.text = (
    "Doors open. Names, then straight into why the day exists. "
    "The 'do not record' notice is the template's — remove it if you're happy to be recorded."
)

# ── 3. the body of the deck ───────────────────────────────────────────────────
for entry in DECK:
    kind = entry[0]

    if kind == SECTION:
        _, title, strap, _unused, notes = entry
        s = slides.add_slide(L_SECTION)
        # the template's own title shape sits off-slide, flagged decorative —
        # keep it so screen readers still announce the section
        s.shapes._spTree.append(copy.deepcopy(section_title_xml))
        set_title(s.shapes[-1], title)
        ph = by_idx(s)
        tf = ph[10].text_frame
        tf.clear()
        tf.word_wrap = True
        p1 = tf.paragraphs[0]
        r1 = p1.add_run()
        r1.text = title
        r1.font.size = Pt(40)
        r1.font.bold = True
        r1.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        _no_bullet(p1)
        p2 = tf.add_paragraph()
        r2 = p2.add_run()
        r2.text = strap
        r2.font.size = Pt(18)
        _no_bullet(p2)

    elif kind == CONTENT:
        _, title, bullets, notes = entry
        s = slides.add_slide(L_CONTENT)
        ph = by_idx(s)
        set_title(ph[0], title)
        fill(ph[11], bullets, size=20)

    elif kind == QUOTE:
        _, title, lines, notes = entry
        s = slides.add_slide(L_CONTENT)
        ph = by_idx(s)
        set_title(ph[0], title)
        tf = ph[11].text_frame
        tf.clear()
        tf.word_wrap = True
        for i, line in enumerate(lines):
            p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
            r = p.add_run()
            r.text = line if line else " "
            r.font.size = Pt(26)
            _no_bullet(p)

    elif kind == CMD:
        _, title, lines, notes = entry
        s = slides.add_slide(L_CONTENT2)
        ph = by_idx(s)
        set_title(ph[0], title)
        fill(ph[11], lines, mono=True)

    elif kind in (DUAL, DARK):
        _, title, left, right, notes = entry
        s = slides.add_slide(L_DUAL if kind == DUAL else L_DARK)
        ph = by_idx(s)
        set_title(ph[0], title)
        fill(ph[11], left, header_first=True, size=16)
        fill(ph[12], right, header_first=True, size=16)

    else:
        raise ValueError(kind)

    if notes:
        s.notes_slide.notes_text_frame.text = notes

# ── 4. rate this session ──────────────────────────────────────────────────────
slides.add_slide(L_RATE)

prs.save(OUT)
print(f"wrote {OUT}: {len(list(prs.slides))} slides")
