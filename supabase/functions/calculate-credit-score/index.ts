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

    const { shopId, registeredAt } = await req.json();
    if (!shopId) {
      return new Response(JSON.stringify({ error: "shopId requis" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    const now = new Date();
    const thisMonthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
    const threeMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 3, 1).toISOString();

    // 1. Paiements complétés ce mois-ci (via sale_id qui commence par shopId)
    const { data: paymentsThisMonth } = await supabase
      .from("mobile_money_payments")
      .select("amount, created_at, sale_id")
      .eq("status", "COMPLETED")
      .ilike("sale_id", `${shopId}%`)
      .gte("created_at", thisMonthStart);

    // 2. Tous les paiements complétés (3 derniers mois)
    const { data: paymentsLast3Months } = await supabase
      .from("mobile_money_payments")
      .select("amount, created_at")
      .eq("status", "COMPLETED")
      .ilike("sale_id", `${shopId}%`)
      .gte("created_at", threeMonthsAgo);

    // 3. Paiements échoués ce mois
    const { data: failedThisMonth } = await supabase
      .from("mobile_money_payments")
      .select("id")
      .eq("status", "FAILED")
      .ilike("sale_id", `${shopId}%`)
      .gte("created_at", thisMonthStart);

    // 4. Retraits
    const { data: withdrawals } = await supabase
      .from("shop_withdrawals")
      .select("gross_amount, created_at, status")
      .eq("shop_id", shopId)
      .gte("created_at", threeMonthsAgo);

    // 5. Solde actuel
    const { data: balanceRow } = await supabase
      .from("shop_balances")
      .select("balance")
      .eq("shop_id", shopId)
      .maybeSingle();

    const currentBalance = balanceRow ? Number(balanceRow.balance) : 0;

    // ─── CALCUL DU SCORE ───────────────────────────────────────────────
    const scoreBreakdown: Array<{label: string; points: number; earned: number; achieved: boolean}> = [];

    // Critère 1 : Nombre de ventes ce mois (max 30 pts)
    const salesCountThisMonth = paymentsThisMonth?.length ?? 0;
    const salesPts = salesCountThisMonth >= 20 ? 30 : salesCountThisMonth >= 10 ? 20 : salesCountThisMonth >= 5 ? 15 : salesCountThisMonth >= 1 ? 5 : 0;
    scoreBreakdown.push({
      label: `${salesCountThisMonth} vente(s) ce mois`,
      points: 30,
      earned: salesPts,
      achieved: salesCountThisMonth >= 5,
    });

    // Critère 2 : Volume mensuel (max 25 pts)
    const volumeThisMonth = (paymentsThisMonth ?? []).reduce((s: number, p: any) => s + Number(p.amount), 0);
    const volumePts = volumeThisMonth >= 500000 ? 25 : volumeThisMonth >= 200000 ? 20 : volumeThisMonth >= 100000 ? 15 : volumeThisMonth >= 50000 ? 10 : volumeThisMonth >= 10000 ? 5 : 0;
    scoreBreakdown.push({
      label: `Volume mensuel : ${Math.round(volumeThisMonth).toLocaleString()} XAF`,
      points: 25,
      earned: volumePts,
      achieved: volumeThisMonth >= 50000,
    });

    // Critère 3 : Ancienneté (max 20 pts)
    let anciennetePts = 0;
    let ancienneteLabel = "Ancienneté inconnue";
    if (registeredAt) {
      const regDate = new Date(registeredAt);
      const diffMonths = (now.getFullYear() - regDate.getFullYear()) * 12 + (now.getMonth() - regDate.getMonth());
      anciennetePts = diffMonths >= 12 ? 20 : diffMonths >= 6 ? 15 : diffMonths >= 3 ? 10 : diffMonths >= 1 ? 5 : 0;
      ancienneteLabel = `Actif depuis ${diffMonths} mois`;
    } else {
      // Estimer depuis le premier paiement
      const allPayments = paymentsLast3Months ?? [];
      if (allPayments.length > 0) {
        anciennetePts = 10;
        ancienneteLabel = "Actif depuis au moins 3 mois";
      }
    }
    scoreBreakdown.push({
      label: ancienneteLabel,
      points: 20,
      earned: anciennetePts,
      achieved: anciennetePts >= 10,
    });

    // Critère 4 : Régularité des retraits (max 15 pts)
    const withdrawalCount = withdrawals?.length ?? 0;
    const regularityPts = withdrawalCount >= 3 ? 15 : withdrawalCount >= 1 ? 10 : 0;
    scoreBreakdown.push({
      label: `${withdrawalCount} retrait(s) sur 3 mois`,
      points: 15,
      earned: regularityPts,
      achieved: withdrawalCount >= 1,
    });

    // Critère 5 : Fiabilité (pas d'échecs) (max 10 pts)
    const failedCount = failedThisMonth?.length ?? 0;
    const reliabilityPts = failedCount === 0 ? 10 : failedCount <= 2 ? 5 : 0;
    scoreBreakdown.push({
      label: failedCount === 0 ? "Aucun paiement échoué" : `${failedCount} paiement(s) échoué(s)`,
      points: 10,
      earned: reliabilityPts,
      achieved: failedCount === 0,
    });

    const totalScore = scoreBreakdown.reduce((s, c) => s + c.earned, 0);

    // ─── ÉLIGIBILITÉ ───────────────────────────────────────────────────
    let eligibilityLevel: string;
    let maxLoanAmount: number;
    let eligibilityLabel: string;
    let eligibilityColor: string;

    if (totalScore >= 70) {
      eligibilityLevel = "HIGH";
      eligibilityLabel = "Éligible au prêt";
      eligibilityColor = "#16A34A";
      // Formule dynamique : (score / 100) * (volume / 2), max 1,000,000 XAF
      maxLoanAmount = (totalScore / 100) * (volumeThisMonth * 0.5);
      if (maxLoanAmount > 1000000) maxLoanAmount = 1000000;
    } else if (totalScore >= 40) {
      eligibilityLevel = "MEDIUM";
      eligibilityLabel = "Partiellement éligible";
      eligibilityColor = "#D97706";
      // Formule dynamique pour éligibilité partielle
      maxLoanAmount = (totalScore / 100) * (volumeThisMonth * 0.35);
      if (maxLoanAmount > 300000) maxLoanAmount = 300000;
    } else {
      eligibilityLevel = "LOW";
      maxLoanAmount = 0;
      eligibilityLabel = "Non éligible pour l'instant";
      eligibilityColor = "#DC2626";
    }

    // Arrondir à la dizaine de milliers la plus proche (minimum 5000 XAF si éligible)
    if (maxLoanAmount > 0) {
      maxLoanAmount = Math.max(5000, Math.floor(maxLoanAmount / 10000) * 10000);
    }

    return new Response(JSON.stringify({
      shopId,
      score: totalScore,
      maxScore: 100,
      breakdown: scoreBreakdown,
      eligibilityLevel,
      eligibilityLabel,
      eligibilityColor,
      maxLoanAmount,
      currentBalance,
      stats: {
        salesCountThisMonth,
        volumeThisMonth: Math.round(volumeThisMonth),
        failedCount,
        withdrawalCount,
      }
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });

  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" }
    });
  }
});
