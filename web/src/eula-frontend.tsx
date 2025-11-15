import React from "react";
import { createRoot } from "react-dom/client";
import { Eula } from "./Eula";

function start() {
  const root = createRoot(document.getElementById("root")!);
  root.render(<Eula />);
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", start);
} else {
  start();
}
