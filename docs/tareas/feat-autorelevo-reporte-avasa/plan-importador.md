# Importador genérico de archivos — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Endpoint `POST /api/importador/<layout_key>` que valida un `.xlsx`/`.csv` y lo guarda en su tabla (primer layout: Reporte AVASA → `autorelevo_contrato_renta`).

**Architecture:** Módulo `ix/apps/importador/` con piezas pequeñas: parser (archivo → filas), validador (filas → registros o errores), registro declarativo de layouts y servicio que hace upsert síncrono en lotes dentro de una transacción. Sin hilos ni colas.

**Tech Stack:** Flask 3.1, SQLAlchemy 2.0 (dialecto MySQL), openpyxl 3.1.5, defusedxml, pytest.

**Spec:** `K2Work/docs/tareas/feat-autorelevo-reporte-avasa/spec-importador.md`

## Global Constraints

- Repo: `K2-Full-Portal/apiserver`. Rutas de este plan relativas a `apiserver/`.
- Sin migraciones alembic: esquema por SQL en `K2Work/datos/feat-autorelevo-reporte-avasa/` con su rollback.
- Sin commit, push ni PR sin confirmación explícita del usuario. Nunca `Co-Authored-By` ni `Claude-Session`.
- Sin comentarios narrativos en código; solo docstrings útiles.
- Nunca concatenar SQL con strings; el cliente nunca elige tabla ni columnas.
- Límites AVASA: 5 MB, 20,000 filas. Tope de descompresión global: 50 MB. Lote: 500. Máximo de errores devueltos: 100.
- Logs con prefijo `IMPORTADOR -`; nunca contenido de filas.
- BD solo `local`/`dev` vía `K2Work/bin/k2-sql`.

## Archivos

| Archivo | Acción | Responsabilidad |
|---|---|---|
| `ix/apps/importador/__init__.py` | Crear | vacío |
| `ix/apps/importador/definitions.py` | Crear | constantes y mensajes |
| `ix/apps/importador/errors.py` | Crear | `ImportError_`, `RowError` |
| `ix/apps/importador/parsers.py` | Crear | detección de formato, zip bomb, lectura y normalización |
| `ix/apps/importador/validators.py` | Crear | conversión por tipo y validación de filas |
| `ix/apps/importador/layouts.py` | Crear | `ImportColumn`, `ImportLayout`, `LAYOUTS` |
| `ix/apps/importador/services.py` | Crear | `ImportService.importar` |
| `ix/apps/importador/endpoints.py` | Crear | rutas |
| `ix/boletas_informativas/auto_relevo/api/auto_relevo_boleta/auto_relevo_boleta_models.py` | Modificar | modelo `AutorelevoContratoRenta` |
| `ix/app.py:~322` | Modificar | registrar endpoints |
| `requirements.txt` | Modificar | `defusedxml` |
| `ix/tests/importador/` | Crear | pruebas |
| `K2Work/datos/feat-autorelevo-reporte-avasa/03-auditoria.sql`, `03-rollback.sql` | Crear | columnas de auditoría |

---

### Task 0: Rama y entorno

- [ ] **Step 1:** En `K2-Full-Portal`, crear la rama `feat-autorelevo-reporte-avasa` desde la rama base vigente siguiendo la skill `k2-git`.
- [ ] **Step 2:** Agregar `defusedxml==0.7.1` a `requirements.txt` (orden alfabético) e instalar en el venv: `pip install defusedxml==0.7.1`.
- [ ] **Step 3:** Verificar que `pytest ix/tests/test_assistance_cases_km.py -q --co` recolecta pruebas (confirma runner y `conftest`).

### Task 1: Columnas de auditoría y modelo

**Files:**
- Create: `K2Work/datos/feat-autorelevo-reporte-avasa/03-auditoria.sql`, `03-rollback.sql`
- Modify: `ix/boletas_informativas/auto_relevo/api/auto_relevo_boleta/auto_relevo_boleta_models.py` (después de `CostosAutorelevo`)
- Test: `ix/tests/importador/test_modelo_contrato_renta.py`

**Interfaces:** Produces `AutorelevoContratoRenta` con columnas `contract_number, numero_reserva, siniestro_folio, dias_renta, total_contrato, voucher_total` + `AuditEntity`.

- [ ] **Step 1: SQL**

`03-auditoria.sql`:
```sql
ALTER TABLE autorelevo_contrato_renta
    ADD COLUMN audit_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN audit_updated_at DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN audit_deleted_at DATETIME NULL,
    ADD COLUMN audit_created_by INT NULL,
    ADD COLUMN audit_updated_by INT NULL,
    ADD COLUMN audit_deleted_by INT NULL,
    ADD COLUMN active_record TINYINT(1) DEFAULT 1;
```
`03-rollback.sql`:
```sql
ALTER TABLE autorelevo_contrato_renta
    DROP COLUMN audit_created_at, DROP COLUMN audit_updated_at, DROP COLUMN audit_deleted_at,
    DROP COLUMN audit_created_by, DROP COLUMN audit_updated_by, DROP COLUMN audit_deleted_by,
    DROP COLUMN active_record;
```
`fecha_carga` se conserva (la usa la carga inicial).

