import React from "react";

export function Eula() {
  return (
    <div className="w-full overflow-x-hidden">
      <main className="py-20 px-6">
        <div className="max-w-[720px] mx-auto">
          <h1 className="text-[56px] font-semibold mb-8 tracking-tight">End User License Agreement</h1>
          <p className="text-[#86868b] text-[17px] mb-12">Last updated: November 30, 2025</p>

          <div className="space-y-8 text-[#86868b] text-[17px] leading-[1.47059]">
            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">License</h2>
              <p>
                Numby is licensed under the <span className="text-[#f5f5f7] font-medium">MIT License</span>.
                This applies to the open source CLI and TUI versions available on GitHub.
              </p>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">MIT License</h2>
              <p className="mb-4">
                Permission is hereby granted, free of charge, to any person obtaining a copy of this software
                and associated documentation files (the "Software"), to deal in the Software without restriction,
                including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
                and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
                subject to the following conditions:
              </p>
              <p className="mb-4">
                The above copyright notice and this permission notice shall be included in all copies or substantial
                portions of the Software.
              </p>
              <p className="uppercase">
                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
                LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
                IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
                WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
                SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
              </p>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">macOS App Store Version</h2>
              <p>
                The macOS app distributed via the App Store is subject to Apple's standard End User License Agreement (EULA)
                in addition to this license. By purchasing and using the App Store version, you agree to both Apple's terms
                and the MIT License terms above.
              </p>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Acceptable Use</h2>
              <p className="mb-4">You may use Numby for any lawful purpose, including:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Personal calculations and financial planning</li>
                <li>Professional or commercial use</li>
                <li>Educational purposes</li>
                <li>Integration into other software (open source version)</li>
              </ul>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Share Feature</h2>
              <p className="mb-4">
                When using the share feature to generate public links:
              </p>
              <ul className="list-disc pl-6 space-y-2">
                <li>You are responsible for the content you share</li>
                <li>Do not share calculations containing sensitive, confidential, or personal information</li>
                <li>Shared content may be cached by browsers, CDNs, or social media platforms</li>
                <li>Share links are stateless - the data is encoded directly in the URL, not stored on our servers</li>
                <li>Once shared, links cannot be revoked or deleted - only stop sharing the URL</li>
              </ul>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Disclaimer</h2>
              <p>
                Numby is provided as a calculation tool. While we strive for accuracy, we cannot guarantee that all
                calculations or currency conversions are error-free. Always verify critical calculations independently.
                We are not liable for any financial decisions made based on Numby's output.
              </p>
            </div>

            <div>
              <h2 className="text-[32px] font-semibold text-[#f5f5f7] mb-4 tracking-tight">Contact</h2>
              <p>
                For questions about this EULA, please contact us via{" "}
                <a href="https://github.com/vivy-company/numby/issues" className="text-blue-500 hover:underline">
                  GitHub Issues
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

export default Eula;
