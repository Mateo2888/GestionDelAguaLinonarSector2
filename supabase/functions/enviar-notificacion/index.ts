// Supabase Edge Function: enviar-notificacion
// Función genérica: manda una notificación push a todas las
// suscripciones guardadas bajo un "codigo" en push_suscripciones.
// La usa el sitio para 3 cosas distintas, todas con el mismo mecanismo:
//   - Avisar al administrador cuando llega un reporte de daño nuevo
//     (codigo = "ADMIN").
//   - Avisar al administrador cuando llega una solicitud de afiliación
//     nueva (codigo = "ADMIN").
//   - Avisar al vecino que reportó un daño o pidió afiliarse cuando el
//     administrador cambia el estado de SU solicitud
//     (codigo = "REPORTE_<id>" o "AFILIACION_<id>").
//
// Reutiliza los mismos secretos VAPID_PUBLIC_KEY/VAPID_PRIVATE_KEY que
// ya se configuraron para "notificar-turnos" — los secretos de
// Supabase son por proyecto, no por función, así que no hace falta
// volver a configurarlos aquí.
//
// Cómo desplegar: mismo procedimiento que las otras funciones (crear
// desde el panel web de Supabase, pegar este código, Deploy, apagar
// "Verify JWT with legacy secret" en su configuración).

// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import webpush from "https://esm.sh/web-push@3.6.7?target=deno";

const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY")!;
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

webpush.setVapidDetails(
  "mailto:gestionagualimonall@gmail.com",
  VAPID_PUBLIC_KEY,
  VAPID_PRIVATE_KEY
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { codigo, title, body, tag, url } = await req.json();
    if (!codigo || !title) {
      return new Response(
        JSON.stringify({ error: "Faltan datos: 'codigo' y 'title' son obligatorios." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: subs } = await sb
      .from("push_suscripciones")
      .select("endpoint, p256dh, auth")
      .eq("propietario_codigo", codigo);

    if (!subs || subs.length === 0) {
      return new Response(JSON.stringify({ ok: true, enviados: 0 }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let enviados = 0;
    for (const sub of subs) {
      try {
        await webpush.sendNotification(
          { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
          JSON.stringify({
            title,
            body: body || "",
            tag: tag || codigo,
            url: url || "/GestionDelAguaLinonarSector2/",
          })
        );
        enviados++;
      } catch (e) {
        if ((e as any).statusCode === 410) {
          await sb.from("push_suscripciones").delete().eq("endpoint", sub.endpoint);
        }
      }
    }

    return new Response(JSON.stringify({ ok: true, enviados }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
