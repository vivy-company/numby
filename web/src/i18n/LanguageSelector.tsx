import React from "react";
import { Globe, ChevronDown } from "lucide-react";
import { useLanguage } from "./LanguageContext";
import { Language, languages } from "./i18n";

export function LanguageSelector() {
  const { language, setLanguage } = useLanguage();

  return (
    <div className="relative inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-white/10 bg-white/5 hover:bg-white/10 transition-all duration-200">
      <Globe size={14} className="text-[#86868b]" aria-hidden="true" />
      <select
        value={language}
        onChange={(e) => setLanguage(e.target.value as Language)}
        className="appearance-none bg-transparent text-zinc-500 hover:text-blue-500 text-sm transition-colors duration-200 cursor-pointer pr-5 outline-none border-none"
        aria-label="Select language"
      >
        {Object.entries(languages).map(([code, name]) => (
          <option key={code} value={code} className="bg-black text-[#f5f5f7]">
            {name}
          </option>
        ))}
      </select>
      <ChevronDown size={12} className="absolute right-2 top-1/2 -translate-y-1/2 pointer-events-none text-[#86868b]" aria-hidden="true" />
    </div>
  );
}
