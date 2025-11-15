class Numby < Formula
  desc "Powerful natural language calculator with terminal user interface"
  homepage "https://github.com/vivy-company/numby"
  version "0.1.3"
  license "MIT"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/vivy-company/numby/releases/download/v0.1.3/numby-v0.1.3-macos-x86_64.tar.gz"
      sha256 "552f20fb1cb811c92f7982152c6ce1e06d6c1d0dd18067dafedaa55e8c232f2c"
    elsif Hardware::CPU.arm?
      url "https://github.com/vivy-company/numby/releases/download/v0.1.3/numby-v0.1.3-macos-aarch64.tar.gz"
      sha256 "675c7433efd9a2dd2054becf59c755c7e274eb852407a6422e004b8ae9b6445e"
    end
  end

  def install
    bin.install "numby-v0.1.3-macos-#{Hardware::CPU.arch}" => "numby"
  end

  test do
    assert_match "numby 0.1.3", shell_output("#{bin}/numby --version")
  end
end
