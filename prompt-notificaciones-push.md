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
