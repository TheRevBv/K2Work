"""Aplica el formato Chubb CDM a un .docx convertido desde Markdown por wordcraft-cli.

Uso:
    uv run --with python-docx cdm_docx.py <docx> --tipo DIS|CLL|PRUEBAS|MANUAL --id <ID> [--logo <png>]

Las imágenes van en el Markdown como un párrafo `IMG: archivo.png` (relativo a --imagenes).
El Markdown de origen empieza con `# <Título>` y una línea `**<ID>** · <proyecto>`;
la última línea `Versión ...` se elimina porque el pie la reemplaza.
"""
import argparse
from pathlib import Path

from docx import Document
from docx.enum.text import WD_BREAK, WD_TAB_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

FORMATOS = {
    "DIS": {"titulo": "Diseño Detallado", "formato": "3.00.01", "fuente": "Georgia", "encabezado": "8DB600"},
    "CLL": {"titulo": "Checklist de Liberación", "formato": "4.00.01", "fuente": "Arial", "encabezado": "000000"},
    "PRUEBAS": {"titulo": "Evidencia de Pruebas", "formato": "4.00.01", "fuente": "Arial", "encabezado": "000000"},
    "MANUAL": {"titulo": "Manual Técnico", "formato": "4.00.01", "fuente": "Arial", "encabezado": "000000"},
}
LOGO_DEFAULT = Path.home() / "Documentos/wordcraft/cdm/plantillas/logo-chubb.png"


def add_field(run, instr: str) -> None:
    for tag, attr in (("w:fldChar", "begin"), ("w:instrText", None), ("w:fldChar", "separate"), ("w:fldChar", "end")):
        el = OxmlElement(tag)
        if attr:
            el.set(qn("w:fldCharType"), attr)
        else:
            el.set(qn("xml:space"), "preserve")
            el.text = instr
        run._r.append(el)


def bottom_border(paragraph) -> None:
    p_pr = paragraph._p.get_or_add_pPr()
    borders = OxmlElement("w:pBdr")
    bottom = OxmlElement("w:bottom")
    for key, val in (("val", "single"), ("sz", "6"), ("space", "1"), ("color", "808080")):
        bottom.set(qn(f"w:{key}"), val)
    borders.append(bottom)
    p_pr.append(borders)


def shade(cell, color: str) -> None:
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:fill"), color)
    cell._tc.get_or_add_tcPr().append(shd)


def set_fonts(doc, fuente: str) -> None:
    for style in doc.styles:
        if style.type == 1 and style.font is not None:
            style.font.name = fuente
            style.font.color.rgb = RGBColor(0, 0, 0)
            r_pr = style.element.get_or_add_rPr()
            r_fonts = r_pr.find(qn("w:rFonts"))
            if r_fonts is None:
                r_fonts = OxmlElement("w:rFonts")
                r_pr.append(r_fonts)
            for attr in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
                r_fonts.set(qn(attr), fuente)
    doc.styles["Normal"].font.size = Pt(11)
    for nivel in (1, 2, 3):
        nombre = f"Heading {nivel}"
        if nombre in [s.name for s in doc.styles]:
            doc.styles[nombre].font.bold = True


def portada(doc, cfg: dict, doc_id: str, logo: Path) -> None:
    body = doc.element.body
    titulo, subtitulo = doc.paragraphs[0], doc.paragraphs[1]

    logo_p = titulo.insert_paragraph_before()
    logo_p.add_run().add_picture(str(logo), width=Cm(5))
    logo_p.paragraph_format.space_after = Cm(6)

    titulo.clear()
    titulo.style = doc.styles["Normal"]
    run = titulo.add_run(cfg["titulo"])
    run.bold, run.font.size = True, Pt(32)
    subtitulo.clear()
    sub = subtitulo.add_run(doc_id)
    sub.font.size = Pt(18)
    sub.add_break(WD_BREAK.PAGE)

    titulos = [(p.text, int(p.style.name[-1])) for p in doc.paragraphs
               if p.style.name.startswith("Heading") and p.style.name[-1] in "123"]
    base = min((nivel for _, nivel in titulos), default=1)
    nuevos = [doc.add_paragraph() for _ in range(len(titulos) + 1)]
    nuevos[0].add_run("Tabla de Contenido").bold = True
    for p, (texto, nivel) in zip(nuevos[1:], titulos):
        p.paragraph_format.left_indent = Cm(0.5 * (nivel - base))
        p.paragraph_format.space_after = Pt(0)
        p.add_run(texto)
    toc_field(nuevos[1], nuevos[-1])
    nuevos[-1].add_run().add_break(WD_BREAK.PAGE)

    ancla = subtitulo._p
    for p in nuevos:
        body.remove(p._p)
        ancla.addnext(p._p)
        ancla = p._p


