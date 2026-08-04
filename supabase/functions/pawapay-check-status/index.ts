import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const PAWAPAY_TOKEN = Deno.env.get("PAWAPAY_API_TOKEN")!;
const BASE_URL = Deno.env.get("PAWAPAY_BASE_URL") || "https://api.pawapay.io";

serve(async (req) => {
  // Support CORS
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

    const { depositId } = await req.json();

    if (!depositId) {
      return new Response(JSON.stringify({ error: "Missing depositId" }), {
        status: 400,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // 1. Appeler l'API pawaPay pour récupérer le statut actuel
    const checkRes = await fetch(`${BASE_URL}/v2/deposits/${depositId}`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${PAWAPAY_TOKEN}`,
      },
    });

    if (!checkRes.ok) {
      const errText = await checkRes.text();
      return new Response(JSON.stringify({ error: `PawaPay API error: ${errText}` }), {
        status: checkRes.status,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const checkResult = await checkRes.json();
    if (checkResult.status === "NOT_FOUND" || !checkResult.data) {
      return new Response(JSON.stringify({ error: "Deposit not found in PawaPay" }), {
        status: 404,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const pawaPayPayment = checkResult.data;
    const status = pawaPayPayment.status; // COMPLETED, FAILED, ACCEPTED, etc.

    // 2. Mettre à jour la base de données Supabase si nécessaire
    const { error: updateError } = await supabase
      .from("mobile_money_payments")
      .update({
        status: status,
        provider_transaction_id: pawaPayPayment.providerTransactionId,
        failure_code: pawaPayPayment.failureReason?.failureCode || null,
        failure_message: pawaPayPayment.failureReason?.failureMessage || null,
        updated_at: new Date().toISOString(),
      })
      .eq("deposit_id", depositId);

    if (updateError) {
      console.error("Error updating DB during polling:", updateError);
    }

    return new Response(
      JSON.stringify({
        depositId,
        status,
        providerTransactionId: pawaPayPayment.providerTransactionId,
        failureReason: pawaPayPayment.failureReason,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message || "Internal Server Error" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      }
    );
  }
});
