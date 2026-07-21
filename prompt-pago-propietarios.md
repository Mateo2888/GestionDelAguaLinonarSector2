# Estado de pago ligado al propietario — instrucciones

Esta función ya está implementada en `index.html`. Este documento explica qué hace y el único paso manual que falta.

## Qué se implementó

- La tabla `propietarios` tiene 3 columnas nuevas: `estado_pago` (Pendiente / Al día), `ultimo_pago` (fecha) y `correo`.
- **Panel admin → pestaña "Propietarios / Turnos":** cada propietario tiene ahora un selector de estado de pago, un campo de fecha del último pago, y un campo de correo — todo se guarda con el mismo botón "Guardar" que ya existía. Junto al nombre aparece una insignia visual (verde "Al día" / roja "Pendiente") para ver el estado de un vistazo.
- El buscador que ya existía en esa pestaña (`prSearch`) busca por nombre o código en tiempo real — no hizo falta agregar nada ahí, ya cumplía lo pedido.
- **Consulta pública "Mi turno":** al escribir su código, el propietario ahora ve también su estado de pago (y la fecha del último pago si está "Al día"), junto al resultado de su turno.
- Al guardar un propietario con estado "Al día", se dispara automáticamente la generación y envío del comprobante en PDF (ver `prompt-comprobante-pago.md`).

## Paso manual pendiente

Ejecutar **`agregar-pago-propietarios.sql`** (raíz del repositorio) en Supabase → SQL Editor → Run. Sin este paso, el sitio intentará guardar `estado_pago`/`ultimo_pago`/`correo` y Supabase devolverá un error porque esas columnas todavía no existen.

## Nota de privacidad

La tabla `propietarios` tiene lectura pública (necesaria para que cualquiera consulte su turno sin iniciar sesión) — igual que ya pasaba con nombre, sector y código. Eso significa que la columna `correo` que se agrega también queda técnicamente legible por cualquiera con la llave pública del proyecto, no solo por el administrador. Si prefieres que los correos NO sean públicos, hace falta un cambio adicional (una vista de Supabase que oculte esa columna al público) — avísame si lo quieres y lo implemento aparte.
