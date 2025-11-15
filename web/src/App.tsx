import React, { useState } from "react";
import {
  Calculator,
  Globe,
  History,
  Variable,
  Ruler,
  Percent,
  Languages,
  Terminal,
  Copy,
  Check,
  Github,
  Apple,
} from "lucide-react";
import logo from "./logo.png";
import screenshotRecipe from "./screenshot-recipe.png";
import screenshotFinance from "./screenshot-finance.png";
import screenshotBills from "./screenshot-bills.png";
import screenshotTravel from "./screenshot-travel.png";
import screenshotTui from "./screenshot-tui.png";
import appStoreBadge from "./app-store-badge.svg";
import { useLanguage, LanguageProvider } from "./i18n/LanguageContext";
import { LanguageSelector } from "./i18n/LanguageSelector";

function AppContent() {
  const { t } = useLanguage();
  const [activeTab, setActiveTab] = useState("macos");
  const [copied, setCopied] = useState(false);

  const screenshots = {
    macos: screenshotFinance,
    cli: screenshotTui,
  };

  const copyInstallCommand = () => {
    navigator.clipboard.writeText("curl -fsSL https://numby.vivy.app/install.sh | bash");
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="w-full overflow-x-hidden">
      {/* Hero Section */}
      <section className="relative text-center py-20 px-6 pb-10 bg-[radial-gradient(ellipse_80%_50%_at_50%_-20%,rgba(0,113,227,0.15),transparent)] animate-[gradient-shift_15s_ease-in-out_infinite]">
        <div className="max-w-[980px] mx-auto">
          <div className="inline-block mb-8">
            <img src={logo} alt="Numby" className="w-28 h-28 drop-shadow-[0_0_40px_rgba(0,113,227,0.3)]" />
          </div>
          <h1 className="text-8xl font-semibold tracking-tight mb-6 leading-none">{t("hero.title")}</h1>
          <p className="text-[28px] text-[#86868b] mb-12">
            {t("hero.subtitle")}
          </p>
          <div className="flex flex-col items-center gap-3 mb-6">
            <div className="flex justify-center mb-2">
              <div className="relative pb-6">
                <div className="opacity-50 cursor-not-allowed">
                  <img src={appStoreBadge} alt="Download on the App Store" className="h-[52px] block rounded-[8px]" />
                </div>
                <span className="absolute -bottom-1 left-1/2 -translate-x-1/2 text-[11px] text-[#86868b] whitespace-nowrap">
                  {t("hero.comingSoon")}
                </span>
              </div>
            </div>
            <p className="text-sm text-[#86868b]">
              {t("hero.pricingPrefix")}
              <span className="text-[#34c759] font-semibold">{t("hero.pricingFree")}</span>
              {t("hero.pricingSuffix")}
            </p>
          </div>
          <div className="mt-6 max-w-[580px] mx-auto">
            <p className="text-[13px] text-[#86868b] mb-2 text-center">
              {t("hero.installLabel")}
            </p>
            <div
              onClick={copyInstallCommand}
              className="bg-black/30 border border-white/10 rounded-xl px-4 py-3.5 cursor-pointer hover:bg-black/40 hover:border-white/20 transition-all duration-200 group flex items-center gap-3"
            >
              <Terminal size={18} className="text-[#86868b] flex-shrink-0" />
              <code className="font-mono text-[13px] flex-1">
                <span className="text-[#89dceb]">curl</span>{" "}
                <span className="text-[#f38ba8]">-fsSL</span>{" "}
                <span className="text-[#a6e3a1]">https://numby.vivy.app/install.sh</span>{" "}
                <span className="text-[#cdd6f4]">|</span>{" "}
                <span className="text-[#89dceb]">bash</span>
              </code>
              <div className="flex-shrink-0">
                {copied ? (
                  <Check size={16} className="text-green-500" />
                ) : (
                  <Copy size={16} className="text-[#86868b] group-hover:text-[#0071e3] transition-colors" />
                )}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Visual Showcase */}
      <section className="py-12 px-6 pb-20">
        <div className="max-w-[1200px] mx-auto">
          <div className="flex gap-2 justify-center mb-2 flex-wrap">
            {(["macos", "cli"] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-4 py-2 rounded-full text-[17px] cursor-pointer transition-all duration-200 border-none ${
                  activeTab === tab
                    ? "bg-[#1d1d1f] text-[#f5f5f7]"
                    : "bg-transparent text-[#86868b] hover:text-[#f5f5f7]"
                }`}
              >
                {tab === "macos" ? t("showcase.app") : t("showcase.terminal")}
              </button>
            ))}
          </div>
          <div className="rounded-[18px] overflow-hidden">
            <img src={screenshots[activeTab as keyof typeof screenshots]} alt={`${activeTab} example`} className="w-full block" />
          </div>
        </div>
      </section>

      {/* Features Bento Grid */}
      <section className="py-20 px-6">
        <div className="max-w-[1200px] mx-auto">
          <h2 className="text-[56px] md:text-[56px] text-[36px] font-semibold text-center mb-16 tracking-tight">{t("features.title")}</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
            {[
              { icon: Calculator, bg: "rgba(0,113,227,0.1)", color: "#0071e3", key: "naturalLanguage", span: true },
              { icon: Ruler, bg: "rgba(255,149,0,0.1)", color: "#ff9500", key: "unitConversions" },
              { icon: Globe, bg: "rgba(52,199,89,0.1)", color: "#34c759", key: "currencies" },
              { icon: Percent, bg: "rgba(175,82,222,0.1)", color: "#af52de", key: "percentages" },
              { icon: Variable, bg: "rgba(255,59,48,0.1)", color: "#ff3b30", key: "variables" },
              { icon: Languages, bg: "rgba(255,204,0,0.1)", color: "#ffcc00", key: "languages" },
              { icon: History, bg: "rgba(0,113,227,0.1)", color: "#0071e3", key: "files" },
            ].map((feature, i) => (
              <div
                key={i}
                className={`bg-white/[0.03] border border-white/8 rounded-3xl p-8 backdrop-blur-xl transition-all duration-300 hover:-translate-y-1.5 hover:shadow-[0_20px_40px_rgba(0,0,0,0.3)] hover:border-white/12 relative overflow-hidden group ${feature.span ? "md:col-span-2 lg:col-span-2" : ""}`}
              >
                <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_0%,rgba(0,113,227,0.1),transparent)] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <div
                  className="w-12 h-12 rounded-xl flex items-center justify-center mb-4 border border-white/8"
                  style={{ background: feature.bg }}
                >
                  <feature.icon size={24} color={feature.color} />
                </div>
                <h3 className="text-2xl font-semibold mb-3 tracking-tight">{t(`features.${feature.key}.title`)}</h3>
                <p className="text-[#86868b] text-[17px] leading-[1.47059]">{t(`features.${feature.key}.desc`)}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="py-20 px-6">
        <div className="max-w-[720px] mx-auto">
          <h2 className="text-[56px] font-semibold text-center mb-16 tracking-tight">{t("howItWorks.title")}</h2>
          <div className="flex flex-col gap-10">
            {[
              { num: "1", key: "step1" },
              { num: "2", key: "step2" },
              { num: "3", key: "step3" },
            ].map((step) => (
              <div key={step.num} className="flex gap-6 items-start">
                <span className="text-[40px] font-bold text-[#0071e3] font-mono min-w-[60px]">{step.num}</span>
                <div>
                  <h3 className="text-2xl font-semibold mb-2 tracking-tight">{t(`howItWorks.${step.key}.title`)}</h3>
                  <p className="text-[#86868b] text-[17px] leading-[1.47059]">{t(`howItWorks.${step.key}.desc`)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-20 px-6">
        <div className="max-w-[720px] mx-auto">
          <h2 className="text-[56px] font-semibold text-center mb-16 tracking-tight">{t("faq.title")}</h2>
          <div className="flex flex-col gap-8">
            {["q1", "q2", "q3", "q4", "q5", "q6"].map((qKey) => {
              const answer = t(`faq.${qKey}.answer`);

              // For q2, highlight "completely free" and "$5.99"
              const renderQ2 = () => {
                const freeTerms = ["completely free", "completamente gratuita", "complètement gratuit", "vollständig kostenlos", "完全無料", "полностью бесплатная", "цалкам бясплатная", "完全免费"];
                const freeTerm = freeTerms.find(term => answer.includes(term)) || "completely free";
                const parts = answer.split(freeTerm);
                const afterFree = parts[1] || "";
                const priceParts = afterFree.split("$5.99");

                return (
                  <>
                    {parts[0]}
                    <span className="text-[#34c759] font-semibold">{freeTerm}</span>
                    {priceParts[0]}
                    <span className="text-[#0071e3]">$5.99</span>
                    {priceParts[1]}
                  </>
                );
              };

              return (
                <div key={qKey}>
                  <h3 className="text-[21px] font-semibold mb-3 tracking-tight">{t(`faq.${qKey}.question`)}</h3>
                  <p className="text-[#86868b] text-[17px] leading-[1.47059]">
                    {qKey === "q2" ? renderQ2() : (
                      <span dangerouslySetInnerHTML={{ __html: answer
                        .replace(/x = 100/g, '<code class="text-[#89dceb] font-mono text-[15px]">x = 100</code>')
                        .replace(/prev/g, '<code class="text-[#89dceb] font-mono text-[15px]">prev</code>')
                        .replace(/sum/g, '<code class="text-[#89dceb] font-mono text-[15px]">sum</code>')
                        .replace(/average/g, '<code class="text-[#89dceb] font-mono text-[15px]">average</code>')
                        .replace(/\.numby/g, '<code class="text-[#89dceb] font-mono text-[15px]">.numby</code>')
                        .replace(/:w/g, '<code class="text-[#89dceb] font-mono text-[15px]">:w</code>')
                        .replace(/numby myfile\.numby/g, '<code class="text-[#89dceb] font-mono text-[15px]">numby myfile.numby</code>')
                      }} />
                    )}
                  </p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-6 border-t border-white/8 mt-20">
        <div className="max-w-[1200px] mx-auto flex justify-between items-center flex-wrap gap-6">
          <p className="text-sm text-[#86868b]">{t("footer.copyright")}</p>
          <div className="flex gap-6 items-center">
            <a href="/privacy" className="text-sm text-[#86868b] hover:text-[#0071e3] transition-colors duration-200">
              {t("footer.privacy")}
            </a>
            <a href="/eula" className="text-sm text-[#86868b] hover:text-[#0071e3] transition-colors duration-200">
              {t("footer.eula")}
            </a>
            <a href="https://github.com/vivy-company/numby" className="text-sm text-[#86868b] hover:text-[#0071e3] transition-colors duration-200">
              {t("footer.github")}
            </a>
            <a href="https://github.com/vivy-company/numby/issues" className="text-sm text-[#86868b] hover:text-[#0071e3] transition-colors duration-200">
              {t("footer.reportIssue")}
            </a>
            <LanguageSelector />
          </div>
        </div>
      </footer>
    </div>
  );
}

export function App() {
  return (
    <LanguageProvider>
      <AppContent />
    </LanguageProvider>
  );
}

export default App;