- [ ] **Step 2:** Pedir confirmación al usuario y aplicar: `K2_CONFIRM_DEV=si bin/k2-sql dev -f datos/feat-autorelevo-reporte-avasa/03-auditoria.sql --commit`; verificar con `bin/k2-sql dev describe autorelevo_contrato_renta`.

- [ ] **Step 3: Prueba que falla**

`ix/tests/importador/__init__.py` vacío. `ix/tests/importador/test_modelo_contrato_renta.py`:
```python
from ix.boletas_informativas.auto_relevo.api.auto_relevo_boleta.auto_relevo_boleta_models import (
    AutorelevoContratoRenta,
)


def test_modelo_mapea_tabla_y_columnas():
    columnas = set(AutorelevoContratoRenta.__table__.columns.keys())
    assert AutorelevoContratoRenta.__tablename__ == "autorelevo_contrato_renta"
    assert {"contract_number", "numero_reserva", "siniestro_folio",
            "dias_renta", "total_contrato", "voucher_total",
            "audit_created_by", "active_record"} <= columnas
```
Run: `pytest ix/tests/importador/test_modelo_contrato_renta.py -v` → FAIL (ImportError).

- [ ] **Step 4: Modelo**
```python
class AutorelevoContratoRenta(database.Model, Base, AuditEntity):
    __tablename__ = 'autorelevo_contrato_renta'

    id = Column(Integer, primary_key=True, autoincrement=True)
    contract_number = Column(String(20), unique=True, nullable=False)
    numero_reserva = Column(String(20), nullable=True)
    siniestro_folio = Column(String(30), nullable=True)
    dias_renta = Column(DECIMAL(6, 2), nullable=False)
    total_contrato = Column(DECIMAL(12, 2), nullable=False)
    voucher_total = Column(DECIMAL(12, 2), nullable=False)
    fecha_carga = Column(DateTime, nullable=False, default=datetime.utcnow)
```
- [ ] **Step 5:** Run la prueba → PASS.
- [ ] **Step 6:** Commit (con confirmación): `feat(autorelevo): modelo AutorelevoContratoRenta`.

### Task 2: Parser seguro

**Files:**
- Create: `ix/apps/importador/__init__.py`, `definitions.py`, `errors.py`, `parsers.py`
- Test: `ix/tests/importador/test_parsers.py`

**Interfaces:**
- Produces: `normalizar_encabezado(valor) -> str`; `leer_archivo(filename: str, data: bytes, max_rows: int) -> tuple[list[str], Iterator[tuple[int, list]]]` (encabezados normalizados, filas `(numero_fila_excel, valores)`); `ImportError_(mensaje: str, status: int = 400, errores: list | None = None)`; `RowError(fila: int, columna: str, valor, mensaje: str)` con `.to_dict()`.

- [ ] **Step 1: definitions y errors**

`definitions.py`:
```python
API_URI_BASE = "/importador"
LOG_PREFIX = "IMPORTADOR -"
TAMANO_LOTE = 500
MAX_ERRORES_RESPUESTA = 100
MAX_BYTES_DESCOMPRIMIDOS = 50 * 1024 * 1024
FIRMA_ZIP = b"PK\x03\x04"
PREFIJOS_FORMULA = ("=", "+", "-", "@")

MSG_SIN_ARCHIVO = "Debe proporcionar un archivo en el campo 'file'"
MSG_LAYOUT_INEXISTENTE = "Layout de importación no encontrado"
MSG_FORMATO = "El archivo debe ser .xlsx o .csv válido"
MSG_TAMANO = "El archivo excede el tamaño permitido"
MSG_FILAS = "El archivo excede el número de filas permitido"
MSG_DESCOMPRESION = "El archivo excede el tamaño descomprimido permitido"
MSG_COLUMNAS = "Faltan columnas obligatorias"
MSG_FILAS_INVALIDAS = "El archivo tiene filas inválidas; no se importó nada"
MSG_ERROR_INTERNO = "No se pudo completar la importación"
```
`errors.py`:
```python
from dataclasses import dataclass, asdict
from typing import Any


class ImportError_(Exception):
    """Error de importación con estatus HTTP y detalle por fila opcional."""

    def __init__(self, mensaje: str, status: int = 400, errores: list | None = None):
        super().__init__(mensaje)
        self.mensaje = mensaje
        self.status = status
        self.errores = errores or []


@dataclass(frozen=True)
class RowError:
    fila: int
    columna: str
    valor: Any
    mensaje: str

    def to_dict(self) -> dict:
        datos = asdict(self)
        datos["valor"] = None if self.valor is None else str(self.valor)
        return datos
```

