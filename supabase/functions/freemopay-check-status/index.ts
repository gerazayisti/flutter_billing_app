import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const FREEMOPAY_BASE_URL = Deno.env.get("FREEMOPAY_BASE_URL") || "https://api-v2.freemopay.com";
const FREEMOPAY_APP_KEY = Deno.env.get("FREEMOPAY_APP_KEY") || "56470c21-bc1d-47d1-ab2f-2efae429b5df";
const FREEMOPAY_SECRET_KEY = Deno.env.get("FREEMOPAY_SECRET_KEY") || "9Vyp3LsNU5ePeXjipu8B";

async function getAccessToken(): Promise<string> {
  const tokenRes = await fetch(`${FREEMOPAY_BASE_URL}/api/v2/payment/token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      appKey: FREEMOPAY_APP_KEY,
      secretKey: FREEMOPAY_SECRET_KEY,
    }),
  });
  const tokenData = await tokenRes.json();
  if (!tokenRes.ok || !tokenData.access_token) {
    throw new Error(`Token Error: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const { depositId } = await req.json();
    if (!depositId) {
      return new Response(JSON.stringify({ error: "depositId requis" }), { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Fetch local record from DB
    const { data: dbRow } = await supabase
      .from("mobile_money_payments")
      .select("amount, phone_number, provider, status")
      .eq("deposit_id", depositId)
      .maybeSingle();

    let rawStatus = "PENDING";
    let apiMessage = "";
    let apiPayer = "";
    let apiAmount = 0;

    try {
      const accessToken = await getAccessToken();
      const apiRes = await fetch(`${FREEMOPAY_BASE_URL}/api/v2/payment/${depositId}`, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
      });

      if (apiRes.ok) {
        const apiData = await apiRes.json();
        rawStatus = (apiData.status || "PENDING").toUpperCase();
        apiMessage = apiData.message || rawStatus;
        apiPayer = apiData.payer || "";
        apiAmount = apiData.amount ? Number(apiData.amount) : 0;
      }
    } catch (_) {}

    let status = dbRow?.status || "ACCEPTED";
    if (rawStatus === "SUCCESS" || rawStatus === "COMPLETED") {
      status = "COMPLETED";
    } else if (rawStatus === "FAILED" || rawStatus === "REJECTED" || rawStatus === "CANCELLED") {
      status = "FAILED";
    } else if (rawStatus === "PENDING" || rawStatus === "CREATED") {
      status = "ACCEPTED";
    }

    if (dbRow) {
      await supabase.from("mobile_money_payments").update({
        status: status,
        updated_at: new Date().toISOString(),
      }).eq("deposit_id", depositId);
    }

    return new Response(
      JSON.stringify({
        depositId,
        status,
        amount: dbRow?.amount ? Number(dbRow.amount) : (apiAmount || 0),
        phone_number: dbRow?.phone_number || apiPayer || "",
        provider: dbRow?.provider || "FreeMoPay",
        message: apiMessage || rawStatus,
      }),
      { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );

  } catch (err: any) {
    console.error("FreeMoPay Check Status Error:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Erreur vérification FreeMoPay" }),
      { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  }
});
