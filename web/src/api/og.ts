/**
 * Dynamic OG Image Generation using Satori
 */

import satori from "satori";
import { Resvg } from "@resvg/resvg-js";
import { decodeShareData } from "../lib/share";
import type { SyntaxColors, ThemeMap } from "../lib/types";
import themes from "../themes.json";

const THEMES = themes as ThemeMap;
const DEFAULT_THEME = "Catppuccin Mocha";

// Load font for Satori
const fontData = await Bun.file(
  new URL("../../node_modules/@fontsource/jetbrains-mono/files/jetbrains-mono-latin-400-normal.woff", import.meta.url)
).arrayBuffer().catch(() => null);

// Fallback to system font if custom font not available
const fonts = fontData
  ? [
      {
        name: "JetBrains Mono",
        data: fontData,
        weight: 400 as const,
        style: "normal" as const,
      },
    ]
  : [];

function getTheme(name: string): SyntaxColors {
  return THEMES[name] || THEMES[DEFAULT_THEME];
}

// Simple color adjustment
function adjustColor(hex: string, amount: number): string {
  const num = parseInt(hex.replace("#", ""), 16);
  const r = Math.min(
    255,
    Math.max(0, (num >> 16) + Math.round(255 * amount))
  );
  const g = Math.min(
    255,
    Math.max(0, ((num >> 8) & 0x00ff) + Math.round(255 * amount))
  );
  const b = Math.min(
    255,
    Math.max(0, (num & 0x0000ff) + Math.round(255 * amount))
  );
  return `#${((r << 16) | (g << 8) | b).toString(16).padStart(6, "0")}`;
}

export async function generateOGImage(data: string): Promise<Buffer> {
  const payload = decodeShareData(data);

  if (!payload) {
    throw new Error("Invalid share data");
  }

  const theme = getTheme(payload.t);

  // Limit lines for OG image
  const lines = payload.l.slice(0, 6);

  const svg = await satori(
    {
      type: "div",
      props: {
        style: {
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          background: theme.background,
          padding: "40px",
        },
        children: [
          // Window frame
          {
            type: "div",
            props: {
              style: {
                flex: 1,
                display: "flex",
                flexDirection: "column",
                borderRadius: "16px",
                overflow: "hidden",
                boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.5)",
                background: theme.background,
              },
              children: [
                // Title bar
                {
                  type: "div",
                  props: {
                    style: {
                      height: "48px",
                      display: "flex",
                      alignItems: "center",
                      padding: "0 20px",
                      background: adjustColor(theme.background, 0.08),
                      borderBottom: `1px solid ${theme.text}20`,
                    },
                    children: [
                      // Traffic lights
                      {
                        type: "div",
                        props: {
                          style: {
                            display: "flex",
                            gap: "8px",
                          },
                          children: [
                            {
                              type: "div",
                              props: {
                                style: {
                                  width: "14px",
                                  height: "14px",
                                  borderRadius: "7px",
                                  background: "#FF5F57",
                                },
                              },
                            },
                            {
                              type: "div",
                              props: {
                                style: {
                                  width: "14px",
                                  height: "14px",
                                  borderRadius: "7px",
                                  background: "#FEBC2E",
                                },
                              },
                            },
                            {
                              type: "div",
                              props: {
                                style: {
                                  width: "14px",
                                  height: "14px",
                                  borderRadius: "7px",
                                  background: "#28C840",
                                },
                              },
                            },
                          ],
                        },
                      },
                      // Title
                      {
                        type: "div",
                        props: {
                          style: {
                            flex: 1,
                            textAlign: "center",
                            fontSize: "16px",
                            fontWeight: 500,
                            color: theme.text,
                          },
                          children: "Numby",
                        },
                      },
                      // Spacer
                      {
                        type: "div",
                        props: { style: { width: "62px" } },
                      },
                    ],
                  },
                },
                // Content
                {
                  type: "div",
                  props: {
                    style: {
                      flex: 1,
                      padding: "24px 32px",
                      display: "flex",
                      flexDirection: "column",
                      gap: "8px",
                      fontFamily: fonts.length ? "JetBrains Mono" : "monospace",
                      fontSize: "20px",
                    },
                    children: lines.map(([expr, result]) => ({
                      type: "div",
                      props: {
                        style: {
                          display: "flex",
                          justifyContent: "space-between",
                          gap: "32px",
                        },
                        children: [
                          {
                            type: "span",
                            props: {
                              style: { color: theme.text },
                              children: expr,
                            },
                          },
                          {
                            type: "span",
                            props: {
                              style: { color: theme.results },
                              children: result,
                            },
                          },
                        ],
                      },
                    })),
                  },
                },
              ],
            },
          },
          // Branding
          {
            type: "div",
            props: {
              style: {
                display: "flex",
                justifyContent: "flex-end",
                padding: "16px 0 0",
                fontSize: "14px",
                color: theme.comments,
              },
              children: "numby.vivy.app",
            },
          },
        ],
      },
    },
    {
      width: 1200,
      height: 630,
      fonts,
    }
  );

  const resvg = new Resvg(svg, {
    fitTo: {
      mode: "width",
      value: 1200,
    },
  });

  return Buffer.from(resvg.render().asPng());
}
