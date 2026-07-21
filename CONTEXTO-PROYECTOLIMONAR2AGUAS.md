# Contexto del proyecto — Gestión del Agua Limonar Sector II

Pega este documento completo como primer mensaje a Claude Code para que tenga todo el contexto del proyecto sin necesidad de preguntarme nada más a mí.

## Qué es esto
Sitio web comunitario para gestionar el sistema de agua del barrio Limonar Sector II, Soacha, Cundinamarca. Es un sitio estático (un solo `index.html` con CSS y JS embebidos) conectado a Supabase como backend.

## Repositorio y hosting
- Repo GitHub: https://github.com/Mateo2888/GestionDelAguaLinonarSector2 (rama `main`, público)
- Publicado con GitHub Pages en: https://mateo2888.github.io/GestionDelAguaLinonarSector2/
- Archivo principal: `index.html` en la raíz del repo (single-file: HTML + `<style>` + `<script>`)
- Otros archivos en el repo: `supabase-setup.sql` (script de creación de tablas), `INSTRUCCIONES.md` (guía de puesta en marcha)

## Stack técnico
- HTML5 + CSS3 (variables CSS, glassmorphism, modo oscuro vía `data-theme` en `<body>`) + JavaScript vanilla (sin frameworks ni build step)
- Supabase JS v2 cargado por CDN (`https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2`) para: base de datos (Postgres), autenticación (login del panel admin), y storage (fotos de reportes de daño)
- Font Awesome 6.5.1 (CDN) para íconos, Google Fonts (Poppins + Inter)
- Sin backend propio, sin Node/build tools — todo corre en el navegador

## Backend Supabase (ya configurado y en producción)
- Proyecto: `agua-limonar-sector-2`, Project ID: `owhtiqoshemfchrsvsib`
- 8 tablas creadas con `supabase-setup.sql`: `programacion`, `noticias`, `galeria`, `mantenimientos`, `finanzas`, `documentos`, `reportes_dano`, `afiliaciones`
- RLS activado: lectura pública en las tablas de contenido; escritura solo para usuarios autenticados (`auth.role() = 'authenticated'`); `reportes_dano` y `afiliaciones` permiten `insert` público pero `select/update/delete` solo autenticado
- Bucket de Storage `fotos` creado como público (para subir fotos de reportes de daño)
- Ya existe un usuario administrador creado en Authentication > Users (el correo/contraseña los tiene el dueño del proyecto, no yo)
- Las credenciales (`SUPABASE_URL` y `SUPABASE_ANON_KEY`, la "Publishable key") **ya están puestas en `index.html`**, cerca de la línea 795, dentro del `<script>` principal — commit `1cc11ce` "Conectar sitio con Supabase". No las borres ni las regreses a los placeholders `TU_SUPABASE_URL` / `TU_SUPABASE_ANON_KEY`.

## Arquitectura del JS en index.html (para orientarte en el código)
- Bloque de config arriba del `<script>` principal: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, variable `sbClient` (cliente de Supabase) y flag `usingSupabase`.
- Objeto `DEMO` con datos de ejemplo (fallback si Supabase no está configurado) y `STATE` (estado en memoria que se renderiza).
- `loadAll()` trae datos de las 8 tablas de Supabase y llama a las funciones `render*()` de cada sección (programación, noticias, galería, mantenimientos, finanzas, documentos).
- Formularios públicos (`damageForm`, `affiliateForm`) insertan filas en `reportes_dano` y `afiliaciones` vía `insertRow()`.
- Panel administrativo (oculto tras un ícono de candado, login con `sbClient.auth.signInWithPassword`) con pestañas por tabla y funciones `add*()` / `crudDelete()` que hacen insert/delete directo en Supabase.
- Dark mode, menú móvil, contador animado de estadísticas, acordeón FAQ, lightbox de galería, botones flotantes (WhatsApp fijo, volver arriba): todo JS vanilla al final del archivo, sin dependencias externas.

## BUG ACTUAL A CORREGIR (prioridad inmediata)
✅ **Resuelto** — ver "Registro de cambios" al final del documento (commit `e357040`, 2026-07-20). Se deja el detalle abajo como referencia histórica del problema y del arreglo aplicado.

Al conectar Supabase apareció este error en consola del navegador:
```
Uncaught SyntaxError: Identifier 'supabase' has already been declared (at index.html:790:9)
```
**Causa:** la librería `@supabase/supabase-js` crea un global `window.supabase`, y el código del sitio también declaraba `let supabase = null;` — mismo nombre, choque de identificadores, rompe toda la página (nada de CSS/JS corre después de ese error).

