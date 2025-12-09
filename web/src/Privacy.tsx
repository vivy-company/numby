import React from "react";

export function Privacy() {
  return (
    <div className="w-full overflow-x-hidden">
      <main className="py-20 px-6">
        <div className="max-w-[720px] mx-auto">
          <h1 className="text-[56px] font-semibold mb-8 tracking-tight">Privacy Policy</h1>
          <p className="text-[#86868b] text-[17px] mb-12">Last updated: November 30, 2025</p>

          <div className="space-y-8 text-[#86868b] text-[17px] leading-[1.47059]">
            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Overview</h2>
              <p>
                Numby is designed with privacy as a core principle. All calculations are processed locally on your device.
                We do not collect, store, or transmit your calculation data or personal information.
              </p>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Data Collection</h2>
              <p className="mb-4">Numby does not collect any personal data. Specifically:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>No analytics or tracking</li>
                <li>No user accounts or authentication</li>
                <li>No telemetry or crash reports</li>
                <li>No advertising or third-party integrations</li>
              </ul>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Local Storage</h2>
              <p>
                All your data stays on your device. Numby stores configuration and calculation history locally in
                <code className="text-[#89dceb] font-mono text-[15px]"> ~/.numby/</code> on your computer.
                This data never leaves your device.
              </p>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Currency Exchange Rates</h2>
              <p>
                When updating currency exchange rates, Numby makes anonymous requests to a free public API.
                No identifying information is sent. The rates are cached locally and work offline.
              </p>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Share Feature</h2>
              <p className="mb-4">
                When you use the "Copy as Link" share feature, the following information is encoded in the URL:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-4">
                <li>Your calculation expressions and results</li>
                <li>The selected theme name</li>
              </ul>
              <p className="mb-4">
                When someone opens a share link:
              </p>
              <ul className="list-disc pl-6 space-y-2 mb-4">
                <li>The calculation data is decoded and displayed on our web server</li>
                <li>An image preview is generated server-side for social media (Open Graph)</li>
                <li>No data is permanently stored on our servers</li>
                <li>No analytics or tracking is performed on share pages</li>
              </ul>
              <p>
                <span className="text-[#f5f5f7] font-medium">Important:</span> Share links are public. Anyone with the link can view
                the calculation content. Do not share links containing sensitive or personal information.
              </p>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Open Source</h2>
              <p>
                Numby is open source software. You can review the entire codebase at{" "}
                <a href="https://github.com/vivy-company/numby" className="text-blue-500 hover:underline">
                  github.com/vivy-company/numby
                </a>{" "}
                to verify our privacy claims.
              </p>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Contact</h2>
              <p>
                For privacy questions or concerns, please open an issue on our{" "}
                <a href="https://github.com/vivy-company/numby/issues" className="text-blue-500 hover:underline">
                  GitHub repository
                </a>.
              </p>
            </div>
          </div>

          <div className="mt-16 pt-8 border-t border-white/8">
            <a href="/" className="text-blue-500 hover:underline">← Back to Home</a>
          </div>
        </div>
      </main>
    </div>
  );
}

export default Privacy;
