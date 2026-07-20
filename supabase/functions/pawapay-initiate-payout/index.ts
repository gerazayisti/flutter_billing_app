import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const PAWAPAY_TOKEN = Deno.env.get("PAWAPAY_API_TOKEN")!;
const BASE_URL = Deno.env.get("PAWAPAY_BASE_URL") || "https://api.sandbox.pawapay.io";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" } });
  }

  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { shopId, amountRequested, phoneNumberRaw, currency = "XAF" } = await req.json();

    // 1. Prédire le fournisseur
    const predRes = await fetch(`${BASE_URL}/v2/predict-provider`, {
      method: "POST",
      headers: { Authorization: `Bearer ${PAWAPAY_TOKEN}`, "Content-Type": "application/json" },
      body: JSON.stringify({ phoneNumber: phoneNumberRaw }),
    });
    const pred = await predRes.json();

    let provider = pred.provider;
    if (provider === "MTN") provider = "MTN_MOMO_CMR";
    if (provider === "ORANGE") provider = "ORANGE_MONEY_CMR";

    if (!pred.phoneNumber || !provider) {
      return new Response(JSON.stringify({ error: "Fournisseur non reconnu" }), { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
    }

    const grossAmount = Number(amountRequested);
    const feeAmount = Math.round(grossAmount * 0.01);
    const netAmount = Math.floor(grossAmount - feeAmount);
    const payoutId = crypto.randomUUID();

    // 2. Vérification solde
    const { data: balanceData } = await supabase.from("shop_balances").select("balance").eq("shop_id", shopId).maybeSingle();
    const currentBalance = balanceData ? Number(balanceData.balance) : 0;

    if (currentBalance < grossAmount) {
      return new Response(JSON.stringify({ error: "Solde insuffisant" }), { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
    }

    // 3. Débit préventif (Sera rollback par le callback si FAILED plus tard)
    await supabase.from("shop_balances").update({ balance: currentBalance - grossAmount }).eq("shop_id", shopId);

    // Enregistrement PENDING en base
    await supabase.from("shop_withdrawals").insert({
      payout_id: payoutId,
      shop_id: shopId,
      phone_number: pred.phoneNumber,
      provider: provider,
      gross_amount: grossAmount,
      fee_amount: feeAmount,
      net_amount: netAmount,
      status: "PENDING",
    });

    // 4. FORMAT PAWAPAY V2 — schéma strict /v2/payouts
    const pawaPayBody = {
      payoutId: payoutId,
      amount: netAmount.toString(),
      currency: currency,
      recipient: {
        type: "MMO",
        accountDetails: {
          phoneNumber: pred.phoneNumber,
          provider: provider,
        },
      },
      customerMessage: "Retrait Gestock", // max 22 caractères
      metadata: [
        { "team": "gestock_plus" },
        { "shopId": shopId }
      ],
    };

    console.log("Sending V13.0 Body to /v2/payouts:", JSON.stringify(pawaPayBody));

    const initRes = await fetch(`${BASE_URL}/v2/payouts`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${PAWAPAY_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(pawaPayBody),
    });

    const initData = await initRes.json();

    if (!initRes.ok) {
      // Rollback immédiat du solde si l'initiation est rejetée par pawaPay
      await supabase.from("shop_balances").update({ balance: currentBalance }).eq("shop_id", shopId);
      await supabase.from("shop_withdrawals").update({
        status: "FAILED",
        failure_message: (initData.failureReason?.failureMessage || JSON.stringify(initData)).substring(0, 200)
      }).eq("payout_id", payoutId);

      return new Response(JSON.stringify({ status: "FAILED", version: "13.0-ERR", error: initData }), { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
    }

    // Initiation réussie (Statut ACCEPTED côté pawaPay)
    await supabase.from("shop_withdrawals").update({ status: "ACCEPTED" }).eq("payout_id", payoutId);

    return new Response(JSON.stringify({ version: "13.0-SUCCESS", payoutId, status: "ACCEPTED" }), { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });

  } catch (error: any) {
    return new Response(JSON.stringify({ error: `V13.0-FATAL: ${error.message}` }), { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } });
  }
});
