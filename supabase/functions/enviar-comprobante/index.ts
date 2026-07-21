// Supabase Edge Function: enviar-comprobante
// Recibe el comprobante de pago (ya generado en PDF por el navegador,
// codificado en base64) y lo envía por correo usando Resend.
//
// Cómo desplegar esta función (sin necesitar la CLI de Supabase):
// ver las instrucciones completas en prompt-comprobante-pago.md, en la
// raíz del repositorio.
//
// Variables de entorno que necesita (configuradas como "Secrets" del
// proyecto en Supabase, NO en este archivo):
//   RESEND_API_KEY   -> la API key de tu cuenta de Resend (resend.com)
//   RESEND_FROM      -> opcional, el remitente a usar (por defecto
//                       "Gestión del Agua Limonar Sector II <onboarding@resend.dev>",
//                       la dirección de pruebas gratuita de Resend)

// deno-lint-ignore-file no-explicit-any
Deno.serve(async (req: Request) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { to, nombre, codigo, sector, fecha, pdfBase64 } = await req.json();

    if (!to || !pdfBase64) {
      return new Response(
        JSON.stringify({ error: "Faltan datos: 'to' y 'pdfBase64' son obligatorios." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
    if (!RESEND_API_KEY) {
      return new Response(
        JSON.stringify({ error: "Falta configurar el secreto RESEND_API_KEY en Supabase." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const from = Deno.env.get("RESEND_FROM") || "Gestión del Agua Limonar Sector II <onboarding@resend.dev>";

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from,
        to: [to],
        subject: `Comprobante de pago — ${nombre || codigo || "Limonar Sector II"}`,
        html: `
          <p>Hola ${nombre || ""},</p>
          <p>Adjunto tu comprobante de pago del aporte de agua (código <strong>${codigo || ""}</strong>, ${sector || ""}), correspondiente al ${fecha || "pago registrado"}.</p>
          <p>Gestión del Agua Limonar Sector II</p>
        `,
        attachments: [
          {
            filename: `comprobante-${codigo || "pago"}.pdf`,
            content: pdfBase64,
          },
        ],
      }),
    });

    const resendData = await resendRes.json();
    if (!resendRes.ok) {
      return new Response(JSON.stringify({ error: resendData }), {
        status: resendRes.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, id: resendData.id }), {
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
