import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // 1. Corriger le trigger avec la bonne extraction du shop_id
    const { error: triggerError } = await supabase.rpc("exec_sql", {
      sql: `
        CREATE OR REPLACE FUNCTION handle_completed_deposit()
        RETURNS trigger AS $$
        DECLARE
          v_shop_id text;
        BEGIN
          IF new.status = 'COMPLETED' AND (old.status IS NULL OR old.status != 'COMPLETED') THEN
            IF position('_' in new.sale_id) > 0 THEN
              v_shop_id := substring(new.sale_id from '(.*)_');
            ELSE
              v_shop_id := 'default_shop';
            END IF;

            INSERT INTO shop_balances (shop_id, balance, updated_at)
            VALUES (v_shop_id, CAST(new.amount AS numeric(15, 2)), now())
            ON CONFLICT (shop_id) DO UPDATE
            SET balance = shop_balances.balance + CAST(new.amount AS numeric(15, 2)),
                updated_at = now();
          END IF;
          RETURN new;
        END;
        $$ LANGUAGE plpgsql;
      `
    });

    // 2. Recalculer les soldes directement (sans passer par exec_sql si non dispo)
    // On vide et réinsère depuis les paiements COMPLETED
    await supabase.from("shop_balances").delete().neq("shop_id", "");

    const { data: payments, error: fetchError } = await supabase
      .from("mobile_money_payments")
      .select("sale_id, amount")
      .eq("status", "COMPLETED");

    if (fetchError) {
      throw new Error(`Erreur lecture paiements: ${fetchError.message}`);
    }

    if (!payments || payments.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: "Aucun paiement COMPLETED trouvé. Soldes vides.", balances: [] }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Grouper par shop_id côté Deno
    const totals: Record<string, number> = {};
    for (const p of payments) {
      const saleId: string = p.sale_id || "default_shop";
      let shopId: string;
      const idx = saleId.lastIndexOf("_");
      if (idx > 0) {
        shopId = saleId.substring(0, idx);
      } else {
        shopId = "default_shop";
      }
      totals[shopId] = (totals[shopId] ?? 0) + parseFloat(p.amount);
    }

    const rows = Object.entries(totals).map(([shop_id, balance]) => ({
      shop_id,
      balance,
      updated_at: new Date().toISOString(),
    }));

    const { error: insertError } = await supabase
      .from("shop_balances")
      .insert(rows);

    if (insertError) {
      throw new Error(`Erreur insertion soldes: ${insertError.message}`);
    }

    return new Response(
      JSON.stringify({ success: true, balances: rows }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (e: any) {
    return new Response(
      JSON.stringify({ success: false, error: e.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
