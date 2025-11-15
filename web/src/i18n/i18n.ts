import en from "./translations/en.json";
import es from "./translations/es.json";
import fr from "./translations/fr.json";
import de from "./translations/de.json";
import ja from "./translations/ja.json";
import ru from "./translations/ru.json";
import be from "./translations/be.json";
import zhCN from "./translations/zh-CN.json";
import zhTW from "./translations/zh-TW.json";

export type Language = "en" | "es" | "fr" | "de" | "ja" | "ru" | "be" | "zh-CN" | "zh-TW";

export const languages: Record<Language, string> = {
  "en": "English",
  "es": "Español",
  "fr": "Français",
  "de": "Deutsch",
  "ja": "日本語",
  "ru": "Русский",
  "be": "Беларуская",
  "zh-CN": "简体中文",
  "zh-TW": "繁體中文",
};

export const translations: Record<Language, typeof en> = {
  en,
  es,
  fr,
  de,
  ja,
  ru,
  be,
  "zh-CN": zhCN,
  "zh-TW": zhTW,
};

const STORAGE_KEY = "numby-language";

export function detectLanguage(): Language {
  // 1. Check localStorage for saved preference
  const saved = localStorage.getItem(STORAGE_KEY) as Language | null;
  if (saved && saved in translations) {
    return saved;
  }

  // 2. Check browser language
  const browserLang = navigator.language || navigator.languages?.[0] || "en";

  // Exact match
  if (browserLang in translations) {
    return browserLang as Language;
  }

  // Match prefix (e.g., "en-US" → "en")
  const prefix = browserLang.split("-")[0];
  if (prefix && prefix in translations) {
    return prefix as Language;
  }

  // Special handling for Chinese
  if (browserLang.startsWith("zh")) {
    return browserLang.includes("TW") || browserLang.includes("HK") ? "zh-TW" : "zh-CN";
  }

  // 3. Fallback to English
  return "en";
}

export function saveLanguage(lang: Language): void {
  localStorage.setItem(STORAGE_KEY, lang);
}

export function getTranslation(lang: Language, key: string): string {
  const keys = key.split(".");
  let value: any = translations[lang];

  for (const k of keys) {
    value = value?.[k];
    if (value === undefined) {
      // Fallback to English if translation missing
      value = translations.en;
      for (const k2 of keys) {
        value = value?.[k2];
      }
      break;
    }
  }

  return value || key;
}