- [ ] **Step 2: Pruebas que fallan**

`ix/tests/importador/conftest.py` (helpers de archivos sintéticos):
```python
import io
import zipfile

import openpyxl
import pytest


def _xlsx(filas):
    wb = openpyxl.Workbook()
    ws = wb.active
    for fila in filas:
        ws.append(fila)
    buffer = io.BytesIO()
    wb.save(buffer)
    return buffer.getvalue()


@pytest.fixture
def xlsx_bytes():
    return _xlsx


@pytest.fixture
def zip_bomb():
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("xl/worksheets/sheet1.xml", b"0" * (60 * 1024 * 1024))
    return buffer.getvalue()
```
`ix/tests/importador/test_parsers.py`:
```python
import pytest

from ix.apps.importador.errors import ImportError_
from ix.apps.importador.parsers import leer_archivo, normalizar_encabezado


@pytest.mark.parametrize("crudo, esperado", [
    ("Di\xadas Renta", "dias renta"),
    ("  Número de  Siniestro o Folio ", "numero de siniestro o folio"),
    (None, ""),
])
def test_normalizar_encabezado(crudo, esperado):
    assert normalizar_encabezado(crudo) == esperado


def test_lee_xlsx(xlsx_bytes):
    data = xlsx_bytes([["Contract Number", "Di\xadas Renta"], ["F1", 15], [None, None]])
    encabezados, filas = leer_archivo("r.xlsx", data, max_rows=10)
    assert encabezados == ["contract number", "dias renta"]
    assert list(filas) == [(2, ["F1", 15])]


def test_lee_csv_utf8():
    data = "Contract Number,Días Renta\nF1,15\n".encode()
    encabezados, filas = leer_archivo("r.csv", data, max_rows=10)
    assert encabezados == ["contract number", "dias renta"]
    assert list(filas) == [(2, ["F1", "15"])]


def test_rechaza_extension_no_permitida():
    with pytest.raises(ImportError_):
        leer_archivo("r.xls", b"x", max_rows=10)


def test_rechaza_xlsx_falso():
    with pytest.raises(ImportError_):
        leer_archivo("r.xlsx", b"no soy zip", max_rows=10)


def test_rechaza_csv_no_utf8():
    with pytest.raises(ImportError_):
        leer_archivo("r.csv", b"\xff\xfe\x00a", max_rows=10)


def test_rechaza_zip_bomb(zip_bomb):
    with pytest.raises(ImportError_):
        leer_archivo("r.xlsx", zip_bomb, max_rows=10)


def test_rechaza_exceso_de_filas(xlsx_bytes):
    data = xlsx_bytes([["A"], ["1"], ["2"], ["3"]])
    _, filas = leer_archivo("r.xlsx", data, max_rows=2)
    with pytest.raises(ImportError_):
        list(filas)
```
Run: `pytest ix/tests/importador/test_parsers.py -v` → FAIL (módulo inexistente).

- [ ] **Step 3: Implementación** `parsers.py`:
```python
import csv
import io
import unicodedata
import zipfile
from typing import Iterator

import openpyxl

from ix.apps.importador.definitions import (
    FIRMA_ZIP, MAX_BYTES_DESCOMPRIMIDOS,
    MSG_DESCOMPRESION, MSG_FILAS, MSG_FORMATO,
)
from ix.apps.importador.errors import ImportError_

Filas = Iterator[tuple[int, list]]


def normalizar_encabezado(valor) -> str:
    texto = str(valor or "").replace("\xad", "")
    texto = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode()
    return " ".join(texto.split()).lower()


def _es_vacia(valores: list) -> bool:
    return all(v is None or str(v).strip() == "" for v in valores)


def _limitar(filas: Filas, max_rows: int) -> Filas:
    for contador, fila in enumerate(filas, start=1):
        if contador > max_rows:
            raise ImportError_(MSG_FILAS)
        yield fila


def _validar_zip(data: bytes) -> None:
    if not data.startswith(FIRMA_ZIP):
        raise ImportError_(MSG_FORMATO)
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            total = sum(info.file_size for info in z.infolist())
    except zipfile.BadZipFile:
        raise ImportError_(MSG_FORMATO)
    if total > MAX_BYTES_DESCOMPRIMIDOS:
        raise ImportError_(MSG_DESCOMPRESION)


def _leer_xlsx(data: bytes) -> tuple[list, Filas]:
    _validar_zip(data)
    try:
        hoja = openpyxl.load_workbook(io.BytesIO(data), read_only=True, data_only=True).worksheets[0]
        filas = hoja.iter_rows(values_only=True)
        encabezados = list(next(filas, []))
    except (KeyError, ValueError, OSError, zipfile.BadZipFile):
        raise ImportError_(MSG_FORMATO)
    return encabezados, ((n, list(v)) for n, v in enumerate(filas, start=2))


def _leer_csv(data: bytes) -> tuple[list, Filas]:
    try:
        texto = data.decode("utf-8-sig")
    except UnicodeDecodeError:
        raise ImportError_(MSG_FORMATO)
    lector = csv.reader(io.StringIO(texto))
    encabezados = next(lector, [])
    return encabezados, ((n, list(v)) for n, v in enumerate(lector, start=2))


LECTORES = {".xlsx": _leer_xlsx, ".csv": _leer_csv}


def leer_archivo(filename: str, data: bytes, max_rows: int) -> tuple[list[str], Filas]:
    """Devuelve encabezados normalizados y un iterador perezoso de filas no vacías.

    El límite de filas se aplica al consumir el iterador.
    """
    extension = "." + filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    lector = LECTORES.get(extension)
    if not lector:
        raise ImportError_(MSG_FORMATO)
    encabezados, filas = lector(data)
    no_vacias = (f for f in filas if not _es_vacia(f[1]))
    return [normalizar_encabezado(h) for h in encabezados], _limitar(no_vacias, max_rows)
```
- [ ] **Step 4:** Run `pytest ix/tests/importador/test_parsers.py -v` → PASS.
- [ ] **Step 5:** Commit (con confirmación): `feat(importador): parser seguro de xlsx y csv`.

