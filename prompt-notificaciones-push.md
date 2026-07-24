# Notificaciones push + voz — instrucciones de despliegue

El código del sitio (botón "Activar notificaciones", service worker, avisos por voz) ya está implementado. Faltan pasos manuales en Supabase — igual que con el comprobante de pago, no hay forma de hacerlos desde este entorno (no hay CLI de Supabase instalada, y crear/programar cosas en el dashboard es una acción tuya).

## Cómo funciona

- **Con la página abierta:** cuando alguien consulta su turno en "Mi turno" y toca "Activar notificaciones", el navegador programa avisos por **voz** (10 min antes, al iniciar, 5 min antes de terminar) mientras la pestaña siga abierta.
- **Con la página cerrada o el celular bloqueado:** un cron en Supabase revisa cada minuto si algún propietario suscrito tiene un turno por empezar/terminar, y le manda una **notificación push real** del sistema operativo (Service Worker + Web Push).
- **iPhone:** las notificaciones push solo funcionan si el propietario agrega el sitio a su pantalla de inicio primero (Compartir → "Agregar a pantalla de inicio", iOS 16.4+) — ya hay un aviso de esto junto al botón de activar notificaciones.

## Paso 1 — Ejecutar el SQL de la tabla de suscripciones

Copia y pega **`push-suscripciones-setup.sql`** en Supabase → SQL Editor → Run.

## Paso 2 — Desplegar la Edge Function (desde el navegador, sin CLI)

1. Supabase → **Edge Functions** → **Create a new function** → nómbrala exactamente `notificar-turnos`.
2. Copia todo el contenido de `supabase/functions/notificar-turnos/index.ts` de este repo y pégalo en el editor.
3. **Deploy**.
4. Verifica el nombre con cuidado — la última vez que desplegamos una función así, quedó con una letra faltante y hubo que borrarla y crearla de nuevo. Revisa que diga exactamente `notificar-turnos`.

## Paso 3 — Configurar los secretos VAPID

Supabase → Edge Functions → **Manage secrets** → agrega estos dos:

- `VAPID_PUBLIC_KEY` → `BFWdWGonS8jIrQbgphvIlGzsN040KcqvYIcBtAY4441FtkhGLaaEinVBIA1o04MfxdVFnj0MaW3fkB9gVCnQ7gw`
- `VAPID_PRIVATE_KEY` → la clave privada que Claude Code generó y te mostró en el chat (no se guardó en ningún archivo del repo por seguridad — cópiala de ahí).

(`SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` los provee Supabase automáticamente a toda función, no hace falta agregarlos.)

## Paso 4 — Ejecutar el SQL del cron

Copia y pega **`cron-notificaciones-setup.sql`** en Supabase → SQL Editor → Run. Esto programa que la función se dispare cada minuto. Habilita las extensiones `pg_cron` y `pg_net` automáticamente si no estaban activas.

## Paso 5 — Probar

1. Entra al sitio en tu celular, ve a "Mi turno", consulta un código real, y toca "Activar notificaciones". Acepta el permiso que pida el navegador.
2. Para probar rápido sin esperar tu turno real: en el panel admin, edita ese propietario y fuerza un turno manual ("Anular turno automático") que empiece dentro de 10-11 minutos desde ahora.
3. Cierra la página o bloquea el celular y espera — deberías recibir la notificación push del sistema operativo cerca del minuto 10 antes de empezar.
4. Si tienes la página abierta en el navegador (no hace falta cerrarla para esta prueba), también deberías escuchar el aviso por voz.

## Nota importante sobre el paquete `web-push` en Deno

La Edge Function usa la librería `web-push` (pensada originalmente para Node) cargada vía `esm.sh` con `?target=deno` para mejorar su compatibilidad — es la forma recomendada de usarla en Supabase, pero **no la pude probar de verdad** (no hay forma de desplegar/ejecutar Edge Functions desde este entorno). Es posible que al desplegarla haga falta algún ajuste si Deno reporta un error de importación — si eso pasa, avísame el mensaje de error exacto y lo resolvemos.

---

## Ampliación: avisos de reportes/afiliaciones (admin ↔ vecinos)

Adicional a los turnos de agua, ahora también se avisa:
- **Al administrador**, cuando llega un reporte de daño o una solicitud de afiliación nueva.
- **Al vecino que reportó o se afilió**, cuando el administrador cambia el estado de SU solicitud (si activó el aviso al enviarla).

Reutiliza toda la infraestructura ya desplegada (mismo service worker, mismos secretos VAPID) — solo faltan estos pasos adicionales:

### Paso 6 — Ejecutar el SQL que permite varios avisos por dispositivo

Copia y pega **`push-suscripciones-multiproposito.sql`** en Supabase → SQL Editor → Run. Esto corrige que un mismo celular (por ejemplo, el tuyo como administrador) pueda estar suscrito a la vez a "mi turno" Y a "avísame de reportes nuevos", sin que uno pise al otro.

### Paso 7 — Desplegar la segunda Edge Function

Mismo procedimiento que con `notificar-turnos`:
1. Supabase → Edge Functions → **Create a new function** → nómbrala exactamente `enviar-notificacion` (revisa el nombre con cuidado, letra por letra).
2. Copia todo el contenido de `supabase/functions/enviar-notificacion/index.ts` y pégalo en el editor.
3. **Deploy**.
4. En **Function configuration**, apaga **"Verify JWT with legacy secret"** (igual que se hizo con `enviar-comprobante`, para evitar el error 403 al llamarla desde el sitio con la sesión del administrador).

No hace falta configurar ningún secreto nuevo — `enviar-notificacion` reutiliza `VAPID_PUBLIC_KEY`/`VAPID_PRIVATE_KEY`, que son secretos de todo el proyecto, no de una función en particular.

### Paso 8 — Probar

1. Como administrador: entra al panel admin → toca el nuevo botón **"Notificarme"** (junto a "Salir") → acepta el permiso.
2. Desde otro celular (o el navegador en modo incógnito), entra al sitio público y envía un "Reporte de daño" de prueba. Deberías recibir la notificación push como administrador en unos segundos.
3. Al enviar el reporte, aparece un botón **"Avisarme cuando actualicen mi reporte"** — actívalo desde ese mismo dispositivo/navegador.
4. Vuelve al panel admin, busca ese reporte en la pestaña "Reportes de daño", y cambia su estado (por ejemplo a "En proceso"). El dispositivo que activó el aviso en el paso 3 debería recibir la notificación de que su reporte se actualizó.
5. Repite lo mismo con el formulario "Quiero afiliarme" si quieres probar también ese flujo.
