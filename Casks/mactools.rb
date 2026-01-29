cask "mactools" do
  version "1.0.0"
  sha256 "8e56ac0310281aeb45ae391caffdbc8fe4f57edb55052668b47decfdc4c7fe18"

  url "https://github.com/LishuGupta652/macos-toolkit/releases/download/1.0.0/MacTools-#{version}.zip"
  name "MacTools"
  desc "Personal macOS menu bar toolkit"
  homepage "https://github.com/LishuGupta652/macos-toolkit"

  depends_on macos: ">= :ventura"

  app "MacTools.app"
end
