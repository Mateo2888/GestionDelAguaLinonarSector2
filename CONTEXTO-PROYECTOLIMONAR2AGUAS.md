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

## Pendientes de personalización
- ~~Número de WhatsApp~~ ✅ ya actualizado a `+57 317 042 7446` (ver Registro de cambios).
- ~~Correo~~ ✅ ya actualizado a `gestionagualimonall@gmail.com` (ver Registro de cambios).
- Nombre del encargado / contacto: sección `<!-- ============ CONTACTO ============ -->` — el usuario confirmó que "Mateo Castro" ya es el nombre real, no requiere cambio.
- Fotos: el hero usa un patrón CSS decorativo (no foto); galería y noticias usan imágenes de stock de Unsplash como placeholder — el usuario no tiene fotos reales a mano todavía, queda pendiente para cuando las tenga.
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

### 2026-07-20 — Personalizar WhatsApp y correo de contacto
**Qué se hizo:** en `index.html` se reemplazó el número de WhatsApp placeholder (`573000000000`) por el real `+57 317 042 7446` en las 4 apariciones (ícono flotante `fab-whats`, enlace `tel:`, texto visible en "Contacto", y la función JS que abre `wa.me` con el mensaje del formulario de reporte de daño). También se reemplazó el correo placeholder `contacto@limonarsector2.org` por el real `gestionagualimonall@gmail.com` en la sección de contacto.
**Qué quedó pendiente:** faltan las fotos reales del sector (hero, galería, noticias siguen con imágenes de stock/patrón CSS) — el usuario las agregará cuando las tenga. El nombre del encargado ("Mateo Castro") y los datos de ejemplo en Supabase no requieren cambio por ahora.

### 2026-07-20 — Manejo de errores de Supabase (red y datos)
**Qué se hizo:** en `index.html` se mejoró el manejo de errores en las llamadas a Supabase, que antes solo registraban fallos en consola (`console.warn`) sin avisar al usuario:
- `loadAll()`: ahora distingue si fallan todas las tablas (aviso "No se pudo conectar con la base de datos, mostrando datos de ejemplo") o solo algunas (aviso "Algunas secciones no cargaron datos actualizados, recarga la página"), en vez de fallar en silencio.
- `insertRow()`, `crudInsert()`, `crudDelete()`, login (`signInWithPassword`): se les agregó `try/catch` para capturar fallos de red (antes solo se manejaba el `error` que devuelve Supabase, no una excepción por falta de conexión), mostrando un toast claro pidiendo revisar la conexión a internet.
- Subida de foto en el formulario de reporte de daño: si falla la subida a Supabase Storage, ahora se avisa con un toast ("No se pudo subir la foto, se enviará el reporte sin ella") en vez de continuar en silencio sin la foto.
Se validó la sintaxis del bloque `<script>` con `node --check` antes de confirmar. Commit pendiente de push en este mismo mensaje de registro.
**Qué quedó pendiente:** no se agregó un indicador visual de "cargando" (spinner/skeleton) mientras `loadAll()` trae los datos la primera vez — por ahora solo se avisa si algo falla, no mientras carga. Seguir pendientes: fotos reales del sector, y las demás mejoras no elegidas en esta ronda (SEO/redes sociales, revisión de datos de ejemplo en Supabase, accesibilidad/mobile).

