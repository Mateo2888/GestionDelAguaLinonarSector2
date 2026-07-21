# Comprobante de pago en PDF — instrucciones de despliegue

El código del lado del sitio (generar el PDF, intentar enviarlo, y el respaldo manual si falla) ya está implementado en `index.html`. Lo que falta es desplegar la pieza que vive en Supabase y crear la cuenta de correo — son pasos manuales que Claude Code no puede hacer por ti desde este entorno (no hay forma de instalar la CLI de Supabase ni de crear cuentas externas).

## Cómo funciona

1. El administrador marca a un propietario como "Al día" y guarda (pestaña "Propietarios / Turnos").
2. El navegador genera el comprobante en PDF (con jsPDF, ya cargado en el sitio) y lo manda a la función `enviar-comprobante` de Supabase.
3. Esa función usa **Resend** (un servicio de envío de correos, gratis hasta 3.000 correos/mes) para mandar el PDF adjunto al correo del propietario.
4. **Si algo falla** (la función no está desplegada todavía, no hay internet, Resend rechaza el envío, etc.): el PDF se descarga automáticamente en el computador del administrador, y se abre su programa de correo con el destinatario y el mensaje ya escritos, listo para adjuntar el PDF a mano y enviar. **Nunca se pierde el comprobante.**

## Paso 1 — Crear cuenta en Resend (5 minutos)

1. Entra a **resend.com** → crea una cuenta gratis.
2. Ve a **API Keys** → **Create API Key** → dale un nombre (ej. "limonar-sector-2") → copia la key (empieza con `re_...`). Solo la vas a ver una vez.
3. Por defecto, Resend te deja enviar correos de prueba desde `onboarding@resend.dev` sin configurar nada más — sirve para empezar a usar la función ya mismo. Si más adelante quieres que los correos salgan de tu propio dominio (ej. `noreply@limonarsector2.org`), en Resend hay una sección **Domains** para verificarlo — no es necesario para que esto funcione hoy.

## Paso 2 — Crear la Edge Function en Supabase (sin la CLI, todo desde el navegador)

1. En tu proyecto de Supabase, ve a **Edge Functions** (menú izquierdo).
2. **Create a new function** → nómbrala exactamente `enviar-comprobante`.
3. Se abre un editor de código en el navegador. Borra lo que tenga por defecto y pega el contenido completo del archivo `supabase/functions/enviar-comprobante/index.ts` de este repositorio.
4. **Deploy**.

## Paso 3 — Configurar el secreto de la API key

1. En Supabase, ve a **Edge Functions** → **Manage secrets** (o Project Settings → Edge Functions, según la versión del panel).
2. Agrega un secreto nuevo: nombre `RESEND_API_KEY`, valor la key que copiaste en el Paso 1.
3. (Opcional) Si verificaste tu propio dominio en Resend, puedes agregar otro secreto `RESEND_FROM` con el remitente que quieras usar, por ejemplo `Gestión del Agua Limonar Sector II <noreply@tudominio.org>`. Si no lo agregas, se usa la dirección de pruebas de Resend automáticamente.

## Paso 4 — Probar

1. Entra al panel admin del sitio → "Propietarios / Turnos".
2. Asegúrate de que el propietario de prueba tenga un correo real cargado en el campo "correo".
3. Márcalo como "Al día" y dale **Guardar**.
4. Si todo quedó bien configurado, debería llegar un correo con el PDF adjunto en unos segundos, y el sitio muestra "Comprobante enviado a [correo]". Si en vez de eso se descarga un PDF y se abre tu programa de correo, algo del Paso 2 o 3 no quedó bien — revisa que el nombre de la función sea exactamente `enviar-comprobante` y que el secreto `RESEND_API_KEY` esté guardado.

## Nota importante

Mientras no completes estos 3 pasos, la función automática de correo simplemente **no va a funcionar** — pero el sitio no se rompe: cada vez que marques a alguien como "Al día", se activa el respaldo manual (descarga el PDF + abre tu correo con todo prellenado) de forma automática. Es decir, puedes usar la función de comprobantes desde ya, solo que sin el envío automático hasta que despliegues esto.
