# BUG-6966BCD8 — "Consultar estatus" termina en crear solicitud (micrositio)

Reabierto 1x (12 nov 2026). Reporta Ian Téllez; asignado a Jeffrey Mikel.

## Causa
- "Consultar estatus" (bienvenida y num-siniestro) navega a `/estado`; `authGuard` redirige a `/auth/login` y la intención se pierde.
- Tras el OTP, `otp.component.ts#checkActiveTicket` busca un ticket abierto por póliza; si no hay, manda a `/solicitud/servicio`.
- `num-siniestro.component.ts#onContinuar` valida el siniestro y siempre navega a `/solicitud/captura` (alta).

## Fix (micrositio-autorelevo-real, rama dev, sin commit)
- `SolicitudService.marcarConsulta/enConsulta`: bandera en `sessionStorage` (`ar_modo_consulta`), fuera de `ar_solicitud_state` porque ese estado se reinicia al cambiar la póliza en el login.
- `authGuard` marca consulta cuando la URL bloqueada es `/estado*`; "Iniciar solicitud" la limpia.
- OTP sin ticket abierto en modo consulta → `/solicitud/siniestro`.
- num-siniestro en modo consulta → `buscarTicketActivo(poliza, siniestro)`; si hay ticket → `/estado`, si no → error, nunca captura.
