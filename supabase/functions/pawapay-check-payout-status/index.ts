import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const PAWAPAY_TOKEN = Deno.env.get("PAWAPAY_API_TOKEN")!;
const BASE_URL = Deno.env.get("PAWAPAY_BASE_URL") || "https://api.pawapay.io";

serve(async (req) => {
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

    const { payoutId } = await req.json();

    if (!payoutId) {
      return new Response(JSON.stringify({ error: "Missing payoutId" }), {
        status: 400,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // 1. Appeler l'API pawaPay pour récupérer le statut actuel
    const checkRes = await fetch(`${BASE_URL}/v2/payouts/${payoutId}`, {
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

    const responseData = await checkRes.json();
    if (responseData.status !== "FOUND" || !responseData.data) {
      return new Response(JSON.stringify({ error: "Payout not found in PawaPay" }), {
        status: 404,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const pawaPayPayout = responseData.data;
    const currentStatus = pawaPayPayout.status; // COMPLETED | FAILED | PROCESSING | ACCEPTED

    // Récupérer le retrait actuel en base pour gérer le rollback ou la commission
    const { data: withdrawal, error: selectError } = await supabase
      .from("shop_withdrawals")
      .select("*")
      .eq("payout_id", payoutId)
      .maybeSingle();

    if (selectError || !withdrawal) {
      return new Response(JSON.stringify({ error: "Withdrawal not found in database" }), {
        status: 404,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    // Si le statut a changé
    if (withdrawal.status !== currentStatus) {
      // Cas 1 : Le retrait a ÉCHOUÉ => Rollback du solde de la boutique
      if (currentStatus === "FAILED") {
        // 1. Récupérer le solde actuel
        const { data: balanceData } = await supabase
          .from("shop_balances")
          .select("balance")
          .eq("shop_id", withdrawal.shop_id)
          .maybeSingle();

        const currentBalance = balanceData ? Number(balanceData.balance) : 0;
        
        // 2. Créditer à nouveau le montant brut
        await supabase
          .from("shop_balances")
          .update({ balance: currentBalance + Number(withdrawal.gross_amount) })
          .eq("shop_id", withdrawal.shop_id);
      }

      // Cas 2 : Le retrait est validé avec succès (COMPLETED) => Créditer la commission Gestock
      if (currentStatus === "COMPLETED") {
        const fee = Number(withdrawal.fee_amount);

        // Mettre à jour les gains accumulés de Gestock (ligne ID 1)
        await supabase.rpc("increment_gestock_earnings", { fee_val: fee });
      }

      // Mettre à jour la ligne de retrait
      await supabase
        .from("shop_withdrawals")
        .update({
          status: currentStatus,
          provider_transaction_id: pawaPayPayout.providerTransactionId,
          failure_code: pawaPayPayout.failureReason?.failureCode || null,
          failure_message: pawaPayPayout.failureReason?.failureMessage || null,
          updated_at: new Date().toISOString(),
        })
        .eq("payout_id", payoutId);
    }

    return new Response(
      JSON.stringify({
        payoutId,
        status: currentStatus,
        providerTransactionId: pawaPayPayout.providerTransactionId,
        failureReason: pawaPayPayout.failureReason,
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
