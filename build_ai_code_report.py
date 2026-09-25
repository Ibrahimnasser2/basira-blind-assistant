# -*- coding: utf-8 -*-
"""
Build a FORMAL Word report for the Basira AI Flutter app, focused on the
AI / ML model code only.

Bidi rules applied:
  * Arabic or mixed Arabic+English paragraphs  -> RTL (w:bidi)
  * Pure English paragraphs (e.g. code blocks) -> LTR
"""

import re
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor


ROOT = Path(__file__).parent
ARABIC_RE = re.compile(r"[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]")
LATIN_RE = re.compile(r"[A-Za-z]")


def _split_bidi_segments(text: str):
    """Split *text* into ordered (segment, direction) pairs.

    Direction is either ``'rtl'`` (Arabic) or ``'ltr'`` (Latin). Neutral
    characters (digits, spaces, punctuation) attach to the previously seen
    strong direction so Word renders them on the correct side.
    """
    if not text:
        return []
    out: list[tuple[str, str]] = []
    buf: list[str] = []
    cur: str | None = None
    for ch in text:
        if ARABIC_RE.match(ch):
            d = "rtl"
        elif LATIN_RE.match(ch):
            d = "ltr"
        else:
            d = None
        if d is None:
            buf.append(ch)
            continue
        if cur is None:
            cur = d
            buf.append(ch)
        elif d == cur:
            buf.append(ch)
        else:
            out.append(("".join(buf), cur))
            buf = [ch]
            cur = d
    if buf:
        out.append(("".join(buf), cur or "rtl"))
    return out


# ---------------------------------------------------------------------------
# Low-level helpers
# ---------------------------------------------------------------------------
def _set_rtl_paragraph(paragraph) -> None:
    pPr = paragraph._p.get_or_add_pPr()
    bidi = pPr.find(qn("w:bidi"))
    if bidi is None:
        bidi = OxmlElement("w:bidi")
        pPr.append(bidi)
    bidi.set(qn("w:val"), "1")


def _mark_run_rtl(run) -> None:
    rPr = run._element.get_or_add_rPr()
    rtl = rPr.find(qn("w:rtl"))
    if rtl is None:
        rtl = OxmlElement("w:rtl")
        rPr.append(rtl)
    rtl.set(qn("w:val"), "1")


def _set_run_fonts(run, latin: str, cs: str) -> None:
    rPr = run._element.get_or_add_rPr()
    rFonts = rPr.find(qn("w:rFonts"))
    if rFonts is None:
        rFonts = OxmlElement("w:rFonts")
        rPr.append(rFonts)
    rFonts.set(qn("w:ascii"), latin)
    rFonts.set(qn("w:hAnsi"), latin)
    rFonts.set(qn("w:cs"), cs)


def _shade_paragraph(paragraph, fill_hex: str) -> None:
    pPr = paragraph._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill_hex)
    pPr.append(shd)


# ---------------------------------------------------------------------------
# High-level paragraph helpers
# ---------------------------------------------------------------------------
def _add_bidi_runs(paragraph, text: str, *, bold: bool, size: int,
                   color: RGBColor | None) -> None:
    """Add the Arabic/mixed text as a single RTL-marked run so Word's
    Unicode bidi algorithm handles embedded Latin substrings correctly
    (including spaces, digits, and punctuation between scripts)."""
    run = paragraph.add_run(text)
    run.bold = bold
    run.font.size = Pt(size)
    if color is not None:
        run.font.color.rgb = color
    _set_run_fonts(run, "Calibri", "Arial")
    _mark_run_rtl(run)


def add_arabic(doc: Document, text: str, *, bold: bool = False,
               size: int = 12, color: RGBColor | None = None,
               align=WD_ALIGN_PARAGRAPH.JUSTIFY) -> None:
    """Arabic / mixed paragraph -> RTL with per-segment direction marks."""
    p = doc.add_paragraph()
    p.alignment = align
    _set_rtl_paragraph(p)
    _add_bidi_runs(p, text, bold=bold, size=size, color=color)