### Task 3: Validador por tipo

**Files:**
- Create: `ix/apps/importador/layouts.py` (solo dataclasses, sin registro), `ix/apps/importador/validators.py`
- Test: `ix/tests/importador/test_validators.py`

**Interfaces:**
- Consumes: `normalizar_encabezado`, `RowError`, `ImportError_`, `PREFIJOS_FORMULA`.
- Produces:
  - `ImportColumn(header: str, field: str, kind: str, required: bool = False)`; `kind` ∈ `{"text", "decimal", "int", "date"}`.
  - `ImportLayout(key, model, upsert_key, columns, roles, max_bytes, max_rows)`.
  - `mapear_columnas(layout, encabezados) -> dict[str, int]` (field → índice; lanza `ImportError_(MSG_COLUMNAS, errores=[faltantes])`).
  - `validar_filas(layout, indices, filas) -> tuple[list[dict], list[RowError], int]` (registros, errores, total_errores).

- [ ] **Step 1: Pruebas que fallan** `ix/tests/importador/test_validators.py`:
```python
from datetime import date
from decimal import Decimal

import pytest

from ix.apps.importador.errors import ImportError_
from ix.apps.importador.layouts import ImportColumn, ImportLayout
from ix.apps.importador.validators import mapear_columnas, validar_filas

LAYOUT = ImportLayout(
    key="prueba", model=None, upsert_key="clave",
    columns=(
        ImportColumn("Clave", "clave", "text", required=True),
        ImportColumn("Monto", "monto", "decimal", required=True),
        ImportColumn("Dias", "dias", "int"),
        ImportColumn("Fecha", "fecha", "date"),
    ),
    roles=("admin",), max_bytes=1024, max_rows=100,
)


def test_mapear_usa_primera_aparicion_e_ignora_extras():
    indices = mapear_columnas(LAYOUT, ["clave", "extra", "monto", "clave"])
    assert indices == {"clave": 0, "monto": 2}


def test_mapear_reporta_obligatorias_faltantes():
    with pytest.raises(ImportError_) as e:
        mapear_columnas(LAYOUT, ["clave"])
    assert e.value.errores == ["Monto"]


def test_convierte_tipos():
    indices = {"clave": 0, "monto": 1, "dias": 2, "fecha": 3}
    registros, errores, total = validar_filas(
        LAYOUT, indices, [(2, [" F1 ", "1,078.5", "15", "2025-04-03"])])
    assert errores == [] and total == 0
    assert registros == [{"clave": "F1", "monto": Decimal("1078.50"),
                          "dias": 15, "fecha": date(2025, 4, 3)}]


@pytest.mark.parametrize("fila, columna", [
    ([None, "1"], "Clave"),
    (["F1", "abc"], "Monto"),
    (["=HYPERLINK(1)", "1"], "Clave"),
])
def test_errores_de_fila(fila, columna):
    _, errores, total = validar_filas(LAYOUT, {"clave": 0, "monto": 1}, [(5, fila)])
    assert total == 1 and errores[0].fila == 5 and errores[0].columna == columna


def test_llave_duplicada_en_archivo():
    _, errores, _ = validar_filas(LAYOUT, {"clave": 0, "monto": 1},
                                  [(2, ["F1", "1"]), (3, ["F1", "2"])])
    assert [(e.fila, e.columna) for e in errores] == [(3, "Clave")]


def test_limita_errores_devueltos_pero_cuenta_todos():
    filas = [(n, [None, "1"]) for n in range(2, 202)]
    _, errores, total = validar_filas(LAYOUT, {"clave": 0, "monto": 1}, filas)
    assert len(errores) == 100 and total == 200
```
Run → FAIL.

