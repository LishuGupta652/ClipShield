cask "clipshield" do
  version "0.1.0"
  sha256 "ab0ccb591e413901020e4272205ff1d3c212e958626a5e47baa31ed29ab8e033"

  url "https://github.com/lishugupta652/clipshield/releases/download/#{version}/ClipShield-#{version}.zip"
  name "ClipShield"
  desc "Clipboard guardian that redacts PII before you paste"
  homepage "https://github.com/lishugupta652/clipshield"

  depends_on macos: ">= :ventura"

  app "ClipShield.app"
end
