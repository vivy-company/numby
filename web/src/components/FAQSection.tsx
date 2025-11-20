import React from "react";
import { useLanguage } from "../i18n/LanguageContext";

export default function FAQSection() {
  const { t } = useLanguage();

  return (
    <section className="py-20 px-6">
      <div className="max-w-[720px] mx-auto">
        <h2 className="text-[56px] font-semibold text-center mb-16 tracking-tight">{t("faq.title")}</h2>
        <div className="flex flex-col gap-8">
          {["q1", "q2", "q3", "q4", "q5", "q6"].map((qKey) => {
            const answer = t(`faq.${qKey}.answer`);

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
                  <span className="text-blue-500">$5.99</span>
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
  );
}
