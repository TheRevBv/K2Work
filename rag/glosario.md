# Glosario

| Término | Significado |
|---|---|
| CDM | Chubb Delivery Model: documento/proceso de entrega que se genera al pasar un cambio (por ejemplo "se generó el CDM para el cambio del webhook") |

## Pólizas de prueba en Chubb SIT (`Policy/SubstituteExp`, verificadas 2026-10-19)

| Clave | Póliza | Inciso | Estado |
|---|---|---|---|
| KD | 39002312 | 1 | Funciona (vigente; caso 67613 en dev) |
| B2 | 39000569 | 1 | Regresa datos pero VENCIDA (2020) |
| BE | 43132157 | 1 | Error "An error has occurred" / datos de vehículo null |
| M9 | 39590099 | 1 | Vigente (MAZDA 3 2010), tiene caso abierto 67607 en dev |

Una póliza con caso abierto responde "La poliza tiene casos abiertos"; usar otra o cerrar el caso.
- **EnforceGitleaks**: ruleset de organización de Mexico-IT en el GitHub del VDI. Exige el status check "Gitleaks Secret Scanning". Un push a una rama ya existente sale rechazado con GH013; crear una rama nueva sí pasa.
