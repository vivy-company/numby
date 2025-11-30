/**
 * Shared type definitions
 */

export interface SyntaxColors {
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

export type ThemeMap = Record<string, SyntaxColors>;