### 2026-07-21 — Eliminar datos de prueba y vaciar respaldo local
**Qué se hizo:** se verificó con una consulta de solo lectura a la API de Supabase (usando la llave pública) qué tablas tenían datos de prueba reales en producción: `programacion` (3 filas: Familia Torres, Familia Ríos, Familia Suárez) y `finanzas` (2 filas: Aportes mensuales, Compra de manguera) — ambas sembradas por `supabase-setup.sql`. `noticias`, `galeria`, `mantenimientos` y `documentos` ya estaban vacías. `reportes_dano` y `afiliaciones` no se pudieron revisar (RLS bloquea lectura sin sesión de admin) pero el usuario confirmó que no hizo pruebas ahí.
En `index.html` se vació por completo el objeto `DEMO` (el respaldo local que se usa solo si el sitio no logra conectarse a Supabase) — antes tenía datos falsos (Familia Torres, noticias de ejemplo, fotos de stock de Unsplash, etc.), ahora son arreglos vacíos, así el sitio nunca muestra información inventada a un visitante real. Se corrigió también el texto del aviso de error de conexión total, que antes decía "mostrando datos de ejemplo" (ya no aplica) y ahora dice "recarga la página o intenta más tarde".
En `supabase-setup.sql` se eliminó la sección final `-- DATOS DE EJEMPLO` (los `insert` de prueba para `programacion` y `finanzas`), para que si el script se vuelve a ejecutar en otro proyecto no siembre datos falsos.
**Qué quedó pendiente:** las 5 filas de prueba que siguen en la base de datos EN VIVO (`programacion` x3, `finanzas` x2) no se pudieron borrar desde aquí — Supabase las protege con RLS y solo un administrador autenticado puede borrarlas. El usuario las borrará manualmente entrando al candado 🔒 del sitio, iniciando sesión como admin, y usando el botón de basura en cada fila de las pestañas "Programación" y "Transparencia". También se detectó (resuelto en la siguiente entrada) que el panel admin no tenía pestaña para ver/gestionar `reportes_dano` ni `afiliaciones`.

### 2026-07-21 — Agregar pestañas "Reportes de daño" y "Afiliaciones" al panel admin
**Qué se hizo:** en `index.html` se agregaron dos pestañas nuevas al panel administrativo (antes solo existían para Programación, Noticias, Galería, Mantenimientos, Transparencia y Documentos):
- **Reportes de daño**: lista los reportes enviados por el formulario público (nombre, sector, dirección, descripción, foto si tiene), con un selector de estado (Nuevo / En proceso / Resuelto) y botón para borrar.
- **Afiliaciones**: lista las solicitudes enviadas por el formulario público (nombre, sector, dirección, teléfono), con un selector de estado (Pendiente / Aprobada / Rechazada) y botón para borrar.
Estas dos tablas solo se cargan (`loadAdminExtras()`) después de iniciar sesión como admin —no antes, porque la política RLS de Supabase bloquea la lectura pública de esas tablas a propósito (contienen datos personales de vecinos)— y se limpian de `STATE` al cerrar sesión, para no dejar datos sensibles en memoria. Se agregó `crudUpdateEstado()` para cambiar el estado desde el selector, usando las políticas de `update` que ya existían en `supabase-setup.sql`.
Durante la implementación se encontró y corrigió un bug antes de publicarlo: `localName()` no reconocía las tablas `reportes_dano` ni `afiliaciones`, lo que habría roto el botón de borrar (el registro se habría borrado en Supabase pero el código habría fallado justo después, sin refrescar la lista ni avisar del error). Se agregó el mapeo faltante.
Se validó sintaxis JS (`node --check`) y balance de `<div>` (197/197) antes de confirmar.
**Qué quedó pendiente:** no se agregó paginación ni filtro/búsqueda en estas dos listas nuevas (no debería ser un problema mientras el volumen de reportes/afiliaciones sea bajo). Seguir pendientes de rondas anteriores: fotos reales del sector, indicador de "cargando", SEO/redes sociales, accesibilidad/mobile.