- [ ] **Step 2: `layouts.py` (dataclasses)**
```python
from dataclasses import dataclass


@dataclass(frozen=True)
class ImportColumn:
    header: str
    field: str
    kind: str
    required: bool = False


@dataclass(frozen=True)
class ImportLayout:
    """Define cómo un archivo se convierte en filas de una tabla."""

    key: str
    model: type
    upsert_key: str
    columns: tuple
    roles: tuple
    max_bytes: int
    max_rows: int
```

- [ ] **Step 3: `validators.py`**
```python
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

from ix.apps.importador.definitions import MAX_ERRORES_RESPUESTA, MSG_COLUMNAS, PREFIJOS_FORMULA
from ix.apps.importador.errors import ImportError_, RowError
from ix.apps.importador.parsers import normalizar_encabezado


def _texto(valor):
    texto = str(valor).strip()
    if texto.startswith(PREFIJOS_FORMULA):
        raise ValueError("No se permiten fórmulas")
    return texto


def _decimal(valor):
    try:
        return Decimal(str(valor).replace(",", "").strip()).quantize(Decimal("0.01"))
    except InvalidOperation:
        raise ValueError("Número inválido")


def _entero(valor):
    numero = _decimal(valor)
    if numero != numero.to_integral_value():
        raise ValueError("Entero inválido")
    return int(numero)


def _fecha(valor):
    if isinstance(valor, datetime):
        return valor.date()
    if isinstance(valor, date):
        return valor
    try:
        return date.fromisoformat(str(valor).strip()[:10])
    except ValueError:
        raise ValueError("Fecha inválida (AAAA-MM-DD)")


CONVERSORES = {"text": _texto, "decimal": _decimal, "int": _entero, "date": _fecha}


def mapear_columnas(layout, encabezados: list[str]) -> dict[str, int]:
    indices = {}
    for columna in layout.columns:
        objetivo = normalizar_encabezado(columna.header)
        if objetivo in encabezados:
            indices[columna.field] = encabezados.index(objetivo)
    faltantes = [c.header for c in layout.columns if c.required and c.field not in indices]
    if faltantes:
        raise ImportError_(MSG_COLUMNAS, errores=faltantes)
    return indices


def _convertir_fila(layout, indices, numero, valores):
    registro, errores = {}, []
    for columna in layout.columns:
        if columna.field not in indices:
            continue
        indice = indices[columna.field]
        crudo = valores[indice] if indice < len(valores) else None
        if crudo is None or str(crudo).strip() == "":
            if columna.required:
                errores.append(RowError(numero, columna.header, crudo, "Valor obligatorio"))
            registro[columna.field] = None
            continue
        try:
            registro[columna.field] = CONVERSORES[columna.kind](crudo)
        except ValueError as e:
            errores.append(RowError(numero, columna.header, crudo, str(e)))
    return registro, errores


def validar_filas(layout, indices, filas):
    """Convierte todas las filas; devuelve registros, hasta 100 errores y el total de errores."""
    registros, errores, total, vistas = [], [], 0, set()
    encabezado_llave = next(c.header for c in layout.columns if c.field == layout.upsert_key)
    for numero, valores in filas:
        registro, errores_fila = _convertir_fila(layout, indices, numero, valores)
        llave = registro.get(layout.upsert_key)
        if not errores_fila and llave in vistas:
            errores_fila.append(RowError(numero, encabezado_llave, llave, "Llave duplicada en el archivo"))
        vistas.add(llave)
        total += len(errores_fila)
        errores.extend(errores_fila[:max(0, MAX_ERRORES_RESPUESTA - len(errores))])
        if not errores_fila:
            registros.append(registro)
    return registros, errores, total
```
- [ ] **Step 4:** Run `pytest ix/tests/importador/test_validators.py -v` → PASS.
- [ ] **Step 5:** Commit (con confirmación): `feat(importador): validación por tipo de columna`.

### Task 4: Registro de layouts y layout AVASA

**Files:**
- Modify: `ix/apps/importador/layouts.py` (agregar registro)
- Test: `ix/tests/importador/test_layouts.py`

**Interfaces:** Produces `LAYOUTS: dict[str, ImportLayout]`, `obtener_layout(key) -> ImportLayout | None`, `AVASA_CONTRATOS`.

- [ ] **Step 1: Prueba que falla**
```python
from ix.apps.importador.layouts import LAYOUTS, obtener_layout
from ix.apps.importador.validators import mapear_columnas
from ix.apps.importador.parsers import normalizar_encabezado

ENCABEZADOS_AVASA = ["Contract Number", "Número de Siniestro o Folio", "KM Traveled",
                     "Di\xadas Renta", "Total del contrato", "Voucher Total",
                     "Contract Number", "Numero de Reserva", "First Name"]


def test_layout_avasa_registrado():
    layout = obtener_layout("avasa_contratos")
    assert layout is LAYOUTS["avasa_contratos"]
    assert layout.upsert_key == "contract_number"


def test_layout_avasa_mapea_encabezados_reales_y_descarta_personales():
    layout = obtener_layout("avasa_contratos")
    indices = mapear_columnas(layout, [normalizar_encabezado(h) for h in ENCABEZADOS_AVASA])
    assert indices == {"contract_number": 0, "siniestro_folio": 1, "dias_renta": 3,
                       "total_contrato": 4, "voucher_total": 5, "numero_reserva": 7}


def test_layout_inexistente():
    assert obtener_layout("../otra_tabla") is None
```
Run → FAIL.

