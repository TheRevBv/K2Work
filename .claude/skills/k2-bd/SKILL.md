---
name: k2-bd
description: Consulta y prueba SQL en la MySQL local o de dev (proxy GCP) de K2 con el wrapper bin/k2-sql, sin exponer credenciales. Usar para diagnosticar datos, buscar tablas/columnas/valores, reproducir un bug o verificar un fix contra la BD.
---

# SQL en K2 con `bin/k2-sql`

Perfiles: `local` (MySQL local) y `dev` (Cloud SQL por proxy). `test` y `prod` están **bloqueados**; no intentes rodearlo.
Conexiones en `~/.config/k2work/db.<perfil>.env` (no leerlas ni mostrarlas). Si falta el archivo, pedir al usuario que lo cree (ver README).

## Comandos

    bin/k2-sql local -e "SELECT ..."          consulta
    bin/k2-sql local -f datos/<ticket>/01-diagnostico.sql
    bin/k2-sql local tablas <patron>          SHOW TABLES LIKE
    bin/k2-sql local columnas <patron>        columna en todas las tablas
    bin/k2-sql local describe <tabla>
    bin/k2-sql local buscar <valor> <tabla>   valor en columnas de texto

## Escritura

- DML (`INSERT/UPDATE/DELETE/REPLACE`) corre con `ROLLBACK` automático: sirve para simular un flujo y ver el efecto.
- DDL se rechaza sin `--commit` (MySQL lo comitea solo).
- Persistir: preguntar al usuario, mostrar la sentencia y el perfil, y solo con su "sí" usar `--commit`. En `dev` además `K2_CONFIRM_DEV=si bin/k2-sql dev ... --commit`.
- `dev` requiere el proxy activo; si el wrapper avisa que no escucha, pedir al usuario levantarlo (`! cloud-sql-proxy ...`).

## Evidencia

- Scripts en `datos/<ticket>/NN-descripcion.sql`; salida relevante en `NN-descripcion.txt` (`bin/k2-sql ... -f ... | tee datos/<ticket>/NN-descripcion.txt`).
- Referenciar scripts y salidas desde `docs/tareas/<rama>.md` y la matriz QA.
- No guardar datos personales reales de clientes en `datos/`; anonimizar.