### 2026-07-21 — SEO y redes sociales
**Qué se hizo:** en `index.html` se completaron las etiquetas de cabecera para compartir el link y para buscadores (ya existían título, descripción y algunas etiquetas Open Graph básicas):
- `<link rel="canonical">` y `og:url` apuntando a la URL real de GitHub Pages.
- `og:site_name` y `og:locale` (`es_CO`).
- Etiquetas Twitter Card (`twitter:card`, `twitter:title`, `twitter:description`).
- Datos estructurados JSON-LD tipo `Organization` con nombre, URL, descripción, correo (`gestionagualimonall@gmail.com`), teléfono (`+573170427446`) y dirección (Soacha, Cundinamarca, CO) — ayuda a que Google entienda de qué trata el sitio y quién es el contacto.
Se crearon dos archivos nuevos en la raíz del repo: `robots.txt` (permite indexar todo, apunta al sitemap) y `sitemap.xml` (una sola URL, la página principal).
Se validó: JSON-LD es JSON válido, sitemap es XML válido, sintaxis JS sigue OK y `<div>`/`<head>` balanceados.
**Qué quedó pendiente:** no se agregó `og:image` ni `twitter:image` (la vista previa al compartir el link en WhatsApp/Facebook seguirá sin miniatura) — este entorno no tiene herramientas para generar/rasterizar una imagen de buena calidad, y además no hay fotos reales del sector todavía (mismo pendiente de siempre). Cuando el usuario tenga un logo o foto representativa, agregar esas dos etiquetas con la URL de esa imagen.

### 2026-07-21 — Indicador de "cargando" y accesibilidad
**Qué se hizo:** dos mejoras en `index.html`, agrupadas en el mismo commit:
- **Indicador de carga:** mientras `loadAll()` trae los datos de Supabase por primera vez, las secciones (Programación, Noticias, Galería, Mantenimientos, Transparencia, Documentos) ahora muestran un spinner con "Cargando..." en vez de verse vacías sin explicación. Se agregó la función `showLoadingState()` y la clase CSS `.loading-state`.
- **Accesibilidad**, revisando el HTML real en vez de asumir problemas genéricos (se midió contraste de color con la fórmula WCAG y todos los pares texto/fondo del sitio ya pasaban AA cómodamente, así que no se tocó eso):
  - Los `<label>` de los 4 formularios (reportar daño, contacto, afiliación, login) no estaban asociados a su campo (`for`/`id` faltante) — un lector de pantalla no sabía a qué campo correspondía cada etiqueta. Se agregó `id` a cada campo y `for` a cada label (12 en total), verificado que todos coincidan.
  - El acordeón de preguntas frecuentes y las fotos de la galería eran `<div>` con `onclick`, invisibles para navegación por teclado. El acordeón ahora tiene `role="button"`, `tabindex="0"`, `aria-expanded` sincronizado, y responde a Enter/Espacio. Las fotos de la galería pasaron de `<div>` a `<button>` real con `aria-label` descriptivo.
  - Botones de solo ícono sin nombre accesible (menú hamburguesa, cerrar menú, cerrar imagen ampliada) recibieron `aria-label`; el botón de cerrar del lightbox pasó de `<span>` a `<button>`. El menú hamburguesa ahora sincroniza `aria-expanded`.
  - Imágenes sin `alt` o con `alt=""` no justificado: fotos de galería (ahora descritas por el `aria-label` del botón que las contiene, así que el `<img>` queda `alt=""` a propósito para no duplicar), foto de mantenimiento (ahora usa la actividad como alt), miniaturas del panel admin (galería y reportes de daño).
  - Se agregó un enlace "Saltar al contenido" (`.skip-link`), visible solo al enfocarlo con teclado, antes del menú de navegación.
Se validó: sintaxis JS (`node --check`), balance de `<div>`/`<button>`/`<span>`/`<form>`/`<label>`, y que cada `for=` de los labels tenga un `id=` real correspondiente (12/12 coinciden).
**Qué quedó pendiente:** no se tocó el enfoque visual (outline) de los campos de formulario al hacer foco — ya cambia de color/fondo al enfocar y cumple el mínimo de la norma, así que se dejó como estaba para no alterar el diseño sin necesidad. Tampoco se ajustó el tamaño de los botones flotantes/hamburguesa (40px, ligeramente por debajo del recomendado de 44px) por ser un desvío menor. Seguir pendientes de siempre: fotos reales del sector, `og:image`.

