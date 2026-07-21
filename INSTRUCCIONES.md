# Gestión del Agua Limonar Sector II — Guía de puesta en marcha

Tienes 3 archivos:
- **index.html** → la página completa (súbela a GitHub Pages).
- **supabase-setup.sql** → crea la base de datos con un clic.
- Esta guía.

Sin configurar nada, `index.html` funciona igual (modo demo, con datos de ejemplo), pero el panel administrativo y los formularios no guardan datos reales. Sigue estos pasos para activar todo:

## Paso 1 — Crear el backend gratuito en Supabase (10 minutos)

1. Entra a **supabase.com** → "Start your project" → crea una cuenta gratis.
2. Crea un proyecto nuevo (elige una contraseña de base de datos y guárdala).
3. Cuando el proyecto termine de crearse, ve a **SQL Editor** (menú izquierdo) → "New query".
4. Abre el archivo `supabase-setup.sql`, copia todo su contenido, pégalo ahí y dale **Run**. Esto crea las 8 tablas y sus permisos de seguridad.
5. Ve a **Storage** (menú izquierdo) → "New bucket" → nómbralo `fotos` → márcalo como **Public bucket** → Create. Ahí se guardarán las fotos de los reportes de daño.
6. Ve a **Authentication > Users** → "Add user" → crea el usuario administrador (por ejemplo, el correo de Mateo Castro) con una contraseña. Con ese correo y contraseña se entra al panel administrativo del sitio.
7. Ve a **Project Settings > API**. Copia dos valores:
   - **Project URL**
   - **anon public key**

## Paso 2 — Conectar el sitio a Supabase

1. Abre `index.html` con cualquier editor de texto (Bloc de notas sirve).
2. Busca estas dos líneas, casi al final del archivo:
   ```js
   const SUPABASE_URL = "TU_SUPABASE_URL";
   const SUPABASE_ANON_KEY = "TU_SUPABASE_ANON_KEY";
   ```
3. Reemplaza los textos entre comillas por los valores que copiaste en el paso anterior. Guarda el archivo.

> La "anon key" es pública y segura para usar en el frontend — Supabase está diseñado para eso; la seguridad real la dan las políticas del paso 1 (solo el administrador autenticado puede editar).

## Paso 3 — Publicar el sitio en GitHub Pages (gratis)

1. Crea una cuenta en **github.com** si no tienes.
2. Crea un repositorio nuevo, público, con el nombre que quieras (ej. `limonar-sector-2`).
3. Sube el archivo `index.html` (botón "Add file" > "Upload files").
4. Ve a **Settings > Pages** del repositorio → en "Source" elige la rama `main` y carpeta `/root` → Save.
5. En unos minutos tu sitio quedará publicado en una dirección como:
   `https://tu-usuario.github.io/limonar-sector-2/`

## Paso 4 — Incrustarlo en Google Sites

1. En Google Sites, abre la página donde quieres mostrarlo.
2. Menú "Insertar" → **Incrustar** → pestaña "Por URL".
3. Pega el link de GitHub Pages del paso anterior.
4. Ajusta el tamaño del recuadro para que ocupe toda la página.

## Uso diario del panel administrativo

- En el sitio, hay un pequeño ícono de candado 🔒 abajo a la izquierda.
- Haz clic, ingresa el correo y contraseña que creaste en el paso 1.6.
- Desde ahí puedes agregar/eliminar: programación de turnos, noticias, fotos de galería, mantenimientos, movimientos de transparencia y documentos — sin tocar el código, y los cambios los ven todos los visitantes al instante.

## Cosas que puedes personalizar directamente en index.html

- Número de WhatsApp: busca `573000000000` (aparece 2 veces) y reemplázalo por el número real.
- Correo de contacto: busca `contacto@limonarsector2.org`.
- Nombre del encargado, dirección, etc.: busca la sección `<!-- ============ CONTACTO ============ -->`.
