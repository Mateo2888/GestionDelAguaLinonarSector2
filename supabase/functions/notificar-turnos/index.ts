// Supabase Edge Function: notificar-turnos
// Se dispara cada minuto (vía pg_cron, ver cron-notificaciones-setup.sql)
// y manda una notificación push a quien tenga el turno por empezar,
// empezando, o por terminar. Es la mitad "página cerrada" del sistema
// de notificaciones — la otra mitad (aviso por VOZ) vive en el
// navegador y solo funciona con la página abierta (ver index.html).
//
// Cómo desplegar: ver prompt-notificaciones-push.md en la raíz del repo.
//
// Variables de entorno que necesita (Secrets del proyecto en Supabase):
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY  -> generadas con `web-push generate-vapid-keys`
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY -> Supabase ya los provee
//   automáticamente a toda Edge Function, no hace falta configurarlos a mano.

// deno-lint-ignore-file no-explicit-any
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// "?target=deno" mejora la compatibilidad de este paquete (pensado para
// Node) dentro del runtime de Deno que usan las Edge Functions.
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

const TURNO_HORAS = 2;
const CICLO_INICIO = new Date("2026-01-01T00:00:00Z");

type Propietario = {
  codigo: string;
  nombre: string;
  posicion: number;
  turno_fecha_manual: string | null;
  turno_inicio_manual: string | null;
  turno_fin_manual: string | null;
};

// Misma lógica que calcularTurno()/construirResultadoTurno() en index.html:
// si el administrador anuló el turno automático para este propietario
// (pestaña "Propietarios / Turnos"), esa fecha/hora manual manda sobre
// el cálculo por posición.
function calcularInicioFin(prop: Propietario, totalActivos: number): { inicio: Date; fin: Date } {
  if (prop.turno_fecha_manual && prop.turno_inicio_manual && prop.turno_fin_manual) {
    const inicio = new Date(`${prop.turno_fecha_manual}T${prop.turno_inicio_manual}`);
    const fin = new Date(`${prop.turno_fecha_manual}T${prop.turno_fin_manual}`);
    return { inicio, fin };
  }
  const cicloHoras = Math.max(totalActivos, 1) * TURNO_HORAS;
  const ahora = new Date();
  const horasDesde = (ahora.getTime() - CICLO_INICIO.getTime()) / 3600000;
  let ciclo = Math.floor(horasDesde / cicloHoras);
  let inicio = new Date(CICLO_INICIO.getTime() + (ciclo * cicloHoras + prop.posicion * TURNO_HORAS) * 3600000);
  let fin = new Date(inicio.getTime() + TURNO_HORAS * 3600000);
  if (ahora > fin) {
    ciclo++;
    inicio = new Date(CICLO_INICIO.getTime() + (ciclo * cicloHoras + prop.posicion * TURNO_HORAS) * 3600000);
    fin = new Date(inicio.getTime() + TURNO_HORAS * 3600000);
  }
  return { inicio, fin };
}

// ¿"ms" cae dentro de la ventana de 1 minuto que le corresponde a este
// disparo del cron? (el cron corre cada 60s, así que cada hito solo debe
// dispararse una vez, en la corrida que lo alcanza).
function enVentana(ms: number, objetivoMs: number): boolean {
  return ms <= objetivoMs && ms > objetivoMs - 60_000;
}

Deno.serve(async () => {
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const ahora = new Date();

  const { data: propietarios } = await sb
    .from("propietarios")
    .select("codigo, nombre, posicion, turno_fecha_manual, turno_inicio_manual, turno_fin_manual")
    .eq("activo", true);

  if (!propietarios || propietarios.length === 0) return new Response("ok: sin propietarios activos");
  const total = propietarios.length;

  let enviados = 0;
  for (const prop of propietarios as Propietario[]) {
    const { inicio, fin } = calcularInicioFin(prop, total);
    const diffInicio = inicio.getTime() - ahora.getTime();
    const diffFin = fin.getTime() - ahora.getTime();

    let mensaje: { title: string; body: string; tag: string } | null = null;
    if (enVentana(diffInicio, 10 * 60 * 1000)) {
      mensaje = { title: "💧 Tu turno de agua comienza pronto", body: `${prop.nombre}, tu agua empieza en 10 minutos.`, tag: `inicio-${prop.codigo}` };
    } else if (diffInicio <= 0 && diffInicio > -60_000) {
      mensaje = { title: "💧 ¡Tu turno de agua ha comenzado!", body: `${prop.nombre}, tienes 2 horas de servicio de agua. ¡Aprovéchalo!`, tag: `turno-${prop.codigo}` };
    } else if (enVentana(diffFin, 5 * 60 * 1000)) {
      mensaje = { title: "⚠️ Tu turno termina pronto", body: `${prop.nombre}, te quedan 5 minutos de agua.`, tag: `fin-${prop.codigo}` };
    }

    if (!mensaje) continue;

    const { data: subs } = await sb
      .from("push_suscripciones")
      .select("endpoint, p256dh, auth")
      .eq("propietario_codigo", prop.codigo);

    if (!subs) continue;

    for (const sub of subs) {
      try {
        await webpush.sendNotification(
          { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
          JSON.stringify({ ...mensaje, url: "/GestionDelAguaLinonarSector2/" })
        );
        enviados++;
      } catch (e) {
        if ((e as any).statusCode === 410) {
          await sb.from("push_suscripciones").delete().eq("endpoint", sub.endpoint);
        }
      }
    }
  }

  return new Response(`ok: ${enviados} notificaciones enviadas`);
});