### 2026-07-21 — Contabilidad y finanzas completo
**Qué se hizo:** ampliación grande de la sección Transparencia/Finanzas en `index.html`, con dos archivos SQL nuevos para aplicar en Supabase (ver "Qué quedó pendiente", es un paso manual obligatorio):
- **Categorías:** cada movimiento ahora puede tener una categoría (Aportes, Donaciones, Mantenimiento, Compras, Pago a encargados, Otro) — select tanto en el formulario admin como en un filtro nuevo en la tabla pública.
- **Editar movimientos:** antes solo se podía agregar o borrar; ahora cada fila en el panel admin tiene un botón de lápiz que carga el registro en el formulario para corregirlo (fecha, concepto, categoría, tipo, valor) y guardarlo con "Guardar cambios" en vez de crear uno nuevo. Se agregó la función genérica `crudUpdate(table, id, row)`.
- **Filtro por mes/año y búsqueda:** en la tabla pública de Transparencia se agregó una barra de búsqueda por concepto, filtro por categoría, y filtro por mes (las opciones de mes se generan automáticamente según los datos reales, vía `populateFinMesFilter()`). Las tarjetas de resumen (ingresos/gastos/saldo) siempre muestran el total real sin filtrar, para no confundir "lo que se ve en la tabla" con "el balance real".
- **Comprobante adjunto:** el formulario admin ahora permite subir una foto del recibo/comprobante (mismo bucket de Supabase Storage que las fotos de reportes de daño, carpeta `comprobantes/`). Se muestra como ícono de recibo enlazado, tanto en la tabla pública (coherente con el espíritu de "Transparencia") como en el panel admin.
- **Control de pagos de mensualidad por vivienda (nueva pestaña "Mensualidades" en el panel admin, SOLO administrador):** el usuario decidió explícitamente que esto NO sea público (a diferencia de Programación) por ser información financiera individual de cada vecino. Sigue el mismo patrón que Reportes de daño/Afiliaciones: se carga solo tras iniciar sesión (`loadAdminExtras()` ahora también trae `mensualidades`) y se limpia de `STATE` al cerrar sesión. Cada registro: vivienda, sector, mes, estado (Pagado/Pendiente/Atrasado, cambiable con un selector como en Reportes/Afiliaciones), valor (prellenado en $25.000, el valor mensual publicado en la sección de precios).
- Se creó **`supabase-migracion-finanzas.sql`** (nuevo archivo en la raíz del repo) con los cambios de esquema: agrega columnas `categoria` y `comprobante` a `finanzas`, y crea la tabla `mensualidades` con RLS activado y una sola política (`for all using auth.role() = 'authenticated'`) — sin política de lectura pública, para que quede completamente privada. También se actualizó `supabase-setup.sql` para que instalaciones nuevas ya incluyan este esquema desde el inicio.
Se validó exhaustivamente antes de publicar: sintaxis JS (`node --check`), balance de `<div>`/`<button>`/`<span>`/`<form>`/`<label>`/`<select>`/`<table>`/`<tr>`, cero ids duplicados en todo el archivo, y que cada `getElementById(...)` referenciado en el JS tenga un elemento real con ese id en el HTML (52/52 coinciden) — este último chequeo habría detectado el mismo tipo de bug que se encontró y corrigió la sesión pasada con `localName()`.
**Qué quedó pendiente (acción manual obligatoria del usuario):** el código ya está publicado y espera las columnas/tabla nuevas, pero **no funcionará hasta que el usuario ejecute `supabase-migracion-finanzas.sql`** en Supabase Dashboard > SQL Editor (una sola vez). Mientras tanto el sitio no se rompe — gracias al manejo de errores ya implementado, mostrará un toast claro ("No se pudieron cargar las mensualidades", o el error de Supabase al guardar) en vez de fallar en silencio, pero la función de categorías/comprobante/mensualidades no operará hasta correr la migración. No se agregó edición de campos múltiples para Mensualidades (solo cambio rápido de estado + borrar, igual que Reportes/Afiliaciones) — si luego se necesita corregir vivienda/sector/mes/valor de un registro ya creado, habría que borrarlo y crearlo de nuevo, o pedir que se agregue edición completa ahí también.