- [ ] **Step 2:** Agregar a `layouts.py` (imports arriba, junto a `dataclass`; registro al final):
```python
from ix.config import config
from ix.boletas_informativas.auto_relevo.api.auto_relevo_boleta.auto_relevo_boleta_models import (
    AutorelevoContratoRenta,
)

AVASA_CONTRATOS = ImportLayout(
    key="avasa_contratos",
    model=AutorelevoContratoRenta,
    upsert_key="contract_number",
    columns=(
        ImportColumn("Contract Number", "contract_number", "text", required=True),
        ImportColumn("Numero de Reserva", "numero_reserva", "text"),
        ImportColumn("Número de Siniestro o Folio", "siniestro_folio", "text"),
        ImportColumn("Días Renta", "dias_renta", "decimal", required=True),
        ImportColumn("Total del contrato", "total_contrato", "decimal", required=True),
        ImportColumn("Voucher Total", "voucher_total", "decimal", required=True),
    ),
    roles=(config.ADMIN, config.SUPERVISOR),
    max_bytes=5 * 1024 * 1024,
    max_rows=20_000,
)

LAYOUTS = {layout.key: layout for layout in (AVASA_CONTRATOS,)}


def obtener_layout(key: str):
    return LAYOUTS.get(key)
```
(Imports al inicio del archivo junto a `dataclass`.)
- [ ] **Step 3:** Run `pytest ix/tests/importador/test_layouts.py -v` → PASS.
- [ ] **Step 4:** Commit (con confirmación): `feat(importador): layout AVASA contratos cerrados`.

### Task 5: Servicio con upsert transaccional

**Files:**
- Create: `ix/apps/importador/services.py`
- Test: `ix/tests/importador/test_services.py`

**Interfaces:**
- Consumes: `leer_archivo`, `mapear_columnas`, `validar_filas`, `ImportLayout`.
- Produces: `ImportService.importar(layout, filename: str, data: bytes, user_id: int, session) -> dict` con `{layout, total, insertados, actualizados}`; lanza `ImportError_`.

- [ ] **Step 1: Pruebas que fallan** (BD real con rollback; usa `create_session(get_db_url())` como `test_assistance_cases_km.py`):
```python
import pytest
from sqlalchemy import func, select

from ix.apps.importador.errors import ImportError_
from ix.apps.importador.layouts import obtener_layout
from ix.apps.importador.services import ImportService
from ix.boletas_informativas.auto_relevo.api.auto_relevo_boleta.auto_relevo_boleta_models import (
    AutorelevoContratoRenta as Modelo,
)
from ix.db.tools import create_session, get_db_url

ENCABEZADO = ["Contract Number", "Numero de Reserva", "Días Renta", "Total del contrato", "Voucher Total"]
USER_ID = 1


@pytest.fixture
def session():
    s = create_session(get_db_url())
    yield s
    s.rollback()
    s.close()


def _contar(session, prefijo):
    return session.scalar(select(func.count()).select_from(Modelo)
                          .where(Modelo.contract_number.like(f"{prefijo}%")))


def test_carga_y_recarga_idempotente(session, xlsx_bytes):
    data = xlsx_bytes([ENCABEZADO, ["ZZT1", "R1", 15, 100, 90], ["ZZT2", None, 7, 50, 0]])
    layout = obtener_layout("avasa_contratos")
    primera = ImportService.importar(layout, "r.xlsx", data, USER_ID, session, commit=False)
    segunda = ImportService.importar(layout, "r.xlsx", data, USER_ID, session, commit=False)
    assert (primera["insertados"], primera["actualizados"]) == (2, 0)
    assert (segunda["insertados"], segunda["actualizados"]) == (0, 2)
    assert _contar(session, "ZZT") == 2


def test_fila_mala_no_escribe_nada(session, xlsx_bytes):
    data = xlsx_bytes([ENCABEZADO, ["ZZT3", "R", 1, 1, 1], ["ZZT4", "R", "x", 1, 1]])
    with pytest.raises(ImportError_) as e:
        ImportService.importar(obtener_layout("avasa_contratos"), "r.xlsx", data, USER_ID, session, commit=False)
    assert e.value.errores[0]["fila"] == 3
    assert _contar(session, "ZZT") == 0
```
`commit=False` solo existe para pruebas (por defecto `True`). Run → FAIL.

