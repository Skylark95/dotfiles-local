#!/usr/bin/env bash
#
# Installs software referenced by these dotfiles that isn't part of the
# dotbot symlink setup. Written for Debian (apt) on a Chromebook - the apt
# counterpart of the fedora branch's install-deps.sh. Safe to re-run: each
# step skips software that's already installed.
#
# Needs sudo for the apt-installed packages; the rest install into $HOME.
#
# Usage: ./install-deps.sh [--upgrade] [step...]
#   --upgrade   also reinstall the GitHub-release tools (nvim, lazygit, gitui,
#               tofu) when a newer release is available
#   step        run only these steps: apt fd bun pnpm lazygit gitui tofu nvim

set -euo pipefail

have() { command -v "$1" &>/dev/null; }

upgrade=false
steps=()
for arg in "$@"; do
  case "$arg" in
    --upgrade) upgrade=true ;;
    apt|fd|bun|pnpm|lazygit|gitui|tofu|nvim) steps+=("$arg") ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

# True if no steps were named, or this one was
want() { [[ ${#steps[@]} -eq 0 || " ${steps[*]} " == *" $1 "* ]]; }

case "$(uname -m)" in
  x86_64)  arch_amd=amd64 arch_gnu=x86_64 ;;
  aarch64) arch_amd=arm64 arch_gnu=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# True if apt knows a candidate version for the package
apt_has() { [[ -n "$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ && $2 != "(none)" {print $2}')" ]]; }

# True if $1 is an older version than $2
ver_lt() { [[ "$1" != "$2" && "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" == "$1" ]]; }

# Latest GitHub release tag without the leading v
latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*'
}

# Decide whether a GitHub-release tool needs (re)installing.
# usage: needs_install <command> <installed-version> <latest-version>
# Echoes the reason and returns 0 if so; returns 1 if it is already current.
needs_install() {
  local cmd=$1 installed=$2 latest=$3
  if ! have "$cmd"; then
    echo "    not installed; installing $latest"
  elif $upgrade && ver_lt "$installed" "$latest"; then
    echo "    $installed -> $latest"
  else
    echo "    already installed ($installed)"
    return 1
  fi
}

if want apt; then
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
fi

if want fd; then
  # Debian names the fd binary fdfind; expose it as fd
  echo "==> Linking fd"
  if have fd; then
    echo "    already installed"
  elif have fdfind; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
fi

if want bun; then
  echo "==> Installing bun"
  if have bun; then
    echo "    already installed"
  else
    curl -fsSL https://bun.sh/install | bash
  fi
fi

if want pnpm; then
  echo "==> Installing pnpm"
  if have pnpm; then
    echo "    already installed"
  else
    npm install -g pnpm
  fi
fi

if want lazygit; then
  echo "==> Installing lazygit"
  installed=$(have lazygit && lazygit --version | grep -Po 'version=\K[0-9.]+' | head -1 || echo 0)
  version=$(latest_tag jesseduffield/lazygit)
  if needs_install lazygit "$installed" "$version"; then
    tmp=$workdir/lazygit
    mkdir -p "$tmp"
    curl -fsSL -o "$tmp/lazygit.tar.gz" \
      "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch_gnu}.tar.gz"
    tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp"
    install -D "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  fi
fi

if want gitui; then
  echo "==> Installing gitui"
  installed=$(have gitui && gitui --version | grep -Po '[0-9]+\.[0-9]+\.[0-9]+' || echo 0)
  version=$(latest_tag gitui-org/gitui)
  if needs_install gitui "$installed" "$version"; then
    # Not packaged in Debian 12; install the release into ~/.local/bin
    case "$arch_gnu" in x86_64) gitui_arch=x86_64 ;; *) gitui_arch=aarch64 ;; esac
    tmp=$workdir/gitui
    mkdir -p "$tmp"
    curl -fsSL -o "$tmp/gitui.tar.gz" \
      "https://github.com/gitui-org/gitui/releases/download/v${version}/gitui-linux-${gitui_arch}.tar.gz"
    tar -xzf "$tmp/gitui.tar.gz" -C "$tmp"
    install -D "$tmp/gitui" "$HOME/.local/bin/gitui"
  fi
fi

if want tofu; then
  echo "==> Installing opentofu"
  installed=$(have tofu && tofu version | grep -Po '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo 0)
  version=$(latest_tag opentofu/opentofu)
  if needs_install tofu "$installed" "$version"; then
    # Not packaged in Debian; install the release into ~/.local/bin
    tmp=$workdir/tofu
    mkdir -p "$tmp"
    curl -fsSL -o "$tmp/tofu.tar.gz" \
      "https://github.com/opentofu/opentofu/releases/download/v${version}/tofu_${version}_linux_${arch_amd}.tar.gz"
    tar -xzf "$tmp/tofu.tar.gz" -C "$tmp"
    install -D "$tmp/tofu" "$HOME/.local/bin/tofu"
  fi
fi

if want nvim; then
  # LazyVim needs Neovim 0.11+; Debian 12 ships 0.7. Each release unpacks to
  # ~/.local/nvim-<version> and ~/.local/bin/nvim points at the active one, so
  # the previous version stays around for a rollback.
  echo "==> Installing neovim"
  min_nvim=0.11.0
  installed=$(have nvim && nvim --version | head -1 | grep -Po 'v\K[0-9]+\.[0-9]+\.[0-9]+' || echo 0)
  version=$(latest_tag neovim/neovim)
  install_nvim=false
  if [[ "$installed" != 0 ]] && ver_lt "$installed" "$min_nvim"; then
    # Always replace a Neovim that is too old for LazyVim, even without --upgrade
    echo "    neovim $installed is older than $min_nvim; installing $version"
    install_nvim=true
  elif needs_install nvim "$installed" "$version"; then
    install_nvim=true
  fi
  if $install_nvim; then
    tmp=$workdir/nvim
    mkdir -p "$tmp"
    curl -fsSL -o "$tmp/nvim.tar.gz" \
      "https://github.com/neovim/neovim/releases/download/v${version}/nvim-linux-${arch_gnu}.tar.gz"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    rm -rf "$HOME/.local/nvim-${version}"
    mv "$tmp/nvim-linux-${arch_gnu}" "$HOME/.local/nvim-${version}"
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$HOME/.local/nvim-${version}/bin/nvim" "$HOME/.local/bin/nvim"
    # Keep the active version and the one before it
    find "$HOME/.local" -maxdepth 1 -type d -name 'nvim-[0-9]*' -printf '%f\n' \
      | sort -V | head -n -2 | while read -r old; do rm -rf "${HOME:?}/.local/${old}"; done
  fi
  # ~/.local/bin has to come before /usr/bin on PATH for the new nvim to win
  resolved=$(PATH="$HOME/.local/bin:$PATH" command -v nvim || true)
  echo "    nvim resolves to ${resolved:-nothing} once ~/.local/bin is first on PATH"
fi

cat <<'EOF'

Done. Notes:
  - bun/pnpm/lazygit/gitui/tofu/nvim install into $HOME; open a new shell (or
    `source ~/.zshrc`) to pick up their PATH/completions entries already wired
    up in this dotfiles repo.
  - Run `./install-deps.sh --upgrade` to update the GitHub-release tools.
  - A system binary of the same name (e.g. /usr/bin/nvim) wins if /usr/bin
    comes before ~/.local/bin on PATH. Check with `command -v <tool>`.
EOF
