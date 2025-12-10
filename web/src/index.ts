import { serve } from "bun";
import index from "./index.html";
import privacyHtml from "./privacy.html";
import eulaHtml from "./eula.html";
import shareHtml from "./s.html";
import { generateOGImage } from "./api/og";

const server = serve({
  routes: {
    "/": index,
    "/s": shareHtml,
    "/privacy": privacyHtml,
    "/eula": eulaHtml,
    "/install.sh": Bun.file("./src/install.sh"),
    "/robots.txt": Bun.file("./src/robots.txt"),
    "/sitemap.xml": Bun.file("./src/sitemap.xml"),
    "/api/og": {
      GET: async (req) => {
        const url = new URL(req.url);
        const data = url.searchParams.get("d");

        if (!data) {
          return new Response("Missing data parameter", { status: 400 });
        }

        try {
          const png = await generateOGImage(data);
          return new Response(png, {
            headers: {
              "Content-Type": "image/png",
              "Cache-Control": "public, max-age=31536000, immutable",
            },
          });
        } catch (e) {
          console.error("OG image generation failed:", e);
          // Return default OG image on error
          return new Response(Bun.file("./src/og.png"));
        }
      },
    },
  },

  development: process.env.NODE_ENV !== "production" && {
    hmr: true,
    console: true,
  },
});

console.log(`🚀 Server running at ${server.url}`);
