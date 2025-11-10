class Numby < Formula
  desc "A powerful natural language calculator with a terminal user interface"
  homepage "https://github.com/wiedymi/numby"
  version "0.1.0"

  livecheck do
    url :homepage
    strategy :github_releases
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/wiedymi/numby/releases/download/v#{version}/numby-macos-aarch64"
    sha256 "TODO: Add SHA256 for aarch64 binary"
  else
    url "https://github.com/wiedymi/numby/releases/download/v#{version}/numby-macos-x86_64"
    sha256 "TODO: Add SHA256 for x86_64 binary"
  end

  head do
    url "https://github.com/wiedymi/numby.git"
    depends_on "rust" => :build
  end

  def install
    bin.install "numby"
  end

  test do
    assert_match "numby", shell_output("#{bin}/numby --version")
    assert_equal "5", shell_output("#{bin}/numby '2 + 3'").strip
  end
end