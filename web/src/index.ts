import { serve } from "bun";
import index from "./index.html";
import privacyHtml from "./privacy.html";
import eulaHtml from "./eula.html";

const server = serve({
  routes: {
    "/": index,
    "/privacy": privacyHtml,
    "/eula": eulaHtml,
    "/install.sh": Bun.file("./src/install.sh"),
  },

  development: process.env.NODE_ENV !== "production" && {
    hmr: true,
    console: true,
  },
});

console.log(`🚀 Server running at ${server.url}`);
