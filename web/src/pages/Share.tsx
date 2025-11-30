import React, { useEffect, useState, useRef } from "react";
import { decodeShareData, type SharePayload } from "../lib/share";
import { highlightExpression } from "../lib/highlight";
import type { SyntaxColors, ThemeMap } from "../lib/types";
import themes from "../themes.json";
import logoUrl from "../logo.png";

const THEMES = themes as ThemeMap;
const DEFAULT_THEME = "Catppuccin Mocha";

function getTheme(name: string): SyntaxColors {
  return THEMES[name] || THEMES[DEFAULT_THEME];
}

export default function Share() {
  const [payload, setPayload] = useState<SharePayload | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState<string | null>(null);
  const [isSharing, setIsSharing] = useState(false);
  const previewRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Try hash first, then query param
    const hash = window.location.hash.slice(1);
    const params = new URLSearchParams(window.location.search);
    const data = hash || params.get("d");

    if (!data) {
      setError("No share data found");
      return;
    }

    const decoded = decodeShareData(data);
    if (!decoded) {
      setError("Invalid share data");
      return;
    }

    setPayload(decoded);
  }, []);

  const theme = payload ? getTheme(payload.t) : getTheme(DEFAULT_THEME);

  const copyText = async () => {
    if (!payload) return;
    const text = payload.l.map(([expr, result]) => `${expr} → ${result}`).join("\n");
    await navigator.clipboard.writeText(text);
    setCopied("text");
    setTimeout(() => setCopied(null), 2000);
  };

  const copyLink = async () => {
    await navigator.clipboard.writeText(window.location.href);
    setCopied("link");
    setTimeout(() => setCopied(null), 2000);
  };

  const copyImage = async () => {
    if (!previewRef.current) return;

    const html2canvas = (await import("html2canvas")).default;
    const canvas = await html2canvas(previewRef.current, {
      backgroundColor: null,
      scale: 2,
    });

    canvas.toBlob(async (blob) => {
      if (blob) {
        await navigator.clipboard.write([
          new ClipboardItem({ "image/png": blob }),
        ]);
        setCopied("image");
        setTimeout(() => setCopied(null), 2000);
      }
    }, "image/png");
  };

  const downloadImage = async () => {
    if (!previewRef.current) return;

    const html2canvas = (await import("html2canvas")).default;
    const canvas = await html2canvas(previewRef.current, {
      backgroundColor: null,
      scale: 2,
    });

    const link = document.createElement("a");
    link.download = "numby-calculation.png";
    link.href = canvas.toDataURL("image/png");
    link.click();
  };

  const share = async () => {
    if (isSharing) return;

    if (navigator.share) {
      try {
        setIsSharing(true);
        await navigator.share({
          title: "Numby Calculation",
          url: window.location.href,
        });
      } catch (e) {
        // User cancelled or share failed - ignore
      } finally {
        setIsSharing(false);
      }
    } else {
      await copyLink();
    }
  };

  if (error) {
    return (
      <div
        className="min-h-screen flex items-center justify-center p-4"
        style={{ background: theme.background }}
      >
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4" style={{ color: theme.text }}>
            {error}
          </h1>
          <p className="mb-6" style={{ color: theme.comments }}>
            This calculation couldn't be loaded.
          </p>
          <a
            href="/"
            className="px-6 py-3 rounded-lg font-medium"
            style={{
              background: theme.currency,
              color: theme.background,
            }}
          >
            Try Numby
          </a>
        </div>
      </div>
    );
  }

  if (!payload) {
    return (
      <div
        className="min-h-screen flex items-center justify-center"
        style={{ background: theme.background }}
      >
        <div
          className="animate-spin w-8 h-8 border-2 rounded-full"
          style={{
            borderColor: theme.comments,
            borderTopColor: theme.currency,
          }}
        />
      </div>
    );
  }

  return (
    <div
      className="min-h-screen flex flex-col"
      style={{ background: theme.background }}
    >
      {/* Header */}
      <header className="p-4 flex items-center justify-between">
        <a href="/" className="flex items-center gap-2">
          <img src={logoUrl} alt="Numby" className="w-8 h-8 rounded" />
          <span className="font-semibold" style={{ color: theme.text }}>
            Numby
          </span>
        </a>
        <a
          href="/"
          className="px-4 py-2 rounded-lg text-sm font-medium"
          style={{
            background: theme.currency,
            color: theme.background,
          }}
        >
          Get the App
        </a>
      </header>

      {/* Preview */}
      <main className="flex-1 flex items-center justify-center p-4">
        <div className="w-full max-w-xl">
          {/* Calculator Window */}
          <div
            ref={previewRef}
            className="overflow-hidden shadow-2xl"
            style={{
              background: theme.background,
              boxShadow: `0 25px 50px -12px rgba(0, 0, 0, 0.4)`,
              border: `1px solid ${theme.text}20`,
              borderRadius: "24px",
            }}
          >
            {/* Title Bar with Traffic Lights */}
            <div
              className="h-12 flex items-center px-5 relative"
              style={{ background: theme.background }}
            >
              {/* Traffic Lights */}
              <div className="flex gap-2">
                <div className="w-3.5 h-3.5 rounded-full bg-[#FF5F57]" />
                <div className="w-3.5 h-3.5 rounded-full bg-[#FEBC2E]" />
                <div className="w-3.5 h-3.5 rounded-full bg-[#28C840]" />
              </div>
              {/* Title centered in the entire bar */}
              <span
                className="absolute left-0 right-0 text-center text-sm font-medium pointer-events-none"
                style={{ color: theme.text }}
              >
                Numby
              </span>
            </div>

            {/* Content */}
            <div className="px-5 pb-5 font-mono text-sm leading-relaxed">
              {payload.l.map(([expr, result], i) => (
                <div key={i} className="flex justify-between gap-8 py-0.5">
                  <span>
                    {highlightExpression(expr, theme).map((token, j) => (
                      <span key={j} style={{ color: token.color }}>
                        {token.text}
                      </span>
                    ))}
                  </span>
                  <span style={{ color: theme.results }}>{result}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Actions */}
          <div className="mt-6 flex flex-wrap gap-3 justify-center">
            <button
              onClick={copyText}
              className="px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 transition-all"
              style={{
                background: theme.text + "15",
                color: theme.text,
              }}
            >
              {copied === "text" ? "✓ Copied!" : "Copy Text"}
            </button>
            <button
              onClick={copyImage}
              className="px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 transition-all"
              style={{
                background: theme.text + "15",
                color: theme.text,
              }}
            >
              {copied === "image" ? "✓ Copied!" : "Copy Image"}
            </button>
            <button
              onClick={downloadImage}
              className="px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 transition-all"
              style={{
                background: theme.text + "15",
                color: theme.text,
              }}
            >
              Download Image
            </button>
            <button
              onClick={share}
              className="px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 transition-all"
              style={{
                background: theme.currency,
                color: theme.background,
              }}
            >
              {copied === "link" ? "✓ Copied!" : "Share"}
            </button>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="p-4 text-center">
        <p className="text-sm" style={{ color: theme.comments }}>
          Create your own calculations at{" "}
          <a href="/" className="underline" style={{ color: theme.text }}>
            numby.vivy.app
          </a>
        </p>
      </footer>
    </div>
  );
}

// Utility to lighten/darken a color
function adjustColor(hex: string, amount: number): string {
  const num = parseInt(hex.replace("#", ""), 16);
  const r = Math.min(255, Math.max(0, (num >> 16) + Math.round(255 * amount)));
  const g = Math.min(255, Math.max(0, ((num >> 8) & 0x00ff) + Math.round(255 * amount)));
  const b = Math.min(255, Math.max(0, (num & 0x0000ff) + Math.round(255 * amount)));
  return `#${((r << 16) | (g << 8) | b).toString(16).padStart(6, "0")}`;
}
