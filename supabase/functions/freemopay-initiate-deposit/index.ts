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

    const { saleId, amount, phoneNumberRaw, currency = "XAF" } = await req.json();

    let phone = phoneNumberRaw.replace(/[^0-9]/g, "");
    if (phone.length === 9 && !phone.startsWith("237")) {
      phone = "237" + phone;
    }

    const depositId = crypto.randomUUID();
    const amountStr = Math.round(Number(amount)).toString();
    const providerName = phone.startsWith("23769") || phone.startsWith("23767") || phone.startsWith("237650") || phone.startsWith("237651") || phone.startsWith("237652") || phone.startsWith("237653") || phone.startsWith("237654") ? "MTN" : "ORANGE";

    // 1. Insert pending payment record in Supabase DB
    const { error: insertError } = await supabase.from("mobile_money_payments").insert({
      deposit_id: depositId,
      sale_id: saleId,
      status: "PENDING",
      amount: amountStr,
      currency,
      phone_number: phone,
      provider: providerName,
    });

    if (insertError) {
      console.error("DB Insert Error:", insertError);
    }

    // 2. Obtain Bearer JWT token & Call FreeMoPay API v2 POST /api/v2/payment
    const accessToken = await getAccessToken();

    const apiRes = await fetch(`${FREEMOPAY_BASE_URL}/api/v2/payment`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        payer: phone,
        amount: amountStr,
        externalId: depositId,
      }),
    });

    const apiData = await apiRes.json();
    const ref = apiData.reference || depositId;

    return new Response(
      JSON.stringify({
        depositId: ref,
        status: "ACCEPTED",
        pinPrompt: "AUTOMATIC",
        pinPromptRevivable: false,
        nameDisplayedToCustomer: "FreeMoPay Mobile Money",
        reference: ref,
        amount: Number(amountStr),
        phone_number: phone,
        provider: providerName,
      }),
      { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );

  } catch (err: any) {
    console.error("FreeMoPay Initiate Deposit Error:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Erreur FreeMoPay" }),
      { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  }
});
