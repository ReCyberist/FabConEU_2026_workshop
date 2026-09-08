#!/usr/bin/env python3
"""Build the FabCon Europe 2026 workshop deck on the official speaker template."""
import copy
import sys
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.dml import MSO_LINE_DASH_STYLE
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.oxml.ns import qn

from content import (
    DECK, SECTION, CONTENT, DUAL, DARK, CMD, QUOTE, IMAGE, DEMO,
    WALK_IN_TITLE, WALK_IN_URL, WALK_IN_LINES, WALK_IN_NOTES, WALK_IN_IMAGES,
    URL_STRIPS,
)

TEMPLATE = sys.argv[1] if len(sys.argv) > 1 else "template.pptx"
OUT = sys.argv[2] if len(sys.argv) > 2 else "FabConEU2026-Workshop-Deck.pptx"

TITLE_LINES = ["Azure SQL or Fabric SQL:", "Infrastructure and Databases as Code"]
PRESENTERS = "JESS POMFRET & ROB SEWELL"
PRESENTER_SUB = "MICROSOFT MVPs  ·  FULL-DAY WORKSHOP  ·  FABCON EUROPE 2026"

# Sampled from a PNG export of the template — the FabCon palette lives in the
# layouts, not the theme, so there is nothing to look it up in.
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
GOLD = RGBColor(0xBC, 0xA0, 0x45)   # the section-break strapline
GREEN = RGBColor(0x01, 0x3F, 0x34)  # the title colour on light slides
# The body placeholder on the light content layout, measured from the template.
BODY_L, BODY_T, BODY_W, BODY_H = Inches(0.81), Inches(1.86), Inches(11.75), Inches(4.63)
RAINBOW = [
    (0xE4, 0x03, 0x03), (0xFF, 0x8C, 0x00), (0xFF, 0xED, 0x00),
    (0x00, 0x80, 0x26), (0x00, 0x4D, 0xFF), (0x75, 0x07, 0x87),
]

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


def image_box(slide, x, y, w, h, prompt):
    """A dashed box standing in for artwork, carrying the prompt that will make it.

    Delete the box, generate the picture, paste it in the same place. The prompt stays in
    content.py, so the next person can see what the picture was supposed to say.
    """
    box = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, x, y, w, h)
    box.fill.solid()
    box.fill.fore_color.rgb = RGBColor(0xF4, 0xF6, 0xF5)
    box.line.color.rgb = GREEN
    box.line.width = Pt(1.25)
    box.line.dash_style = MSO_LINE_DASH_STYLE.DASH
    box.shadow.inherit = False

    tf = box.text_frame
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = Inches(0.28)
    tf.margin_top = tf.margin_bottom = Inches(0.22)
    tf.vertical_anchor = MSO_ANCHOR.TOP
    for i, (text, size, bold, colour) in enumerate((
        ("IMAGE — prompt for Napkin / Eraser / Claude", 10, True, GREEN),
        ("", 6, False, GREEN),
        (prompt, 11, False, RGBColor(0x33, 0x33, 0x33)),
    )):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = PP_ALIGN.LEFT
        run = p.add_run()
        run.text = text if text else " "
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.color.rgb = colour
        _no_bullet(p)


def url_strip(slide, lead, url):
    """A link strip beneath a slide's content, for the people who did not write the
    address down at the door."""
    box = slide.shapes.add_textbox(Inches(0.92), Inches(5.75), Inches(11.4), Inches(1.0))
    tf = box.text_frame
    tf.word_wrap = True
    tf.margin_left = 0  # so the strip sits on the title's left edge, not inset from it
    for i, (text, size, bold) in enumerate((
        (lead, 15, False),
        (url, 22, True),
    )):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        run = p.add_run()
        run.text = text
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.color.rgb = GREEN
        _no_bullet(p)


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


# ── 1. walk-in slide ─────────────────────────────────────────────────────────
# What the room reads while it fills up, so it sits ahead of the conference
# splash. Rainbow behind it: the day opens by asking people to be decent to each
# other, and the first slide may as well say so before we do.
s = slides.add_slide(L_SECTION)
strip_placeholders(s)  # this one is laid out by hand, not by the layout
# the template's own title shape sits off-slide, flagged decorative — keep it so
# screen readers still announce the slide
s.shapes._spTree.append(copy.deepcopy(section_title_xml))
set_title(s.shapes[-1], WALK_IN_TITLE)


def _flat(shape):
    """No outline, no shadow — these are flat blocks of colour, not objects."""
    shape.line.fill.background()
    shape.shadow.inherit = False
    return shape


_band_bottom = int(prs.slide_height * 0.927)  # stop above the conference footer band
for _i, _rgb in enumerate(RAINBOW):
    _top = int(_band_bottom * _i / len(RAINBOW))
    _bot = int(_band_bottom * (_i + 1) / len(RAINBOW))
    _band = _flat(s.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, _top, prs.slide_width, _bot - _top))
    _band.fill.solid()
    _band.fill.fore_color.rgb = RGBColor(*_rgb)