- [ ] **Step 2: `services.py`**
```python
import hashlib
import logging

from sqlalchemy import select
from sqlalchemy.dialects.mysql import insert

from ix.apps.importador.definitions import LOG_PREFIX, MSG_ERROR_INTERNO, MSG_FILAS_INVALIDAS, TAMANO_LOTE
from ix.apps.importador.errors import ImportError_
from ix.apps.importador.parsers import leer_archivo
from ix.apps.importador.validators import mapear_columnas, validar_filas


def _lotes(registros, tamano=TAMANO_LOTE):
    for inicio in range(0, len(registros), tamano):
        yield registros[inicio:inicio + tamano]


class ImportService:

    @staticmethod
    def _leer_y_validar(layout, filename, data):
        encabezados, filas = leer_archivo(filename, data, layout.max_rows)
        indices = mapear_columnas(layout, encabezados)
        registros, errores, total_errores = validar_filas(layout, indices, filas)
        if total_errores:
            raise ImportError_(MSG_FILAS_INVALIDAS, errores=[e.to_dict() for e in errores])
        return registros

    @staticmethod
    def _llaves_existentes(layout, registros, session):
        columna = getattr(layout.model, layout.upsert_key)
        existentes = set()
        for lote in _lotes([r[layout.upsert_key] for r in registros]):
            existentes.update(session.scalars(select(columna).where(columna.in_(lote))))
        return existentes

    @staticmethod
    def _upsert(layout, registros, user_id, session):
        tabla = layout.model.__table__
        actualizables = [c.field for c in layout.columns if c.field != layout.upsert_key]
        for lote in _lotes(registros):
            sentencia = insert(tabla).values([{**r, "audit_created_by": user_id} for r in lote])
            cambios = {campo: sentencia.inserted[campo] for campo in actualizables}
            cambios["audit_updated_by"] = user_id
            session.execute(sentencia.on_duplicate_key_update(**cambios))

    @staticmethod
    def importar(layout, filename: str, data: bytes, user_id: int, session, commit: bool = True) -> dict:
        """Valida el archivo completo y hace upsert en una sola transacción (todo o nada)."""
        registros = ImportService._leer_y_validar(layout, filename, data)
        try:
            existentes = ImportService._llaves_existentes(layout, registros, session)
            ImportService._upsert(layout, registros, user_id, session)
            if commit:
                session.commit()
        except Exception:
            session.rollback()
            logging.exception(f"{LOG_PREFIX} error de BD en layout {layout.key}")
            raise ImportError_(MSG_ERROR_INTERNO, status=500)
        resultado = {
            "layout": layout.key,
            "total": len(registros),
            "insertados": len(registros) - len(existentes),
            "actualizados": len(existentes),
        }
        logging.info(f"{LOG_PREFIX} user={user_id} layout={layout.key} archivo={filename} "
                     f"sha256={hashlib.sha256(data).hexdigest()} {resultado}")
        return resultado
```
- [ ] **Step 3:** Run `pytest ix/tests/importador/test_services.py -v` contra local/dev → PASS. Verificar después que no quedó nada: `bin/k2-sql dev -e "SELECT COUNT(*) FROM autorelevo_contrato_renta WHERE contract_number LIKE 'ZZT%'"` → 0.
- [ ] **Step 4:** Commit (con confirmación): `feat(importador): servicio de upsert transaccional por lotes`.

### Task 6: Endpoints y registro en la app

**Files:**
- Create: `ix/apps/importador/endpoints.py`
- Modify: `ix/app.py` (junto a la línea `from ix.apps.form_response_import.endpoints import ...`)
- Test: `ix/tests/importador/test_endpoints.py`

**Interfaces:** Consumes `obtener_layout`, `LAYOUTS`, `ImportService.importar`, `ImportError_`. Usa `database.session` de `ix.app`.

- [ ] **Step 1: Pruebas que fallan** (fixtures `client` y `token` de `ix/tests/conftest.py`; el token es de un admin):
```python
import io

URL = "/api/importador"


def _post(client, layout, data, nombre="r.xlsx", token=None):
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    return client.post(f"{URL}/{layout}", headers=headers, content_type="multipart/form-data",
                       data={"file": (io.BytesIO(data), nombre)})


def test_sin_token_401(client):
    assert _post(client, "avasa_contratos", b"x").status_code == 401


def test_layout_inexistente_404(client, token):
    assert _post(client, "no_existe", b"x", token=token).status_code == 404


def test_sin_archivo_400(client, token):
    r = client.post(f"{URL}/avasa_contratos", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 400


def test_excede_tamano_413(client, token):
    assert _post(client, "avasa_contratos", b"0" * (5 * 1024 * 1024 + 1), token=token).status_code == 413


def test_columnas_faltantes_400(client, token, xlsx_bytes):
    r = _post(client, "avasa_contratos", xlsx_bytes([["Contract Number"], ["ZZE1"]]), token=token)
    assert r.status_code == 400
    assert "Días Renta" in r.get_json()["data"]


def test_lista_layouts(client, token):
    r = client.get(f"{URL}/layouts", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert "avasa_contratos" in [l["key"] for l in r.get_json()["data"]]
```
El 403 requiere un usuario sin rol admin/supervisor; si `conftest` no lo ofrece, se prueba manualmente en Bruno (Task 7). El caso feliz se cubre en Task 5 y en la aceptación (Task 7) para no escribir en dev desde el endpoint en pruebas. Run → FAIL (404 en todas).