def add_heading_ar(doc: Document, text: str, *, level: int = 1) -> None:
    sizes = {0: 22, 1: 16, 2: 13}
    colors = {
        0: RGBColor(0x1F, 0x49, 0x7D),
        1: RGBColor(0x1F, 0x49, 0x7D),
        2: RGBColor(0x2E, 0x74, 0xB5),
    }
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    _set_rtl_paragraph(p)
    _add_bidi_runs(
        p, text, bold=True,
        size=sizes.get(level, 12),
        color=colors.get(level, RGBColor(0, 0, 0)),
    )


def add_code_block(doc: Document, code: str) -> None:
    """Code block -> LTR, monospace, light gray background."""
    for line in code.splitlines() or [""]:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.left_indent = Cm(0.2)
        _shade_paragraph(p, "F4F4F4")
        run = p.add_run(line if line else " ")
        run.font.name = "Consolas"
        run.font.size = Pt(9)
        _set_run_fonts(run, "Consolas", "Consolas")


def add_file_caption(doc: Document, relpath: str) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    run = p.add_run(f"// File: {relpath}")
    run.italic = True
    run.font.name = "Consolas"
    run.font.size = Pt(9)
    run.font.color.rgb = RGBColor(0x70, 0x70, 0x70)


# ---------------------------------------------------------------------------
# Report content
# ---------------------------------------------------------------------------
SECTIONS = [
    {
        "title": "أولاً: نموذج التعرف على العملة المصرية (TFLite – YOLOv8)",
        "tech": "TensorFlow Lite • YOLOv8 • معالجة صور محلية",
        "purpose": (
            "اكتشاف فئات العملة المصرية الورقية (5، 10، 20، 50، 100، 200 جنيه) "
            "محلياً داخل الجهاز دون الحاجة لاتصال بالإنترنت."
        ),
        "summary": (
            "يتم تحميل نموذج YOLOv8 المُصدَّر بصيغة TFLite من مجلد assets، "
            "ثم تُلتقط صور دورية من الكاميرا، يُعاد ضبط أبعادها وتُطبيع قيم "
            "البكسلات، ثم تُمرَّر إلى المفسّر (Interpreter). يتم استخراج "
            "أعلى احتمال من مخرجات الكاشف وتحويل الفئة إلى مسمى عربي يُنطق "
            "صوتياً عبر TTS."
        ),
        "file": ROOT / "lib/features/currency_detection/currency_screen.dart",
    },
    {
        "title": "ثانياً: خدمة Gemini للنماذج متعددة الوسائط",
        "tech": "Google Generative AI • Gemini 1.5 Flash",
        "purpose": (
            "وصف الصور، استخراج النصوص العربية والإنجليزية، وترجمة "
            "التسميات الإنجليزية إلى العربية باستخدام نموذج لغوي متعدد "
            "الوسائط."
        ),
        "summary": (
            "تستقبل الخدمة ملف الصورة وموجّه نصي (Prompt) ثم ترسلهما إلى "
            "نموذج Gemini 1.5 Flash عبر حزمة google_generative_ai، وتُعيد "
            "النتيجة النصية للعرض والنطق."
        ),
        "file": ROOT / "lib/core/services/gemini_service.dart",
    },
    {
        "title": "ثالثاً: اكتشاف الأشياء (Google ML Kit)",
        "tech": "ML Kit Object Detection • ML Kit Image Labeling",
        "purpose": (
            "تحديد الأشياء الموجودة أمام المستخدم وتسميتها بالعربية بشكل "
            "لحظي."
        ),
        "summary": (
            "يستخدم نموذجي Object Detection و Image Labeling من Google ML "
            "Kit، مع طبقة قاموس داخلي لترجمة التسميات الشائعة إلى العربية، "
            "وآلية احتياطية للترجمة الديناميكية للتسميات غير المعروفة."
        ),
        "file": ROOT / "lib/features/object_detection/object_screen.dart",
    },
    {
        "title": "رابعاً: قراءة النصوص OCR",
        "tech": "ML Kit Text Recognition • Gemini كبديل",
        "purpose": "قراءة النصوص المطبوعة من الصور باللغتين العربية والإنجليزية.",
        "summary": (
            "يُستخدم نموذج Text Recognition من ML Kit لاستخراج النصوص "
            "اللاتينية محلياً، وعند فشل الاستخراج أو الحاجة لدعم العربية "
            "يتم استدعاء نموذج Gemini كحل احتياطي."
        ),
        "file": ROOT / "lib/features/text_reader/ocr_screen.dart",
    },
    {
        "title": "خامساً: اكتشاف الوجوه (ML Kit Face Detection)",
        "tech": "ML Kit Face Detection",
        "purpose": "عدّ الوجوه الظاهرة أمام الكاميرا والإعلان عنها صوتياً.",
        "summary": (
            "يعتمد على نموذج Face Detection من Google ML Kit مع التقاط "
            "دوري للصور كل ثلاث ثوانٍ، مع منع تكرار الإعلانات الصوتية "
            "غير المفيدة."
        ),
        "file": ROOT / "lib/features/face_recognition/face_screen.dart",
    },
    {
        "title": "سادساً: وصف المشهد عبر Gemini",
        "tech": "Gemini 1.5 Flash (Vision)",
        "purpose": (
            "توليد وصف لغوي تلقائي للمشهد المرئي أمام المستخدم لمساعدة "
            "ضعاف البصر."
        ),
        "summary": (
            "تلتقط الشاشة صورة كل أربع ثوانٍ وترسلها إلى نموذج Gemini مع "
            "موجّه عربي، ثم تنطق النتيجة عبر محرك TTS."
        ),
        "file": ROOT / "lib/features/scene_description/scene_screen.dart",
    },
    {
        "title": "سابعاً: التعرف على اللون الغالب",
        "tech": "خوارزمية إحصائية على البكسلات (بدون نموذج خارجي)",
        "purpose": "تحديد اللون الغالب في إطار الكاميرا وتسميته بالعربية.",
        "summary": (
            "يتم تصغير الإطار إلى 64×64 بكسل، ثم حساب متوسط قنوات RGB، "
            "وتصنيف الناتج إلى أحد الألوان العربية الأساسية عبر قواعد بسيطة."
        ),
        "file": ROOT / "lib/features/color_detection/color_screen.dart",
    },
]