**2026-07-21, seguimiento:** el usuario confirmó haber ejecutado `supabase-migracion-finanzas.sql` ("Success. No rows returned"). Se verificó con consultas de solo lectura a la API que `finanzas` ya tiene las columnas `categoria`/`comprobante` (0 filas — el usuario ya había borrado las 2 de prueba) y que `mensualidades` existe y está correctamente protegida (HTTP 200 con `[]` para un visitante anónimo, no el 404 de "tabla no encontrada"). El módulo de Contabilidad y Finanzas quedó completamente operativo.

### 2026-07-21 — Hacer privada toda la sección "Transparencia"
**Qué se hizo:** el usuario pidió explícitamente que la sección pública "Transparencia" (que mostraba ingresos/gastos y documentos como el Reglamento y el Balance en PDF) dejara de ser visible para cualquier visitante, y que fuera de verdad privada (no solo oculta visualmente) — confirmó ambas cosas: ocultar el bloque completo (finanzas + documentos, no solo la parte financiera) y proteger los datos también a nivel de base de datos.
- Se eliminó por completo la sección pública `<section id="documentos">` de `index.html` (tarjetas de resumen, filtros, tabla de finanzas y grilla de documentos), junto con sus enlaces de navegación (menú móvil y footer) y se actualizó la pregunta del FAQ "¿Dónde veo en qué se gasta el dinero?" para ya no referenciar una sección pública que dejó de existir. También se quitó "y transparencia" de la meta descripción SEO, para no anunciar una función que ya no es pública.
- La tabla de finanzas (con búsqueda, filtro por categoría/mes, tarjetas de resumen, y ahora botones de editar/borrar en cada fila) se **reubicó dentro de la pestaña "Transparencia" del panel admin**, reemplazando la lista simple que había ahí. Los documentos siguen gestionándose desde su lista existente en el panel admin (sin cambios ahí).
- `finanzas` y `documentos` se sacaron de la carga pública (`loadAll()`) y pasaron a cargarse solo tras iniciar sesión, junto con reportes/afiliaciones/mensualidades (`loadAdminExtras()`), y se limpian de `STATE` al cerrar sesión — mismo patrón de privacidad ya usado para esas tres tablas.
- Se creó **`supabase-migracion-transparencia-privada.sql`** (nuevo archivo, acción manual pendiente del usuario) que elimina las políticas de lectura pública de `finanzas` y `documentos` en Supabase — sin esa política, esas tablas quedan completamente bloqueadas para cualquier visitante no autenticado, usando la política de administrador que ya existía. También se actualizó `supabase-setup.sql` para que instalaciones nuevas ya nazcan con `finanzas`/`documentos` privados.
- **Bug encontrado y corregido antes de publicar:** al eliminar la función `renderDocumentos()` (ya no hacía falta, no queda contenedor público), se me había quedado una llamada huérfana a `renderDocumentos()` dentro de `refreshAll()` — eso habría roto el panel admin completo (con un `ReferenceError`) cada vez que se agregara o borrara cualquier registro en cualquier pestaña, no solo en Documentos. Se detectó al validar sistemáticamente cada función invocada en `onclick`/`.then()` contra las funciones realmente definidas, y se corrigió quitando esa llamada.
Se validó exhaustivamente: sintaxis JS, balance de todas las etiquetas relevantes, cero ids duplicados, cada `getElementById(...)` con su elemento real, y cada función usada en `onclick="..."` o `.then(...)` con su definición real (14 y 1 respectivamente, todas encontradas).
**Qué quedó pendiente (acción manual obligatoria del usuario):** ejecutar `supabase-migracion-transparencia-privada.sql` en Supabase SQL Editor (una sola vez) — sin este paso, la tabla técnicamente sigue siendo leíble por cualquiera con la llave pública (aunque ya no se vea en la página), igual que pasó con la migración anterior. Nota menor sin resolver: la pestaña del panel admin se sigue llamando "Transparencia" internamente, un poco irónico ahora que es privada — se puede renombrar si se quiere, no se tocó por no ser parte de lo pedido.