**Arreglo necesario** (probablemente ya lo hice en una sesión anterior contigo, Claude Code — verifica primero si ya está aplicado revisando si existe la variable `sbClient` en el archivo; si no, aplícalo):
1. Renombrar `let supabase = null;` → `let sbClient = null;`
2. Renombrar la asignación `supabase = window.supabase.createClient(...)` → `sbClient = window.supabase.createClient(...)` (dejar `window.supabase.createClient` intacto, esa parte SÍ debe seguir diciendo `supabase` porque es la librería).
3. En todo el resto del archivo, todo uso de `supabase.from(`, `supabase.auth.`, `supabase.storage.` (como variable propia, no como `window.supabase`) → cambiar a `sbClient.from(`, `sbClient.auth.`, `sbClient.storage.`
4. Eliminar esta etiqueta duplicada/errónea si sigue en el `<head>` (carga un CSS como si fuera un script, genera un warning de MIME type):
   ```html
   <script src="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" defer></script>
   ```
   (debe quedar solo el `<link rel="stylesheet" href="...font-awesome.../all.min.css">`, no el `<script>`).
5. No tocar `SUPABASE_URL` ni `SUPABASE_ANON_KEY` (ya tienen los valores reales).
6. Verificar sintaxis del JS embebido antes de dar por terminado (extraer el contenido entre `<script>...</script>` del bloque principal y validar, por ejemplo con `node --check`).
7. Commit + push a `main`.

Después de este fix, probar en vivo (esperar 1-2 min por el deploy de GitHub Pages, recargar con Ctrl+Shift+R, revisar la consola del navegador con F12 — no debe haber errores rojos) y confirmar que:
- La sección "Programación" carga las filas de ejemplo desde Supabase (Familia Torres, Familia Ríos, Familia Suárez).
- El candado 🔒 (abajo a la izquierda) abre el modal de login y con el usuario administrador ya creado se puede entrar al panel.
- Desde el panel se puede agregar un registro nuevo y verlo reflejado en la tabla pública tras refrescar.

## Pendientes de personalización (para después de arreglar el bug)
Estos son placeholders que hay que reemplazar con datos reales del barrio, buscando en index.html:
- Número de WhatsApp: aparece como `573000000000` (2 apariciones: botón flotante y formulario de contacto).
- Correo: `contacto@limonarsector2.org`
- Nombre del encargado / contacto: sección `<!-- ============ CONTACTO ============ -->` (actualmente dice "Mateo Castro").
- Fotos: el hero usa un patrón CSS decorativo (no foto); galería y noticias usan imágenes de stock de Unsplash como placeholder — reemplazar por fotos reales del sector cuando el usuario las tenga.
- Datos de ejemplo en Supabase (programación, finanzas, etc.) son de prueba — se pueden editar/borrar desde el panel admin sin tocar código.

## Preferencias del usuario
- El usuario no es programador, trabaja desde VS Code con Claude Code, prefiere que Claude Code haga los cambios de código + git directamente en vez de explicarle paso a paso.
- Priorizó calidad y velocidad ("rápido y excelente") sobre control manual del código.
- **Convención vigente:** cada vez que se haga un cambio importante en el proyecto (arreglar un bug, conectar algo nuevo, agregar una función), Claude Code debe agregar una entrada nueva en "Registro de cambios" (abajo) con fecha, qué se hizo y qué quedó pendiente, para que este documento siempre refleje el estado real del proyecto.

## Registro de cambios

### 2026-07-20 — Conectar sitio con Supabase
**Qué se hizo:** se reemplazaron los placeholders `TU_SUPABASE_URL` / `TU_SUPABASE_ANON_KEY` en `index.html` (~línea 795) por las credenciales reales del proyecto Supabase (`owhtiqoshemfchrsvsib`). Commit `1cc11ce`, push a `main`.
**Qué quedó pendiente:** justo después de este cambio apareció un error en consola por choque de nombres entre la variable propia `supabase` y el global `window.supabase` de la librería (ver entrada siguiente).

### 2026-07-20 — Corregir conflicto de variable `supabase`
**Qué se hizo:** se renombró la variable propia `let supabase` → `let sbClient` en todo `index.html` (declaración, asignación con `window.supabase.createClient(...)`, y todos los usos `.from(`, `.auth.`, `.storage.`), sin tocar `window.supabase.createClient` ni el CDN de `@supabase/supabase-js`. También se eliminó una etiqueta `<script>` duplicada e incorrecta del CDN de Font Awesome en el `<head>` (dejando solo el `<link rel="stylesheet">`). Commit `e357040`, push a `main`.
**Qué quedó pendiente:** probar en vivo tras el deploy de GitHub Pages (Ctrl+Shift+R, revisar consola con F12) para confirmar que ya no aparece el error de `Identifier 'supabase' has already been declared` y que la sección "Programación", el login del panel admin y el alta de registros funcionan correctamente. También siguen pendientes las personalizaciones listadas en "Pendientes de personalización" (WhatsApp, correo, nombre de contacto, fotos reales).
