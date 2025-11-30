import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import Share from "./pages/Share";

const root = createRoot(document.getElementById("root")!);
root.render(<Share />);
