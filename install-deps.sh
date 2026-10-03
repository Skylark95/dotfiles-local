#!/usr/bin/env bash
#
# Installs software referenced by these dotfiles that isn't part of the
# dotbot symlink setup. Written for Fedora (dnf) - the OS this was generated
# on. Safe to re-run: each step skips software that's already installed.
#
# Needs sudo for the dnf-installed packages; the rest install into $HOME.

set -euo pipefail

have() { command -v "$1" &>/dev/null; }

echo "==> Installing dnf packages"
dnf_pkgs=()
declare -A dnf_bin=(
  [diff-so-fancy]=diff-so-fancy
  [fd-find]=fd
  [fzf]=fzf
  [gitui]=gitui
  [tig]=tig
  [xclip]=xclip
  [awscli2]=aws
  [jsonnet]=jsonnet
  [maven]=mvn
  [opentofu]=tofu
  [sqlite]=sqlite3
  [zsh]=zsh
)
for pkg in "${!dnf_bin[@]}"; do
  have "${dnf_bin[$pkg]}" || dnf_pkgs+=("$pkg")
done
if [[ ${#dnf_pkgs[@]} -gt 0 ]]; then
  sudo dnf install -y "${dnf_pkgs[@]}"
else
  echo "    already installed"
fi

echo "==> Installing bun"
if have bun; then
  echo "    already installed"
else
  curl -fsSL https://bun.sh/install | bash
fi

echo "==> Installing pnpm"
if have pnpm; then
  echo "    already installed"
else
  npm install -g pnpm
fi

echo "==> Installing lazygit"
if have lazygit; then
  echo "    already installed"
else
  # Not packaged in the Fedora repos; install the latest release into ~/.local/bin
  lazygit_version=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep -Po '"tag_name": *"v\K[^"]*')
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/lazygit_${lazygit_version}_Linux_x86_64.tar.gz"
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  install -D "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$tmp"
fi

cat <<'EOF'

Done. Notes:
  - bun/pnpm/lazygit install into $HOME; open a new shell (or `source ~/.zshrc`)
    to pick up their PATH/completions entries already wired up in this
    dotfiles repo.
EOF
