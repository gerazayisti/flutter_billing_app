import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Correspondance pay-link → plan pour les abonnements
const PAY_LINK_PLANS: Record<string, { tier: string; cycle: string; days: number }> = {
  '3bcd23b713e9ec8f19411c6095525d': { tier: 'starter',  cycle: 'monthly', days: 31  },
  'cab2ac95c6063e094194479258b534': { tier: 'starter',  cycle: 'yearly',  days: 366 },
  '291134fa9f453dd8e420e5a4ff40ac': { tier: 'pro',      cycle: 'monthly', days: 31  },
  '27b1282a2bbb6a3f1ab8a0f12c15e6': { tier: 'pro',      cycle: 'yearly',  days: 366 },
  'd43fb1dabda88266f9a8a4dd99acb6': { tier: 'business', cycle: 'monthly', days: 31  },
  '63c0fdd1b47df54316a8816d997a35': { tier: 'business', cycle: 'yearly',  days: 366 },
};

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  let body: Record<string, any>;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  console.log("FreeMoPay Webhook payload reçu:", JSON.stringify(body));

  const reference       = body["reference"] as string | undefined;
  const status          = (body["status"] as String | undefined)?.toUpperCase();
  const externalId      = body["externalId"] as string | undefined;
  const transactionType = body["transactionType"] as string | undefined;
  const metadata        = body["metadata"] as Record<string, string> | undefined;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const now = new Date();

  // 1. Mettre à jour mobile_money_payments si externalId correspond à une vente/dépôt
  if (externalId) {
    const isSuccess = status === "SUCCESS" || status === "COMPLETED";
    const dbStatus = isSuccess ? "COMPLETED" : (status === "FAILED" ? "FAILED" : "PENDING");

    const { error: updateErr } = await supabase
      .from("mobile_money_payments")
      .update({
        status: dbStatus,
        freemopay_reference: reference,
        updated_at: now.toISOString(),
      })
      .eq("deposit_id", externalId);

    if (updateErr) {
      console.warn("Mobile Money Payment Update Error:", updateErr);
    }
  }

  // 2. Traiter les abonnements si metadata ou pay_link_id est fourni
  const shopId = metadata?.["shop_id"] || (externalId?.startsWith("sub_") ? externalId.split("_")[1] : undefined);
  const payLinkId = metadata?.["pay_link_id"];

  if (shopId && (status === "SUCCESS" || status === "COMPLETED")) {
    const plan = payLinkId ? PAY_LINK_PLANS[payLinkId] : undefined;
    const tier = plan?.tier ?? "starter";
    const cycle = plan?.cycle ?? "monthly";
    const days = plan?.days ?? 31;
    const expiry = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

    await supabase.from("subscriptions").upsert({
      shop_id: shopId,
      tier,
      billing_cycle: cycle,
      status: "active",
      start_date: now.toISOString(),
      expiry_date: expiry.toISOString(),
      freemopay_reference: reference || externalId,
      updated_at: now.toISOString(),
    }, { onConflict: "shop_id" });
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
