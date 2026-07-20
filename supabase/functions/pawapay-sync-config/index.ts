import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const PAWAPAY_TOKEN = Deno.env.get("PAWAPAY_API_TOKEN")!;
const BASE_URL = Deno.env.get("PAWAPAY_BASE_URL") || "https://api.sandbox.pawapay.io";

serve(async () => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Fetch config for Cameroon (CMR)
    const res = await fetch(`${BASE_URL}/v2/active-conf?country=CMR`, {
      headers: { Authorization: `Bearer ${PAWAPAY_TOKEN}` },
    });
    
    if (!res.ok) {
      throw new Error(`PawaPay API responded with status ${res.status}`);
    }

    const conf = await res.json();

    const { error } = await supabase.from("pawapay_config").upsert({
      id: 1,
      active_conf: conf,
      fetched_at: new Date().toISOString()
    });

    if (error) {
      throw error;
    }

    return new Response(JSON.stringify({ success: true, message: "PawaPay active-conf synced successfully" }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });
  } catch (error: any) {
    console.error("Sync active-conf error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});
