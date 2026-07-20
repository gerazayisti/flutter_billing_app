import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

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

    const payload = await req.json();
    const depositId = payload.depositId;

    if (!depositId) {
      return new Response("Missing depositId", { status: 400 });
    }

    // Idempotence : si déjà traité avec ce statut, on sort
    const { data: existing } = await supabase
      .from("mobile_money_payments")
      .select("status")
      .eq("deposit_id", depositId)
      .maybeSingle();

    if (existing?.status === payload.status) {
      return new Response("Already updated", { status: 200 });
    }

    const { error: updateError } = await supabase
      .from("mobile_money_payments")
      .update({
        status: payload.status, // COMPLETED | FAILED | PROCESSING
        provider_transaction_id: payload.providerTransactionId,
        failure_code: payload.failureReason?.failureCode || null,
        failure_message: payload.failureReason?.failureMessage || null,
        updated_at: new Date().toISOString(),
      })
      .eq("deposit_id", depositId);

    if (updateError) {
      console.error("Error updating mobile money payment:", updateError);
      return new Response("Error updating payment status", { status: 500 });
    }

    return new Response("Success", { status: 200 });
  } catch (error: any) {
    console.error("Callback handler error:", error);
    return new Response(error.message || "Internal Server Error", { status: 500 });
  }
});
