# CDSPLAT-55 — terminar `git am` en la VDI

Estado al 2026-11-17: `git am` detenido en el patch 06/11 (job + cron). Faltan 06→11.

## Patch 06 (jobs.py / cronjob.py / cron.yaml) — aplicado a mano

En `apiserver/ix/apps/ahio/jobs.py`:

- Agregar `from datetime import datetime, timedelta, timezone`.
- Agregar `APPOINTMENT_TRIGGER_WINDOW = timedelta(hours=1.5)` arriba de `_assign_appointment_case`.
- Quitar el import duplicado de `get_first_ticket_by_case_id_and_ticket_type` (línea 28).
- El import `from ix.apps.ahio.utils import get_provider_coverage_site_by_sap_code` **no existe en dev**
  (se movió a `ix.apps.providers.services` y pide `state_id`, `district_id`). Déjalo así: el patch 11 lo quita.

```powershell
Get-ChildItem -Recurse -Filter *.rej | Remove-Item
git add apiserver/ix/apps/ahio/jobs.py apiserver/ix/apps/ahio/cronjob.py apiserver/cron.yaml
git am --continue
```

Si un patch falla por CRLF: `git am --abort` no; usa `git am --continue` tras aplicar a mano, o reintenta con
`git apply --3way --ignore-whitespace` sobre el hunk.

## Patches 07–10

Tests y ajustes de timezone/ventana. Si chocan, quedarse con la versión del patch (`--theirs`) salvo imports
de `ahio.utils` → `providers.services`.

## Patch 11 — conflicto esperado en `ahio/utils.py`

En dev `ahio/utils.py` ya no tiene `get_provider_coverage_site_by_sap_code`. Resolver agregando al final:

```python
from typing import Optional

from ix.apps.ahio.variables import AhioDefinitions, AhioMessages
from ix.apps.assistance_cases.services import get_assistance_case_by_id
from ix.apps.providers.services import assign_provider, get_provider_coverage_site_by_sap_code
from ix.apps.providers.types import ProviderAssignmentResult


def try_assign_provider_from_ahio_response(case_id: int, response: dict) -> Optional[ProviderAssignmentResult]:
    """Si la respuesta de AHIO ya trae sap_code, resuelve el proveedor en K2 y asigna.
    Devuelve None si AHIO aún no tiene sap_code, para que el caller decida el siguiente paso."""
    sap_code = (
        response
        .get(AhioDefinitions.RESPONSE, {})
        .get(AhioDefinitions.CRANE, {})
        .get(AhioDefinitions.SAP_CODE)
    )
    if not sap_code:
        return None

    case = get_assistance_case_by_id(case_id)
    provider, provider_site, coverage_id = get_provider_coverage_site_by_sap_code(
        sap_code=sap_code,
        state_id=case.state_id,
        district_id=case.state_district_id,
    )
    ...  # resto igual al patch (ProviderAssignmentResult / assign_provider)
```

(Fusionar los imports con los que ya tiene el archivo; `AhioMessages` ya está.)

En los tests del patch 11, el mock debe apuntar a donde se usa:
`patch("ix.apps.ahio.utils.get_provider_coverage_site_by_sap_code")` — sigue válido porque se importa en `ahio.utils`.

## Antes de push

Quitar el trailer de IA del patch 03 (f9ce8ff7, "tratar cita registrada…"):

```powershell
git rebase -i origin/dev   # marcar ese commit como 'reword' y borrar la línea Co-Authored-By
git log origin/dev..HEAD --format='%h %s%n%b' | Select-String Co-Authored   # debe salir vacío
```

Verificar: `python -m pytest apiserver/tests -k ahio` (o el path de tests del patch 07).
