cask "clipshield" do
  version "0.1.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/yourname/clipshield/releases/download/#{version}/ClipShield-#{version}.zip"
  name "ClipShield"
  desc "Clipboard guardian that redacts PII before you paste"
  homepage "https://github.com/yourname/clipshield"

  depends_on macos: ">= :ventura"

  app "ClipShield.app"
end
