#!/usr/bin/env bun
/**
 * Export themes from ThemeData.swift to themes.json for web use
 * Run: bun scripts/export-themes.ts
 */

import { readFileSync, writeFileSync } from "fs";

const THEME_DATA_PATH = "../Numby/Numby/Core/ThemeData.swift";
const THEME_SWIFT_PATH = "../Numby/Numby/Core/Theme.swift";
const OUTPUT_PATH = "./src/themes.json";

interface SyntaxColors {
  text: string;
  background: string;
  numbers: string;
  operators: string;
  keywords: string;
  functions: string;
  constants: string;
  variables: string;
  variableUsage: string;
  assignment: string;
  currency: string;
  units: string;
  results: string;
  comments: string;
}

interface Theme {
  name: string;
  syntax: SyntaxColors;
}

function parseThemeData(content: string): Record<string, SyntaxColors> {
  const themes: Record<string, SyntaxColors> = {};

  // Match Theme blocks
  const themeRegex = /Theme\(\s*name:\s*"([^"]+)",\s*syntax:\s*SyntaxColors\(\s*text:\s*"([^"]+)",\s*background:\s*"([^"]+)",\s*numbers:\s*"([^"]+)",\s*operators:\s*"([^"]+)",\s*keywords:\s*"([^"]+)",\s*functions:\s*"([^"]+)",\s*constants:\s*"([^"]+)",\s*variables:\s*"([^"]+)",\s*variableUsage:\s*"([^"]+)",\s*assignment:\s*"([^"]+)",\s*currency:\s*"([^"]+)",\s*units:\s*"([^"]+)",\s*results:\s*"([^"]+)",\s*comments:\s*"([^"]+)"/g;

  let match;
  while ((match = themeRegex.exec(content)) !== null) {
    const [, name, text, background, numbers, operators, keywords, functions, constants, variables, variableUsage, assignment, currency, units, results, comments] = match;

    themes[name] = {
      text,
      background,
      numbers,
      operators,
      keywords,
      functions,
      constants,
      variables,
      variableUsage,
      assignment,
      currency,
      units,
      results,
      comments,
    };
  }

  return themes;
}

function parseCatppuccinThemes(content: string): Record<string, SyntaxColors> {
  const themes: Record<string, SyntaxColors> = {};

  // Catppuccin themes are defined differently, extract them manually
  const catppuccinData: Record<string, SyntaxColors> = {
    "Catppuccin Latte": {
      text: "#4C4F69",
      background: "#EFF1F5",
      numbers: "#04A5E5",
      operators: "#FE640B",
      keywords: "#8839EF",
      functions: "#DF8E1D",
      constants: "#1E66F5",
      variables: "#7287FD",
      variableUsage: "#EA76CB",
      assignment: "#D20F39",
      currency: "#40A02B",
      units: "#179299",
      results: "#40A02B",
      comments: "#9CA0B0",
    },
    "Catppuccin Frappé": {
      text: "#C6D0F5",
      background: "#303446",
      numbers: "#85C1DC",
      operators: "#EF9F76",
      keywords: "#CA9EE6",
      functions: "#E5C890",
      constants: "#8CAAEE",
      variables: "#BABBF1",
      variableUsage: "#F4B8E4",
      assignment: "#E78284",
      currency: "#A6D189",
      units: "#81C8BE",
      results: "#A6D189",
      comments: "#838BA7",
    },
    "Catppuccin Macchiato": {
      text: "#CAD3F5",
      background: "#24273A",
      numbers: "#7DC4E4",
      operators: "#F5A97F",
      keywords: "#C6A0F6",
      functions: "#EED49F",
      constants: "#8AADF4",
      variables: "#B7BDF8",
      variableUsage: "#F5BDE6",
      assignment: "#EE99A0",
      currency: "#A6DA95",
      units: "#8BD5CA",
      results: "#A6DA95",
      comments: "#5B6078",
    },
    "Catppuccin Mocha": {
      text: "#CDD6F4",
      background: "#1E1E2E",
      numbers: "#74C7EC",
      operators: "#FAB387",
      keywords: "#CBA6F7",
      functions: "#F9E2AF",
      constants: "#89B4FA",
      variables: "#B4BEFE",
      variableUsage: "#F5C2E7",
      assignment: "#EBA0AC",
      currency: "#A6E3A1",
      units: "#94E2D5",
      results: "#A6E3A1",
      comments: "#585B70",
    },
  };

  return catppuccinData;
}

async function main() {
  console.log("Reading theme data...");

  const themeDataContent = readFileSync(THEME_DATA_PATH, "utf-8");

  // Parse all themes
  const themes = parseThemeData(themeDataContent);
  const catppuccinThemes = parseCatppuccinThemes(themeDataContent);

  // Merge all themes
  const allThemes = { ...catppuccinThemes, ...themes };

  console.log(`Found ${Object.keys(allThemes).length} themes`);

  // Write to JSON
  writeFileSync(OUTPUT_PATH, JSON.stringify(allThemes, null, 2));

  console.log(`Exported to ${OUTPUT_PATH}`);

  // Print size info
  const jsonStr = JSON.stringify(allThemes);
  console.log(`JSON size: ${(jsonStr.length / 1024).toFixed(2)} KB`);
}

main();