# ---------------------------------------------------------------------------
# Cover & sections
# ---------------------------------------------------------------------------
def _add_centered_arabic(doc: Document, text: str, *, size: int,
                         bold: bool = False, italic: bool = False,
                         color: RGBColor | None = None) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    _set_rtl_paragraph(p)
    run = p.add_run(text)
    run.bold = bold
    run.italic = italic
    run.font.size = Pt(size)
    if color is not None:
        run.font.color.rgb = color
    _set_run_fonts(run, "Calibri", "Arial")
    _mark_run_rtl(run)


def build_cover(doc: Document) -> None:
    for _ in range(3):
        doc.add_paragraph()

    _add_centered_arabic(doc, "تقرير فني", size=28, bold=True,
                         color=RGBColor(0x1F, 0x49, 0x7D))
    _add_centered_arabic(
        doc, "أكواد نماذج الذكاء الاصطناعي – تطبيق بصيرة",
        size=20, bold=True,
    )
    doc.add_paragraph()
    _add_centered_arabic(
        doc, "نسخة مبسّطة تتضمن كود الموديلات الذكية فقط",
        size=13, italic=True, color=RGBColor(0x55, 0x55, 0x55),
    )

    for _ in range(8):
        doc.add_paragraph()

    _add_centered_arabic(doc, "إعداد فريق تطوير تطبيق بصيرة", size=12)
    doc.add_page_break()


