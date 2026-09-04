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
  [fzf]=fzf
  [gitui]=gitui
  [tig]=tig
  [xclip]=xclip
  [awscli2]=aws
  [jsonnet]=jsonnet
  [maven]=mvn
  [opentofu]=tofu
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

cat <<'EOF'

Done. Notes:
  - bun/pnpm install into $HOME; open a new shell (or `source ~/.zshrc`)
    to pick up their PATH/completions entries already wired up in this
    dotfiles repo.
EOF