**2026-07-21, seguimiento:** el usuario confirmó haber ejecutado `supabase-migracion-transparencia-privada.sql` ("Success. No rows returned"). Se verificó con consultas de solo lectura que `finanzas` y `documentos` devuelven HTTP 200 con `[]` para un visitante anónimo (existen pero están bloqueadas por RLS), a diferencia del HTTP 404 real de una tabla inexistente. Quedó completamente confirmado: privado tanto visualmente como a nivel de base de datos.

### 2026-07-21 — Rediseño visual: paleta, tipografía y hero más modernos
**Qué se hizo:** el usuario pidió "mejorar el diseño, algo más profesional y moderno", sin referencia específica (pidió usar criterio propio) y marcando las 4 áreas: colores, tipografía, hero, y componentes en general. **Importante: este entorno no tiene navegador ni herramienta de captura de pantalla disponible** (se intentó vía el skill `run`/`chromium-cli`, no está instalado) — todo este trabajo se hizo a ciegas, solo sobre el código, sin poder verlo renderizado. Se le avisó al usuario antes de empezar.
- **Paleta de colores:** se reemplazó el azul genérico tipo "Bootstrap" (`--blue:#1565C0`, `--blue-deep:#0D47A1`, `--sky:#03A9F4`) por un azul-teal más distintivo y acorde al tema de agua (`--blue:#0C7A9E`, `--blue-deep:#073B54`, `--sky:#1EC4D6`). Se verificó contraste WCAG antes de elegir estos valores (blue-deep 11.9:1, blue 4.9:1 contra blanco — ambos pasan AA cómodo; sky se mantuvo como acento decorativo brillante, igual que el original, no pensado para texto sólido). Se actualizaron TODOS los usos de esos colores "hardcodeados" en rgba() que no pasaban por la variable CSS (sombras de botones, fondos de badges, el ícono de la pestaña del navegador/favicon) para que no quedara una paleta a medias.
- **Tipografía:** se aumentó ligeramente la escala del título del hero (`clamp(2.2rem,5.5vw,3.6rem)` → `clamp(2.4rem,6vw,4.1rem)`) y de los títulos de sección (`clamp(1.7rem,3.2vw,2.5rem)` → `clamp(1.85rem,3.6vw,2.75rem)`), y se ajustó el `letter-spacing` de todos los encabezados para una sensación más editorial/cuidada.
- **Hero:** se enriqueció el degradado de fondo (ahora en diagonal en vez de vertical, con dos capas adicionales de resplandor radial tipo "mesh gradient") para más profundidad, manteniendo las ondas (ripples) animadas que ya existían.
- **Componentes:** se aumentó la profundidad de las sombras globales (`--shadow`/`--shadow-sm`, usadas por todas las tarjetas, tablas, modales y timeline del sitio) para una sensación más "flotante". Se agregó sombra de color a los `icon-tile` (los íconos redondeados de la sección Nosotros). El botón principal pasó de un degradado de 2 colores a uno de 3 paradas (oscuro→medio→claro) para verse más rico y, de paso, mejorar el contraste del texto blanco.
Se validó: balance de llaves `{}` del CSS (228/228), sintaxis JS intacta (no se tocó JS, solo un estilo inline de un botón), y se confirmó que no quedó ningún color antiguo (`03A9F4`/`1565C0`/`0D47A1`) sin reemplazar en todo el archivo.
**Qué quedó pendiente:** esto es un trabajo hecho completamente a ciegas — el usuario DEBE revisar el sitio en vivo (esperar el deploy de GitHub Pages, Ctrl+Shift+R) y decir específicamente qué funciona y qué no, para poder ajustar con precisión en vez de seguir adivinando. No se tocó el HTML/estructura de ninguna sección, ni el modo oscuro (los nuevos colores aplican igual en ambos temas por diseño, no se verificó visualmente). No se agregó ninguna foto real (sigue pendiente de siempre) ni se cambió la fuente tipográfica (se mantuvo Poppins/Inter).

