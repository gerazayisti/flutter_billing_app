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

    const { shopId } = await req.json();

    if (!shopId) {
      return new Response(
        JSON.stringify({ error: "shopId requis" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Chercher correspondance exacte
    const { data: exact } = await supabase
      .from("shop_balances")
      .select("shop_id, balance")
      .eq("shop_id", shopId)
      .maybeSingle();

    if (exact) {
      return new Response(
        JSON.stringify({ shop_id: exact.shop_id, balance: Number(exact.balance) }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Fallback : retourner tous les soldes (pour les migrations de shop_id)
    const { data: all } = await supabase
      .from("shop_balances")
      .select("shop_id, balance");

    if (all && all.length > 0) {
      // Si un seul shop en BD, on le retourne directement
      if (all.length === 1) {
        return new Response(
          JSON.stringify({ shop_id: all[0].shop_id, balance: Number(all[0].balance) }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      // Sinon on retourne la somme totale (multi-boutique = cas rare)
      const total = all.reduce((sum: number, row: any) => sum + Number(row.balance), 0);
      return new Response(
        JSON.stringify({ shop_id: shopId, balance: total }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Aucun solde trouvé
    return new Response(
      JSON.stringify({ shop_id: shopId, balance: 0 }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (e: any) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
