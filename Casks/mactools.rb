cask "mactools" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256"

  url "https://github.com/yourname/mactools/releases/download/v#{version}/MacTools-#{version}.zip"
  name "MacTools"
  desc "Personal macOS menu bar toolkit"
  homepage "https://github.com/yourname/mactools"

  depends_on macos: ">= :ventura"

  app "MacTools.app"
end