- [ ] **Step 2: `endpoints.py`**
```python
from flask import g, request

from ix.api import errors, wrappers
from ix.app import database
from ix.apps.importador.definitions import API_URI_BASE, MSG_LAYOUT_INEXISTENTE, MSG_SIN_ARCHIVO, MSG_TAMANO
from ix.apps.importador.errors import ImportError_
from ix.apps.importador.layouts import LAYOUTS, obtener_layout
from ix.apps.importador.services import ImportService
from ix.config import config


def _error(detalle, status, data=None):
    raise errors.ApiError({"data": data or [], "detail": detalle}, status)


def _validar_rol(layout):
    roles_usuario = {r.name for r in g.current_user.roles}
    if config.ADMIN not in roles_usuario and not roles_usuario.intersection(layout.roles):
        raise errors.forbidden_error


def _leer_limitado(archivo, max_bytes):
    data = archivo.stream.read(max_bytes + 1)
    if len(data) > max_bytes:
        _error(MSG_TAMANO, 413)
    return data


@wrappers.api_resource(route=f"{API_URI_BASE}/<layout_key>", method="POST")
@wrappers.auth
@wrappers.doc('Importa un archivo .xlsx o .csv según el layout indicado.')
def importar_archivo(layout_key):
    layout = obtener_layout(layout_key)
    if not layout:
        _error(MSG_LAYOUT_INEXISTENTE, 404)
    _validar_rol(layout)
    archivo = request.files.get("file")
    if not archivo or not archivo.filename:
        _error(MSG_SIN_ARCHIVO, 400)
    data = _leer_limitado(archivo, layout.max_bytes)
    try:
        resultado = ImportService.importar(layout, archivo.filename, data, g.current_user.id, database.session)
    except ImportError_ as e:
        _error(e.mensaje, e.status, e.errores)
    return {"success": True, "data": resultado, "error": None}


@wrappers.api_resource(route=f"{API_URI_BASE}/layouts", method="GET")
@wrappers.auth
@wrappers.doc('Lista los layouts de importación disponibles.')
def listar_layouts():
    columnas = lambda l: [{"header": c.header, "required": c.required} for c in l.columns]
    data = [{"key": l.key, "columnas": columnas(l), "max_rows": l.max_rows} for l in LAYOUTS.values()]
    return {"success": True, "data": data, "error": None}
```
Revisar en `wrappers.api_resource` el prefijo real (`/api`) y si la ruta `layouts` choca con `<layout_key>` en el método GET; si choca, Flask resuelve primero la regla estática, así que no hay conflicto.

- [ ] **Step 3:** En `ix/app.py`, junto a la línea 322:
```python
from ix.apps.importador.endpoints import importar_archivo, listar_layouts
```
- [ ] **Step 4:** Run `pytest ix/tests/importador -v` → PASS todo el módulo.
- [ ] **Step 5:** Commit (con confirmación): `feat(importador): endpoints de importación y layouts`.

### Task 7: Aceptación, Bruno y documentación

**Files:**
- Create: `K2Work/bruno/` o colección por skill `k2-bruno` (datos sintéticos)
- Modify: `K2Work/docs/tareas/feat-autorelevo-reporte-avasa.md`, `K2Work/rag/indice-archivos.md`

- [ ] **Step 1:** Levantar el apiserver local apuntando a dev y subir el Excel real (`~/Descargas/...xlsx`) con un usuario admin. Esperado: `total=4404, insertados=0, actualizados=4404` (la tabla ya tiene la carga SQL).
- [ ] **Step 2:** Verificar totales: `bin/k2-sql dev -e "SELECT COUNT(*), SUM(total_contrato), SUM(voucher_total), COUNT(audit_updated_by) FROM autorelevo_contrato_renta"` → `4404 · 56801820.67 · 53474699.88 · 4404`.
- [ ] **Step 3:** Colección Bruno (skill `k2-bruno`): caso feliz, 401, 403 (usuario sin rol), 404, 413, columnas faltantes, fila inválida.
- [ ] **Step 4:** Correr `pytest ix/tests/importador -v` completo y pegar la salida en la tarea.
- [ ] **Step 5:** Documentar en la tarea (Cambios, Pruebas) y agregar `ix/apps/importador/` a `rag/indice-archivos.md` con la nota "agregar layout = un `ImportLayout` en `layouts.py`".
- [ ] **Step 6:** Preparar PR con la skill `k2-git` solo tras confirmación del usuario.
