import React from "react";
import { createRoot } from "react-dom/client";
import { Privacy } from "./Privacy";

function start() {
  const root = createRoot(document.getElementById("root")!);
  root.render(<Privacy />);
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", start);
} else {
  start();
}
