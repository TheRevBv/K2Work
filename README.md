# K2Work

Espacio de apoyo para trabajar con Claude Code en K2 (CDS) y en el micrositio de autorelevo: documentación de tickets, skills, consultas SQL y bitácora diaria.

- Reglas y flujo: [AGENTS.md](AGENTS.md)
- Skills: [skills/README.md](skills/README.md)
- Diseño: [docs/superpowers/specs/2026-10-12-k2work-design.md](docs/superpowers/specs/2026-10-12-k2work-design.md)

## Preparación de BD

Crea `~/.config/k2work/db.local.env` (y `db.dev.env` para el proxy de dev) con permisos 600:

    K2_DB_HOST=127.0.0.1
    K2_DB_PORT=3306
    K2_DB_USER=<usuario>
    K2_DB_PASSWORD=<password>
    K2_DB_NAME=<base>

Uso: `bin/k2-sql local -e "SELECT 1"`.
