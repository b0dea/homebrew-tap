# frozen_string_literal: true

# Homebrew formula for fortkeep. It lives here and is copied to the b0dea/homebrew-tap repository as Formula/fortkeep.rb
# when a release is published; ci/release-pins.sh prints the url, sha256 and COMMIT to paste in.
#
# Why fortkeep itself isn't in the Cellar: fortkeep runs from a git checkout of a signed release tag. Its agent guards
# load from that folder, your settings and results live in it, its integrity check compares the folder with the signed
# tag, and `fortkeep update` moves it between signed tags. A Cellar copy has no git history, and `brew upgrade` would
# swap it under the guards. So this formula installs only a small shim. On first run the shim makes that checkout in
# ~/.local/share/fortkeep with the release's own install.sh, pinned to this release's commit, then hands over to it.
class Fortkeep < Formula
  desc "Security checkup for developer Macs, run with your coding agent"
  homepage "https://github.com/b0dea/fortkeep"
  url "https://github.com/b0dea/fortkeep/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "c788d19f39d77cb50e5a179eb7b183de6e1a7af81ea94b4f3a4380b7b1e34d8f"
  license "MIT"

  # The release tag's commit: install.sh refuses a clone whose tag isn't exactly this commit.
  COMMIT = "e05b647162e33c0b8b58b77fb85ad5358205250a"

  depends_on macos: :sequoia

  def install
    libexec.install "install.sh"
    (bin/"fortkeep").write <<~SH
      #!/bin/bash
      # fortkeep's Homebrew shim: makes the checkout of release v#{version} on first run, then runs fortkeep from it.
      # The installer talks on stderr, so the first `fortkeep version --json` or `check --json` prints only its JSON.
      d="$HOME/.local/share/fortkeep"
      if [ ! -x "$d/bin/fortkeep" ]; then
        /bin/bash "#{libexec}/install.sh" --tag "v#{version}" --commit "#{COMMIT}" --no-link >&2 || exit
      fi
      exec "$d/bin/fortkeep" "$@"
    SH
  end

  def caveats
    <<~EOS
      The first time you run fortkeep, it clones release v#{version} into ~/.local/share/fortkeep and checks its
      signature. Updates come from `fortkeep update`, not `brew upgrade`. Start with: fortkeep agent
    EOS
  end

  test do
    system "/bin/bash", "-n", libexec/"install.sh"
  end
end