### 2026-07-21 — Sectores 1-10, estadísticas reales del hero, y bug de contraste en modo oscuro
**Qué se hizo:**
- **Sectores hasta el 10:** los 3 `<select>` de sector que existían en el sitio (filtro de Programación, formulario de Reportar daño, formulario de Afiliación) solo tenían "Sector 1" y "Sector 2" como opciones — se ampliaron a Sector 1 a Sector 10. Los campos de sector en el panel admin (Programación, Mensualidades) ya eran de texto libre, no seleccionables, así que no necesitaban cambio.
- **Estadísticas del hero conectadas a datos reales:** las tarjetas "Viviendas" (antes fijo en 300) y "Mantenimientos" (antes fijo en 120) ahora se calculan de verdad desde `STATE.programacion.length` y `STATE.mantenimientos.length` tras cada carga de datos (`updateStatCounters()`, llamada al final de `loadAll()`). "Sectores" se dejó en 10 fijo (no hay una tabla de "sectores" en la base de datos — es simplemente el rango configurado de sectores, que ahora es real tras el cambio anterior). "Disponibilidad" (95%) no se tocó — es un indicador aspiracional sin una fuente de datos natural en el sistema, y el usuario no lo mencionó explícitamente. Se quitó el `setTimeout(animateCounters, 400)` que animaba los contadores con un tiempo fijo sin relación a si los datos ya habían cargado; ahora se anima justo después de que los datos reales están listos.
- **Bug de contraste en modo oscuro/claro corregido:** el usuario reportó letras blancas invisibles al cambiar de tema. Se revisó sistemáticamente cada uso de `color:#fff` en el archivo (18 casos) contra el fondo real de cada contexto; todos menos uno resultaron estar sobre fondos que NO cambian con el tema (degradados de la marca, hero, footer, avatares) y por lo tanto son seguros. El único bug real encontrado: `.toast` (el mensaje de confirmación que aparece abajo) usaba `background:var(--ink)` — una variable que en modo claro es azul oscuro (fondo correcto) pero en modo OSCURO se invierte a un tono casi blanco (`#EAF2F7`), dejando el texto blanco del toast invisible sobre un fondo casi blanco (contraste medido: 1.13:1, prácticamente ilegible). Se corrigió fijando el fondo del toast a un color oscuro fijo (`#0D2436`), independiente del tema — igual que ya se hacía con el pie de página. Nota: el reporte del usuario decía que el problema ocurría en modo "día", pero la evidencia técnica (medición de contraste) muestra que el bug real ocurre en modo "noche"; es posible que haya confusión sobre a qué modo se refería cada palabra, dado que el ícono del botón cambia (sol/luna) de forma que puede prestarse a confusión. Si el usuario ve el problema en otro lugar específico después de este cambio, hay que pedirle una captura o el nombre exacto del texto invisible para localizarlo con precisión.
Se validó: sintaxis JS, balance de `<div>`/`<button>`/`<span>`/`<form>`/`<label>`/`<select>`/`<option>` y balance de llaves `{}` del CSS, cada `getElementById`/`onclick`/`.then()` con su definición real, y se contó manualmente que los 3 selects de sector tienen exactamente 10 opciones "Sector N" cada uno.
**Qué quedó pendiente:** seguir sin poder verificar visualmente (mismo problema de siempre, no hay navegador en este entorno) — pedirle al usuario que confirme en el sitio en vivo que el toast ya se ve bien en modo oscuro, y que la dirección del bug de contraste coincide con lo que él reportó.
