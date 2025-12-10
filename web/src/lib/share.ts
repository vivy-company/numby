/**
 * Share URL encoding/decoding utilities
 */

import pako from "pako";

export interface SharePayload {
  v: number; // version
  l: [string, string][]; // lines: [expression, result][]
  t: string; // theme name
}

/**
 * Decode share data from URL fragment or query param
 */
export function decodeShareData(encoded: string): SharePayload | null {
  try {
    // Convert base64url to base64
    let base64 = encoded.replace(/-/g, "+").replace(/_/g, "/");

    // Add padding if needed
    while (base64.length % 4) {
      base64 += "=";
    }

    // Decode base64 to bytes
    const binaryStr = atob(base64);
    const bytes = new Uint8Array(binaryStr.length);
    for (let i = 0; i < binaryStr.length; i++) {
      bytes[i] = binaryStr.charCodeAt(i);
    }

    // Decompress (iOS uses raw deflate without zlib headers)
    const decompressed = pako.inflateRaw(bytes, { to: "string" });

    // Parse JSON
    const payload = JSON.parse(decompressed) as SharePayload;

    // Validate
    if (payload.v !== 1 || !Array.isArray(payload.l)) {
      return null;
    }

    return payload;
  } catch (e) {
    console.error("Failed to decode share data:", e);
    return null;
  }
}

/**
 * Encode share data for URL
 */
export function encodeShareData(payload: SharePayload): string {
  // JSON stringify
  const json = JSON.stringify(payload);

  // Compress (use raw deflate to match iOS)
  const compressed = pako.deflateRaw(json);

  // Convert to base64url
  let base64 = btoa(String.fromCharCode(...compressed));

  // Make URL-safe
  base64 = base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  return base64;
}

/**
 * Generate full share URL
 */
export function generateShareURL(
  lines: [string, string][],
  theme: string
): string {
  const payload: SharePayload = {
    v: 1,
    l: lines,
    t: theme,
  };

  const encoded = encodeShareData(payload);
  return `https://numby.vivy.app/s#${encoded}`;
}
