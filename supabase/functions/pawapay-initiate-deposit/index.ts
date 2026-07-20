import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const PAWAPAY_TOKEN = Deno.env.get("PAWAPAY_API_TOKEN")!;
const BASE_URL = Deno.env.get("PAWAPAY_BASE_URL") || "https://api.sandbox.pawapay.io";

serve(async (req) => {
  // CORS support
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      }
    });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { saleId, amount, phoneNumberRaw, metadata, currency = "XAF" } = await req.json();

    // 1. Sanitiser le numéro + prédire l'opérateur
    const predRes = await fetch(`${BASE_URL}/v2/predict-provider`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${PAWAPAY_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ phoneNumber: phoneNumberRaw }),
    });
    const pred = await predRes.json();
    
    if (pred.failureReason || !pred.phoneNumber) {
      return new Response(
        JSON.stringify({ error: pred.failureReason || "Numéro invalide" }),
        { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
      );
    }

    // 2. Vérifier le statut du provider + le pinPrompt depuis active-conf
    const { data: confRow, error: confError } = await supabase
      .from("pawapay_config")
      .select("active_conf")
      .maybeSingle();

    let depositOp = { status: "OPERATIONAL", decimalsInAmount: "ZERO_PLACES", pinPrompt: "AUTOMATIC", pinPromptRevivable: true, pinPromptInstructions: null };
    let providerName = pred.provider;

    if (confRow && confRow.active_conf && confRow.active_conf.countries) {
      const country = confRow.active_conf.countries.find(
        (c: any) => c.country === pred.country
      );
      if (country) {
        const providerConf = country.providers.find(
          (p: any) => p.provider === pred.provider
        );
        if (providerConf) {
          providerName = providerConf.nameDisplayedToCustomer || pred.provider;
          const currencyConf = providerConf.currencies.find((c: any) => c.currency === currency) || providerConf.currencies[0];
          if (currencyConf && currencyConf.operationTypes && currencyConf.operationTypes.DEPOSIT) {
            depositOp = currencyConf.operationTypes.DEPOSIT;
          }
        }
      }
    }

    if (depositOp.status !== "OPERATIONAL") {
      return new Response(
        JSON.stringify({ error: { code: "PROVIDER_UNAVAILABLE", status: depositOp.status } }),
        { status: 409, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
      );
    }

    // 3. Arrondir le montant selon decimalsInAmount
    const dp = depositOp.decimalsInAmount === "TWO_PLACES" ? 2 : 0;
    const amountStr = Number(amount).toFixed(dp);

    // 4. Générer et persister le depositId AVANT l'appel
    const depositId = crypto.randomUUID();
    const { error: insertError } = await supabase.from("mobile_money_payments").insert({
      deposit_id: depositId,
      sale_id: saleId,
      status: "PENDING",
      amount: amountStr,
      currency,
      phone_number: pred.phoneNumber,
      provider: pred.provider,
    });

    if (insertError) {
      return new Response(
        JSON.stringify({ error: "Erreur enregistrement de la transaction" }),
        { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
      );
    }

    // 5. Initier le dépôt
    const body = {
      depositId,
      amount: amountStr,
      currency,
      payer: {
        type: "MMO",
        accountDetails: { phoneNumber: pred.phoneNumber, provider: pred.provider },
      },
      customerMessage: "Achat Gestock",
      // Fusionner les métadonnées pour inclure le tag team pour le hackathon
      metadata: [
        { "team": "gestock_plus" },
        { "saleId": (saleId || "unknown").substring(0, 64) }
      ]
    };

    const initRes = await fetch(`${BASE_URL}/v2/deposits`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${PAWAPAY_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    
    const initData = await initRes.json();

    if (!initRes.ok || initData.status === "REJECTED" || initData.error) {
      await supabase
        .from("mobile_money_payments")
        .update({
          status: "FAILED",
          failure_code: initData.failureReason?.failureCode || initData.error?.failureCode || "REJECTED",
          failure_message: initData.failureReason?.failureMessage || initData.errorMessage || "Refusé par PawaPay",
        })
        .eq("deposit_id", depositId);
        
      return new Response(
        JSON.stringify({
          depositId,
          status: "REJECTED",
          failureReason: initData.failureReason || { failureMessage: initData.errorMessage, failureCode: initData.error?.failureCode },
          pinPrompt: depositOp.pinPrompt,
          pinPromptRevivable: depositOp.pinPromptRevivable,
          pinPromptInstructions: depositOp.pinPromptInstructions,
          nameDisplayedToCustomer: providerName,
          rawError: initData,
        }),
        { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
      );
    } else {
      await supabase
        .from("mobile_money_payments")
        .update({ status: "ACCEPTED" })
        .eq("deposit_id", depositId);
    }

    return new Response(
      JSON.stringify({
        depositId,
        status: initData.status || "ACCEPTED",
        failureReason: null,
        pinPrompt: depositOp.pinPrompt,
        pinPromptRevivable: depositOp.pinPromptRevivable,
        pinPromptInstructions: depositOp.pinPromptInstructions,
        nameDisplayedToCustomer: providerName,
      }),
      { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message || "Internal Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  }
});
