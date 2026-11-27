"""Aplica BUG-56B60FEE en la raíz de K2-Full-Portal sin depender del contexto ni de CRLF.

Uso: python aplicar_fix.py   (desde la raíz del repo)
"""
import re
from pathlib import Path

RELEVO = Path("admin/src/app/app-models/api/relevo")
CAMBIOS = [
    (
        "apiserver/ix/boletas_informativas/auto_relevo/api/auto_relevo_boleta/auto_relevo_boleta_service.py",
        r'^([ \t]*)"motivo_servicio_id": \(payload\.get\("boleta_informativa"\) or \{\}\)\.get\("motivo_servicio_id"\),',
        r'\1**{k: (payload.get("boleta_informativa") or {}).get(k)\n\1   for k in ("motivo_servicio_id", "estado_entrega_id", "municipio_entrega_id")},',
    ),
    (
        "admin/src/app/app-modules/relevo-car/list/list.component.html",
        r"rowData\.BoletaInformativa\?\.MotivoServicio\?\.nombre",
        "rowData.MotivoServicio?.nombre",
    ),
    (
        "admin/src/app/app-modules/relevo-car/list/list.component.html",
        r"detailTicket\?\.BoletaInformativa\?\.MotivoServicio\?\.nombre",
        "detailTicket?.MotivoServicio?.nombre",
    ),
    (
        str(RELEVO / "relevo_ticket_boleta_informativa.model.ts"),
        r"^[ \t]*MotivoServicio\?: RelevoTicketMotivoServicioModel \| null;[ \t]*\n",
        "",
    ),
    (
        str(RELEVO / "relevo_ticket_form.model.ts"),
        r"\{ RelevoTicketBoletaInformativaModel \}",
        "{ RelevoTicketBoletaInformativaModel, RelevoTicketMotivoServicioModel }",
    ),
    (
        str(RELEVO / "relevo_ticket_form.model.ts"),
        r"^([ \t]*)BoletaInformativa: RelevoTicketBoletaInformativaModel,[ \t]*\n",
        r"\g<0>\1MotivoServicio?: RelevoTicketMotivoServicioModel | null,\n",
    ),
]

for ruta, patron, reemplazo in CAMBIOS:
    p = Path(ruta)
    crudo = p.read_bytes().decode("utf-8")
    crlf = "\r\n" in crudo
    texto = crudo.replace("\r\n", "\n")
    nuevo, n = re.subn(patron, reemplazo, texto, count=1, flags=re.M)
    if n == 0:
        print(f"SIN CAMBIO (revisar a mano): {ruta} :: {patron}")
        continue
    p.write_bytes((nuevo.replace("\n", "\r\n") if crlf else nuevo).encode("utf-8"))
    print(f"ok: {ruta}")