def toc_field(primero, ultimo) -> None:
    """Campo TOC con los títulos como resultado precalculado; Word lo recalcula con páginas al abrir."""
    def fld(tipo):
        el = OxmlElement("w:fldChar")
        el.set(qn("w:fldCharType"), tipo)
        return el

    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = 'TOC \\o "1-3" \\h \\z \\u'
    inicio = primero.runs[0]._r
    for el in (fld("begin"), instr, fld("separate")):
        r = OxmlElement("w:r")
        r.append(el)
        inicio.addprevious(r)
    fin = OxmlElement("w:r")
    fin.append(fld("end"))
    ultimo._p.append(fin)


def encabezado_y_pie(doc, cfg: dict, doc_id: str) -> None:
    section = doc.sections[0]
    section.different_first_page_header_footer = True

    header = section.header.paragraphs[0]
    header.text = f"{doc_id}\n{cfg['titulo']}"
    bottom_border(header)

    footer = section.footer.paragraphs[0]
    ancho = section.page_width - section.left_margin - section.right_margin
    footer.paragraph_format.tab_stops.add_tab_stop(ancho // 2, WD_TAB_ALIGNMENT.CENTER)
    footer.paragraph_format.tab_stops.add_tab_stop(ancho, WD_TAB_ALIGNMENT.RIGHT)
    footer.add_run(f"Versión Formato: {cfg['formato']}\t")
    add_field(footer.add_run(), "PAGE")
    footer.add_run("\tDocumento confidencial Chubb")
    for run in footer.runs:
        run.font.size = Pt(9)


def tablas(doc, color: str) -> None:
    for table in doc.tables:
        table.style = doc.styles["Table Grid"] if "Table Grid" in [s.name for s in doc.styles] else table.style
        for cell in table.rows[0].cells:
            shade(cell, color)
            for p in cell.paragraphs:
                for run in p.runs:
                    run.bold = True
                    run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)


def imagenes(doc, carpeta: Path) -> None:
    """Reemplaza los párrafos `IMG: archivo.png` por la imagen de `carpeta`, al ancho de la página."""
    section = doc.sections[0]
    ancho = section.page_width - section.left_margin - section.right_margin
    for p in doc.paragraphs:
        texto = p.text.strip()
        if texto.startswith("IMG:"):
            archivo = carpeta / texto[4:].strip()
            p.clear()
            p.add_run().add_picture(str(archivo), width=ancho)


def quitar_version_final(doc) -> None:
    ultimo = [p for p in doc.paragraphs if p.text.strip()][-1]
    if ultimo.text.startswith("Versión"):
        ultimo._p.getparent().remove(ultimo._p)


def actualizar_campos_al_abrir(doc) -> None:
    update = OxmlElement("w:updateFields")
    update.set(qn("w:val"), "true")
    doc.settings.element.append(update)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("docx", type=Path)
    parser.add_argument("--tipo", required=True, choices=FORMATOS)
    parser.add_argument("--id", required=True, dest="doc_id")
    parser.add_argument("--logo", type=Path, default=LOGO_DEFAULT)
    parser.add_argument("--imagenes", type=Path, help="carpeta de las imágenes IMG: (default: <docx>/../src)")
    args = parser.parse_args()

    cfg = FORMATOS[args.tipo]
    doc = Document(args.docx)
    quitar_version_final(doc)
    set_fonts(doc, cfg["fuente"])
    portada(doc, cfg, args.doc_id, args.logo)
    encabezado_y_pie(doc, cfg, args.doc_id)
    tablas(doc, cfg["encabezado"])
    imagenes(doc, args.imagenes or args.docx.parent / "src")
    actualizar_campos_al_abrir(doc)
    doc.save(args.docx)


if __name__ == "__main__":
    main()