def build_intro(doc: Document) -> None:
    add_heading_ar(doc, "مقدمة", level=1)
    add_arabic(
        doc,
        "بناءً على طلب العميل، يُقدّم هذا التقرير الفني نسخة مبسّطة تحتوي "
        "حصراً على أكواد نماذج الذكاء الاصطناعي المُستخدمة في تطبيق "
        "«بصيرة» المخصص لمساعدة المكفوفين وضعاف البصر. تم استبعاد كود "
        "الواجهات وملفات الإعدادات والبنية التحتية غير المرتبطة "
        "مباشرة بالنماذج الذكية، التزاماً بالشرط المطلوب.",
    )
    add_arabic(
        doc,
        "يعتمد التطبيق على مزيج من النماذج المحلية (TensorFlow Lite و Google "
        "ML Kit) لتحقيق أداء فوري دون إنترنت، إضافة إلى النماذج السحابية "
        "متعددة الوسائط (Gemini 1.5 Flash) للمهام التي تتطلب فهماً سياقياً "
        "أعمق مثل وصف المشهد وقراءة النصوص العربية.",
    )

    add_heading_ar(doc, "ملخص النماذج المستخدمة", level=2)
    items = [
        "نموذج YOLOv8 (TFLite) للتعرف على فئات العملة المصرية.",
        "نماذج Google ML Kit: اكتشاف الأشياء، التسميات، النصوص، الوجوه.",
        "نموذج Gemini 1.5 Flash لوصف المشهد وقراءة النصوص العربية.",
        "خوارزمية محلية لتحليل اللون الغالب من بكسلات الإطار.",
    ]
    for it in items:
        p = doc.add_paragraph(style="List Bullet")
        p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        _set_rtl_paragraph(p)
        _add_bidi_runs(p, it, bold=False, size=12, color=None)

    doc.add_page_break()


def build_section(doc: Document, section: dict) -> None:
    add_heading_ar(doc, section["title"], level=1)

    add_heading_ar(doc, "التقنية المستخدمة", level=2)
    add_arabic(doc, section["tech"])

    add_heading_ar(doc, "الهدف الوظيفي", level=2)
    add_arabic(doc, section["purpose"])

    add_heading_ar(doc, "الوصف الفني المختصر", level=2)
    add_arabic(doc, section["summary"])

    add_heading_ar(doc, "الكود المصدر", level=2)
    rel = section["file"].relative_to(ROOT).as_posix()
    add_file_caption(doc, rel)
    code = section["file"].read_text(encoding="utf-8")
    add_code_block(doc, code)

    doc.add_page_break()


def build_conclusion(doc: Document) -> None:
    add_heading_ar(doc, "الخاتمة", level=1)
    add_arabic(
        doc,
        "يُظهر التطبيق توظيفاً متكاملاً لتقنيات الذكاء الاصطناعي الحديثة، "
        "بدمج النماذج المحلية الخفيفة (TFLite و ML Kit) مع النماذج "
        "السحابية متعددة الوسائط (Gemini)، بما يحقق توازناً بين الأداء "
        "الفوري والدقة العالية. وقد تم تقديم كود النماذج فقط في هذا "
        "التقرير وفقاً لطلب العميل، مع إمكانية تسليم الكود الكامل عند "
        "الحاجة.",
    )


def main() -> None:
    doc = Document()
    # Default page margins for a clean formal layout
    for section in doc.sections:
        section.top_margin = Cm(2.2)
        section.bottom_margin = Cm(2.2)
        section.left_margin = Cm(2.0)
        section.right_margin = Cm(2.0)

    build_cover(doc)
    build_intro(doc)
    for s in SECTIONS:
        build_section(doc, s)
    build_conclusion(doc)

    out = ROOT / "Basira_AI_Models_Report.docx"
    doc.save(out)
    print(f"Saved: {out}")


if __name__ == "__main__":
    main()
