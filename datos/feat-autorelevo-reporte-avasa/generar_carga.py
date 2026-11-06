"""Genera 02-carga.sql y 02-rollback.sql desde el xlsx del Reporte AVASA.

Uso: uv run --with openpyxl python -I generar_carga.py <reporte.xlsx> <dir_salida>
Solo exporta llaves y las columnas pedidas; omite nombres y placas.
"""
import sys
from decimal import Decimal
from pathlib import Path

import openpyxl

COLUMNAS = {
    "contract number": "contract_number",
    "numero de reserva": "numero_reserva",
    "número de siniestro o folio": "siniestro_folio",
    "dias renta": "dias_renta",
    "total del contrato": "total_contrato",
    "voucher total": "voucher_total",
}
TEXTO = ("contract_number", "numero_reserva", "siniestro_folio")
LOTE = 500


def normalizar(encabezado):
    return " ".join(str(encabezado or "").replace("\xad", "").split()).lower()


def indices(encabezados):
    idx = {}
    for i, h in enumerate(encabezados):
        campo = COLUMNAS.get(normalizar(h))
        if campo and campo not in idx:
            idx[campo] = i
    faltan = set(COLUMNAS.values()) - set(idx)
    if faltan:
        sys.exit(f"Faltan columnas: {sorted(faltan)}")
    return idx


def sql_valor(campo, valor):
    if valor is None or str(valor).strip() == "":
        return "NULL"
    if campo in TEXTO:
        return "'" + str(valor).strip().replace("'", "''") + "'"
    return str(Decimal(str(valor)).quantize(Decimal("0.01")))


def filas(ruta):
    hoja = openpyxl.load_workbook(ruta, read_only=True, data_only=True).worksheets[0]
    it = hoja.iter_rows(values_only=True)
    idx = indices(next(it))
    vistos = set()
    for fila in it:
        contrato = fila[idx["contract_number"]]
        if not contrato or contrato in vistos:
            continue
        vistos.add(contrato)
        yield [sql_valor(c, fila[i]) for c, i in idx.items()], list(idx)


def main(ruta, salida):
    salida = Path(salida)
    datos = list(filas(ruta))
    campos = datos[0][1]
    valores = [v for v, _ in datos]
    actualizar = ", ".join(f"{c} = VALUES({c})" for c in campos if c != "contract_number")
    with open(salida / "02-carga.sql", "w", encoding="utf-8") as f:
        for i in range(0, len(valores), LOTE):
            lote = ",\n".join("(" + ", ".join(v) + ")" for v in valores[i:i + LOTE])
            f.write(f"INSERT INTO autorelevo_contrato_renta ({', '.join(campos)}) VALUES\n{lote}\n"
                    f"ON DUPLICATE KEY UPDATE {actualizar};\n")
    contratos = [v[campos.index("contract_number")] for v in valores]
    with open(salida / "02-rollback.sql", "w", encoding="utf-8") as f:
        for i in range(0, len(contratos), LOTE):
            f.write("DELETE FROM autorelevo_contrato_renta WHERE contract_number IN ("
                    + ", ".join(contratos[i:i + LOTE]) + ");\n")
    print(f"{len(valores)} contratos")


if __name__ == "__main__":
    main(*sys.argv[1:3])
