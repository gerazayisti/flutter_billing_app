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
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { shopId, amountRequested, phoneNumberRaw } = await req.json();

    let phone = phoneNumberRaw.replace(/[^0-9]/g, "");
    if (phone.length === 9 && !phone.startsWith("237")) {
      phone = "237" + phone;
    }

    const payoutId = crypto.randomUUID();
    const amountStr = Math.round(Number(amountRequested)).toString();

    // 1. Insert pending payout in Supabase DB
    await supabase.from("mobile_money_payouts").insert({
      payout_id: payoutId,
      shop_id: shopId,
      status: "PENDING",
      amount: amountStr,
      phone_number: phone,
    });

    // 2. Obtain Bearer JWT token & Call FreeMoPay API v2 direct-withdraw
    const accessToken = await getAccessToken();

    const apiRes = await fetch(`${FREEMOPAY_BASE_URL}/api/v2/payment/direct-withdraw`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        receiver: phone,
        amount: amountStr,
        externalId: payoutId,
      }),
    });

    const apiData = await apiRes.json();
    const ref = apiData.reference || payoutId;

    return new Response(
      JSON.stringify({
        payoutId: ref,
        status: apiData.status === "CREATED" ? "ACCEPTED" : (apiData.status || "ACCEPTED"),
        reference: ref,
        message: apiData.message || "Retrait initié via FreeMoPay",
      }),
      { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );

  } catch (err: any) {
    console.error("FreeMoPay Initiate Payout Error:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Erreur retrait FreeMoPay" }),
      { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  }
});