# A rainbow is a lovely thing to walk into and a hopeless thing to read 15pt text
# off, so the words sit on a solid panel and the colour becomes a border.
panel = _flat(s.shapes.add_shape(
    MSO_SHAPE.RECTANGLE, Inches(0.45), Inches(0.65), Inches(12.43), Inches(3.95)))
panel.fill.solid()
panel.fill.fore_color.rgb = GREEN

tf = panel.text_frame
tf.word_wrap = True
tf.margin_left = Inches(0.5)
tf.margin_right = Inches(0.5)
tf.margin_top = Inches(0.35)
tf.margin_bottom = Inches(0.2)


def _walk_in_line(first, text, size, colour, bold=False):
    p = tf.paragraphs[0] if first else tf.add_paragraph()
    p.alignment = PP_ALIGN.LEFT  # an autoshape centres its first paragraph by default
    run = p.add_run()
    run.text = text if text else " "
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = colour
    _no_bullet(p)


# gold on the URL only: it is the one thing on the slide somebody has to act on
_walk_in_line(True, WALK_IN_TITLE, 34, WHITE, bold=True)
_walk_in_line(False, WALK_IN_URL, 26, GOLD, bold=True)
for _line in [""] + WALK_IN_LINES:
    _walk_in_line(False, _line, 15, WHITE)

# Dashed boxes to drop pictures into. Delete one and paste a picture in its place.
_n = len(WALK_IN_IMAGES)
_left, _right, _gap = Inches(0.45), Inches(12.88), Inches(0.21)
_box_w = int(((_right - _left) - _gap * (_n - 1)) / _n)
for _i, _label in enumerate(WALK_IN_IMAGES):
    _box = s.shapes.add_shape(
        MSO_SHAPE.RECTANGLE, _left + _i * (_box_w + _gap), Inches(4.85), _box_w, Inches(1.85))
    _box.fill.solid()
    _box.fill.fore_color.rgb = WHITE
    _box.line.color.rgb = GREEN
    _box.line.width = Pt(1.5)
    _box.line.dash_style = MSO_LINE_DASH_STYLE.DASH
    _box.shadow.inherit = False
    _t = _box.text_frame
    _t.word_wrap = True
    _t.vertical_anchor = MSO_ANCHOR.MIDDLE
    _p = _t.paragraphs[0]
    _p.alignment = PP_ALIGN.CENTER
    _r = _p.add_run()
    _r.text = _label
    _r.font.size = Pt(14)
    _r.font.bold = True
    _r.font.color.rgb = GREEN
    _no_bullet(_p)

s.notes_slide.notes_text_frame.text = WALK_IN_NOTES

# ── 2. splash ─────────────────────────────────────────────────────────────────
slides.add_slide(L_SPLASH)

# ── 3. title slide (template slide 3's shapes, retexted) ─────────────────────
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

# ── 4. the body of the deck ───────────────────────────────────────────────────
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

    elif kind == DEMO:
        _, title, quip, lines, notes = entry
        s = slides.add_slide(L_SECTION)
        s.shapes._spTree.append(copy.deepcopy(section_title_xml))
        set_title(s.shapes[-1], title)
        tf = by_idx(s)[10].text_frame
        tf.clear()
        tf.word_wrap = True
        for i, (text, size, colour, bold) in enumerate(
            [(title, 40, WHITE, True), (quip, 22, GOLD, False), ("", 12, WHITE, False)]
            + [(l, 16, WHITE, False) for l in lines]
        ):
            p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
            p.alignment = PP_ALIGN.LEFT
            run = p.add_run()
            run.text = text if text else " "
            run.font.size = Pt(size)
            run.font.bold = bold
            run.font.color.rgb = colour
            _no_bullet(p)

    elif kind == IMAGE:
        _, title, bullets, prompt, notes = entry
        s = slides.add_slide(L_CONTENT)
        ph = by_idx(s)
        set_title(ph[0], title)
        # The layout's body box is L=0.81 T=1.86 W=11.75 H=4.63. A placeholder inherits
        # its position, and writing one dimension drops the other three to zero — so when
        # we narrow it for the picture, all four go in explicitly.
        if bullets:
            body = ph[11]
            body.left, body.top = BODY_L, BODY_T
            body.width, body.height = Inches(5.9), BODY_H
            fill(body, bullets, size=17)
            image_box(s, Inches(7.06), BODY_T, Inches(5.46), BODY_H, prompt)
        else:
            ph[11]._element.getparent().remove(ph[11]._element)
            image_box(s, BODY_L, BODY_T, BODY_W, BODY_H, prompt)

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

    strip = URL_STRIPS.get(entry[1])
    if strip:
        url_strip(s, *strip)

    if notes:
        s.notes_slide.notes_text_frame.text = notes

# ── 5. rate this session ──────────────────────────────────────────────────────
slides.add_slide(L_RATE)

prs.save(OUT)
print(f"wrote {OUT}: {len(list(prs.slides))} slides")
