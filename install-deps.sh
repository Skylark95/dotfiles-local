#!/usr/bin/env bash
#
# Installs software referenced by these dotfiles that isn't part of the
# dotbot symlink setup. Written for Debian (apt) on a Chromebook - the apt
# counterpart of the fedora branch's install-deps.sh. Safe to re-run: each
# step skips software that's already installed.
#
# Needs sudo for the apt-installed packages; the rest install into $HOME.

set -euo pipefail

have() { command -v "$1" &>/dev/null; }

case "$(uname -m)" in
  x86_64)  arch_amd=amd64 arch_gnu=x86_64 ;;
  aarch64) arch_amd=arm64 arch_gnu=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# True if apt knows a candidate version for the package
apt_has() { [[ -n "$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ && $2 != "(none)" {print $2}')" ]]; }

echo "==> Installing apt packages"
# package=binary (jq is used by the Claude Code status line)
declare -A apt_bin=(
  [awscli]=aws
  [curl]=curl
  [fd-find]=fdfind
  [fzf]=fzf
  [jq]=jq
  [jsonnet]=jsonnet
  [maven]=mvn
  [sqlite3]=sqlite3
  [tig]=tig
  [xclip]=xclip
  [zsh]=zsh
)
# diff-so-fancy is only packaged from Debian 13 on; older releases get it
# from the zgenom plugin instead
apt_has diff-so-fancy && apt_bin[diff-so-fancy]=diff-so-fancy
apt_pkgs=()
for pkg in "${!apt_bin[@]}"; do
  have "${apt_bin[$pkg]}" || apt_pkgs+=("$pkg")
done
# Snacks (LazyVim) dlopen()s the unversioned libsqlite3.so, which only ships
# in the -dev package
[[ -e /usr/lib/x86_64-linux-gnu/libsqlite3.so || -e /usr/lib/aarch64-linux-gnu/libsqlite3.so ]] \
  || apt_pkgs+=(libsqlite3-dev)
if [[ ${#apt_pkgs[@]} -gt 0 ]]; then
  sudo apt-get update
  sudo apt-get install -y "${apt_pkgs[@]}"
else
  echo "    already installed"
fi

# Debian names the fd binary fdfind; expose it as fd
echo "==> Linking fd"
if have fd; then
  echo "    already installed"
elif have fdfind; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
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

# Latest GitHub release tag without the leading v
latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*'
}

echo "==> Installing lazygit"
if have lazygit; then
  echo "    already installed"
else
  version=$(latest_tag jesseduffield/lazygit)
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/lazygit.tar.gz" \
    "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch_gnu}.tar.gz"
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  install -D "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$tmp"
fi

echo "==> Installing gitui"
if have gitui; then
  echo "    already installed"
else
  # Not packaged in Debian 12; install the latest release into ~/.local/bin
  version=$(latest_tag gitui-org/gitui)
  case "$arch_gnu" in x86_64) gitui_arch=x86_64 ;; *) gitui_arch=aarch64 ;; esac
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/gitui.tar.gz" \
    "https://github.com/gitui-org/gitui/releases/download/v${version}/gitui-linux-${gitui_arch}.tar.gz"
  tar -xzf "$tmp/gitui.tar.gz" -C "$tmp" gitui
  install -D "$tmp/gitui" "$HOME/.local/bin/gitui"
  rm -rf "$tmp"
fi

echo "==> Installing opentofu"
if have tofu; then
  echo "    already installed"
else
  # Not packaged in Debian; install the latest release into ~/.local/bin
  version=$(latest_tag opentofu/opentofu)
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/tofu.tar.gz" \
    "https://github.com/opentofu/opentofu/releases/download/v${version}/tofu_${version}_linux_${arch_amd}.tar.gz"
  tar -xzf "$tmp/tofu.tar.gz" -C "$tmp" tofu
  install -D "$tmp/tofu" "$HOME/.local/bin/tofu"
  rm -rf "$tmp"
fi

# LazyVim needs a recent Neovim; Debian 12 ships 0.7
echo "==> Checking neovim"
if have nvim; then
  nvim_version=$(nvim --version | head -1 | grep -Po 'v\K[0-9]+\.[0-9]+')
  if [[ "$(printf '%s\n0.10\n' "$nvim_version" | sort -V | head -1)" != "0.10" ]]; then
    echo "    WARNING: neovim $nvim_version is too old for LazyVim (needs >= 0.10)."
    echo "    Install a newer release from https://github.com/neovim/neovim/releases"
  else
    echo "    neovim $nvim_version ok"
  fi
else
  echo "    WARNING: neovim not found; install it from https://github.com/neovim/neovim/releases"
fi

cat <<'EOF'

Done. Notes:
  - bun/pnpm/lazygit/gitui/tofu install into $HOME; open a new shell (or
    `source ~/.zshrc`) to pick up their PATH/completions entries already wired
    up in this dotfiles repo.
  - ~/.local/bin is appended to PATH, so a system binary of the same name
    (e.g. /usr/bin/nvim) takes precedence over one installed there.
EOF
