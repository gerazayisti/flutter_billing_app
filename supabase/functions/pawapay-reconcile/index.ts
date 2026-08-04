import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const PAWAPAY_TOKEN = Deno.env.get("PAWAPAY_API_TOKEN")!;
const BASE_URL = Deno.env.get("PAWAPAY_BASE_URL") || "https://api.pawapay.io";

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

    // 1. Fetch pending deposits (older than 30 seconds but less than 1 hour)
    const { data: deposits, error: fetchError } = await supabase
      .from("mobile_money_payments")
      .select("id, deposit_id")
      .in("status", ["PENDING", "ACCEPTED"])
      .lt("created_at", new Date(Date.now() - 30 * 1000).toISOString())
      .gt("created_at", new Date(Date.now() - 60 * 60 * 1000).toISOString());

    if (fetchError) {
      throw new Error(`Error fetching deposits: ${fetchError.message}`);
    }

    const results = [];

    // 2. Poll PawaPay for each deposit
    for (const deposit of deposits) {
      try {
        const response = await fetch(`${BASE_URL}/v2/deposits/${deposit.deposit_id}`, {
          headers: {
            Authorization: `Bearer ${PAWAPAY_TOKEN}`,
            "Content-Type": "application/json",
          },
        });

        if (!response.ok) {
          results.push({ deposit_id: deposit.deposit_id, error: `API HTTP ${response.status}` });
          continue;
        }

        const data = await response.json();
        const status = data.status || data[0]?.status;

        if (status === "COMPLETED") {
          await supabase
            .from("mobile_money_payments")
            .update({ status: "COMPLETED" })
            .eq("deposit_id", deposit.deposit_id);
          results.push({ deposit_id: deposit.deposit_id, status: "COMPLETED" });
        } else if (status === "FAILED" || status === "REJECTED") {
          const failureReason = data.failureReason || data[0]?.failureReason;
          await supabase
            .from("mobile_money_payments")
            .update({
              status: "FAILED",
              failure_code: failureReason?.failureCode,
              failure_message: failureReason?.failureMessage,
            })
            .eq("deposit_id", deposit.deposit_id);
          results.push({ deposit_id: deposit.deposit_id, status: "FAILED" });
        } else {
          results.push({ deposit_id: deposit.deposit_id, status: "STILL_PENDING" });
        }
      } catch (err: any) {
        results.push({ deposit_id: deposit.deposit_id, error: err.message });
      }
    }

    return new Response(
      JSON.stringify({ success: true, processed: results.length, results }),
      { status: 200, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message || "Internal Server Error" }),
      { status: 500, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  }
});
