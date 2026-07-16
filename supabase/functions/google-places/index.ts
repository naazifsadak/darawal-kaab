import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Resolves a Google photo_reference into a final public CDN image URL
// by following the redirect that Google returns. The resulting URL is a
// public googleapis.com CDN URL that any Image.network() can load without auth.
async function resolvePhotoUrl(photoReference: string, apiKey: string): Promise<string | null> {
  try {
    const googlePhotoUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=600&photo_reference=${photoReference}&key=${apiKey}`;
    const res = await fetch(googlePhotoUrl, { redirect: "manual" });
    // Google responds with a 302 redirect to the actual CDN image URL
    const redirectUrl = res.headers.get("location");
    if (redirectUrl) return redirectUrl;
    // If no redirect (image served directly), return the original URL
    if (res.ok) return googlePhotoUrl;
    return null;
  } catch {
    return null;
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("GOOGLE_PLACES_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "GOOGLE_PLACES_API_KEY secret is not configured in Supabase" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Default JSON handler for API post requests
    const body = await req.json();
    const { action } = body;

    if (action === "nearbySearch") {
      const { lat, lng, radius, keyword } = body;
      const googleUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}&keyword=${encodeURIComponent(keyword)}&key=${apiKey}`;
      const googleRes = await fetch(googleUrl);
      const data = await googleRes.json();

      // Resolve photo references in parallel for all results so Flutter
      // can load images with plain Image.network() — no auth headers needed.
      const FALLBACK = "https://picsum.photos/seed/gasstation/600/400";
      if (data.results && Array.isArray(data.results)) {
        await Promise.all(
          data.results.map(async (place: any) => {
            const photos = place.photos;
            if (photos && photos.length > 0) {
              const photoRef = photos[0].photo_reference;
              const resolvedUrl = await resolvePhotoUrl(photoRef, apiKey);
              place._resolvedPhotoUrl = resolvedUrl ?? FALLBACK;
            } else {
              place._resolvedPhotoUrl = FALLBACK;
            }
          })
        );
      }

      return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "details") {
      const { place_id, fields } = body;
      const googleUrl = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${place_id}&fields=${fields}&key=${apiKey}`;
      const googleRes = await fetch(googleUrl);
      const data = await googleRes.json();
      return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({ error: "Invalid or unsupported action" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
