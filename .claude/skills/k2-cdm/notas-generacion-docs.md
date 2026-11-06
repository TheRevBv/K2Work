# Generación de documentos CDM (wordcraft)

- Los documentos que los agentes lean o generen deben estar en `~/Documentos/wordcraft`. Fuera de esa carpeta no pueden leer ni escribir.
  - Plantillas base: `~/Documentos/wordcraft/cdm/plantillas/` (CLL, DIS, PRUEBAS, Manual Técnico).
  - Salidas por ticket: `~/Documentos/wordcraft/cdm/<AÑO>_OM-<PROY>_R<NN>/`.
- El editor del menú abre sin red: los agentes no controlan la ventana abierta y trabajan sin ventana (CLI/MCP).
- El editor gráfico no se ha probado; solo la CLI y el MCP. Si falla al abrir desde el menú, avisar al usuario.
- Claude Code y Codex cargan el MCP de wordcraft solo al iniciar sesión; si no aparece, pedir que reinicie la sesión.
- Aislamiento, instalación, limitaciones y cómo revertir: `~/Proyectos/cachyos-migration/docs/wordcraft.md`. Último recurso: snapshot home #236.
