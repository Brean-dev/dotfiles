#!/usr/bin/env bash
set -euo pipefail

# ================== Config (override via env) ==================
REPO_HTTPS="${REPO_HTTPS:-https://github.com/Brean-dev/dotfiles.git}"               # e.g. https://github.com/USER/REPO.git
BRANCH="${BRANCH:-main}"
DOTDIR="${DOTDIR:-$HOME/.dotfiles}"
BACKUP_BASE="${BACKUP_BASE:-$HOME/.dotfiles_backup}"
NVIM_DEST="${NVIM_DEST:-$HOME/.config/nvim}"
POSH_DEST="${POSH_DEST:-$HOME/.config/oh-my-posh}"
TMUX_DIR_DEST="${TMUX_DIR_DEST:-$HOME/.tmux}"
TMUX_CONF_DEST="${TMUX_CONF_DEST:-$HOME/.tmux.conf}"
ZSH_FILE_DEST="${ZSH_FILE_DEST:-$HOME/.zshrc}"
ZSH_DIR_DEST="${ZSH_DIR_DEST:-$HOME/.config/zshrc}"   # moved into XDG config directory
OHMYZSH_DEST="${OHMYZSH_DEST:-$HOME/.oh-my-zsh}"

# ================== Helpers ==================
log()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!! \033[0m%s\n" "$*"; }
die()  { printf "\033[1;31mXX \033[0m%s\n" "$*"; exit 1; }
need() { command -v "$1" >/dev/null 2>&1; }


pm_install() {
  if need apt; then
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y build-essential pkg-config cmake ninja-build gdb lldb make autoconf automake libtool clang llvm libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev libncurses5-dev libncursesw5-dev git mercurial subversion curl wget unzip zip tar rsync jq ripgrep fd-find tree htop net-tools gnupg ca-certificates zsh tmux yq
    # Fastfetch is not in apt, install from GitHub
    if ! need fastfetch; then
      log "Installing fastfetch from GitHub releases"
      ff_url=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep "browser_download_url.*linux-amd64.deb" | cut -d '"' -f4)
      if [ -n "$ff_url" ]; then
        wget -O /tmp/fastfetch.deb "$ff_url"
        sudo dpkg -i /tmp/fastfetch.deb || sudo apt -f install -y
        rm /tmp/fastfetch.deb
      else
        warn "Could not find fastfetch .deb release for linux-amd64"
      fi
    fi
    # Install fzf via git clone (not apt)
    if ! need fzf; then
      log "Installing fzf via git clone"
      git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
      ~/.fzf/install --all
    fi

  elif need dnf; then
    log "Using dnf to install development packages"
    # Install Development Tools group then useful libraries/tools
    sudo dnf5 group install "c-development"
    sudo dnf install -y pkgconfig cmake ninja-build gdb lldb autoconf automake libtool clang llvm openssl-devel zlib-devel bzip2-devel readline-devel sqlite-devel libffi-devel xz-devel ncurses-devel git mercurial subversion curl wget unzip zip tar rsync jq ripgrep fd-find tree htop net-tools gnupg2 ca-certificates zsh tmux yq

    # fzf & fastfetch handled later (fastfetch fallback handled for apt only above)

  elif need pacman; then
    log "Using pacman to install development packages"
    sudo pacman -Sy --noconfirm --needed base-devel pkgconf cmake ninja gdb lldb autoconf automake libtool clang llvm openssl zlib bzip2 readline sqlite libffi xz ncurses git mercurial subversion curl wget unzip zip tar rsync jq ripgrep fd tree htop net-tools gnupg ca-certificates zsh tmux yq

  elif need zypper; then
    log "Using zypper to install development packages"
    # Install common development pattern + libraries/tools
    sudo zypper install -y -t pattern devel_C_C++
    sudo zypper install -y gcc gcc-c++ make pkg-config cmake ninja gdb lldb autoconf automake libtool clang llvm libopenssl-devel zlib-devel bzip2-devel readline-devel sqlite3-devel libffi-devel xz-devel ncurses-devel git mercurial subversion curl wget unzip zip tar rsync jq ripgrep fd-find tree htop net-tools gpg2 ca-certificates zsh tmux yq

  elif need apk; then
    log "Using apk to install development packages"
    sudo apk add --no-cache build-base pkgconfig cmake ninja gdb autoconf automake libtool clang llvm openssl-dev zlib-dev bzip2-dev readline-dev sqlite-dev libffi-dev xz-dev ncurses-dev git mercurial subversion curl wget unzip zip tar rsync jq ripgrep fd tree htop net-tools gnupg ca-certificates zsh tmux yq

  else
    warn "Unknown package manager; please install git curl unzip zsh tmux neovim and development libs manually."
  fi
}


install_oh_my_posh() {
  if need oh-my-posh; then return; fi
  log "Installing oh-my-posh to /usr/local/bin"
  curl -fsSL https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin
}

install_oh_my_zsh() {
  # Only install if ~/.oh-my-zsh isn't already provided by repo or present.
  if [ -d "$OHMYZSH_DEST" ]; then
    log "oh-my-zsh already present at $OHMYZSH_DEST"
    return
  fi
  log "Installing oh-my-zsh (non-interactive; KEEP_ZSHRC, no chsh, no auto-run)"
  RUNZSH=no CHSH=${CHSH:-no} KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

mkxdg() {
  mkdir -p "$HOME/.config" "$BACKUP_DIR"
}

backup_path() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    local rel="${target#"$HOME/"}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$target" "$BACKUP_DIR/$rel"
    log "Backed up $target → $BACKUP_DIR/$rel"
  fi
}

link_dir() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  backup_path "$dest"
  if ln -snf "$src" "$dest"; then
    log "Linked dir  $src → $dest"
  else
    die "Failed to link $src → $dest"
  fi
}

link_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  backup_path "$dest"
  ln -snf "$src" "$dest"
  log "Linked file $src → $dest"
}

# ================== Fetch repo ==================
clone_or_update() {
  if [ -d "$DOTDIR/.git" ]; then
    log "Updating repo in $DOTDIR"
    git -C "$DOTDIR" fetch --all --prune
    git -C "$DOTDIR" checkout "$BRANCH" || true
    git -C "$DOTDIR" pull --ff-only || true
    return
  fi

  [ -n "$REPO_HTTPS" ] || die "REPO_HTTPS is empty. Set REPO_HTTPS=https://github.com/USER/REPO.git"
  log "Cloning $REPO_HTTPS → $DOTDIR (branch: $BRANCH)"
  git clone --depth=1 --branch "$BRANCH" "$REPO_HTTPS" "$DOTDIR"
}


# ================== Placement logic ==================
place_dotfiles() {
  # nvim/
  if [ -d "$DOTDIR/nvim" ]; then
    link_dir "$DOTDIR/nvim" "$NVIM_DEST"
  fi

  # oh-my-posh/
  if [ -d "$DOTDIR/oh-my-posh" ]; then
    link_dir "$DOTDIR/oh-my-posh" "$POSH_DEST"
  fi

  # oh-my-zsh/ or .oh-my-zsh/ from repo → ~/.oh-my-zsh
  if [ -d "$DOTDIR/oh-my-zsh" ] || [ -d "$DOTDIR/.oh-my-zsh" ]; then
    local zsrc="$DOTDIR/oh-my-zsh"
    [ -d "$DOTDIR/.oh-my-zsh" ] && zsrc="$DOTDIR/.oh-my-zsh"
    link_dir "$zsrc" "$OHMYZSH_DEST"
  fi

  # tmux/ (optional) and tmux.conf
  if [ -d "$DOTDIR/tmux" ]; then
    link_dir "$DOTDIR/tmux" "$TMUX_DIR_DEST"
  fi
  if [ -f "$DOTDIR/tmux.conf" ]; then
    link_file "$DOTDIR/tmux.conf" "$TMUX_CONF_DEST"
  fi
  if [ -d "$DOTDIR/zshrc" ]; then
    link_dir "$DOTDIR/zshrc" "$HOME/.config/zshrc"
    log "Linked dir  $DOTDIR/zshrc → $HOME/.config/zshrc"
  fi


 if [ -f "$DOTDIR/.zshrc" ]; then
    link_file "$DOTDIR/.zshrc" "$ZSH_FILE_DEST"
        log "Created loader $ZSH_FILE_DEST → sources $ZSH_DIR_DEST/*.zsh"
      else
        warn "$ZSH_FILE_DEST exists; not overwriting with loader."
 fi
}


install_ohmyzsh_plugins() {
  log "Ensuring oh-my-zsh plugins exist"

  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  mkdir -p "$custom/plugins"

  # Map of plugin_name → git_url
  declare -A plugins=(
    [fzf-zsh-plugin]="https://github.com/unixorn/fzf-zsh-plugin.git"
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    [fast-syntax-highlighting]="https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
    [zsh-fzf-history-search]="https://github.com/joshskidmore/zsh-fzf-history-search.git"
  )

  for name in "${!plugins[@]}"; do
    local dest="$custom/plugins/$name"
    if [ -d "$dest" ]; then
      log "[oh-my-zsh] plugin '$name' already installed"
    else
      log "[oh-my-zsh] installing plugin '$name'"
      git clone --depth=1 "${plugins[$name]}" "$dest"
    fi
  done
}

change_shell_to_zsh() {
  local current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  local zsh_path="$(command -v zsh)"
  
  if [ "$current_shell" = "$zsh_path" ]; then
    log "Shell is already zsh"
    return
  fi
  
  if [ -z "$zsh_path" ]; then
    warn "zsh not found in PATH, cannot change shell"
    return
  fi
  
  log "Changing default shell from $current_shell to $zsh_path"
  if ! grep -q "^$zsh_path$" /etc/shells; then
    log "Adding $zsh_path to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells
  fi
  
  chsh -s "$zsh_path"

  exec zsh
  log "Shell changed to zsh. Please log out and back in for the change to take effect."
}

install_rust() {
  if need rustc; then
    log "Rust is already installed"
    # Install zoxide & eza if rust is present
    install_cargo_tools
    return
  fi
  
  log "Installing Rust via rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  
  # Source the cargo environment
  if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
  fi
  
  log "Rust installed successfully"
  install_cargo_tools
}

install_cargo_tools() {
  if need zoxide; then
    log "zoxide is already installed"
  else
    log "Installing zoxide via cargo"
    cargo install zoxide
  fi

  if need eza; then
    log "eza is already installed"
  else
    log "Installing eza via cargo"
    cargo install eza
  fi
}

install_go() {
  if need go; then
    log "Go is already installed"
    return
  fi

  log "Installing Go from official binaries"

  # Get the latest Go version
  local go_version
  go_version=$(curl -s https://go.dev/VERSION?m=text | grep -m1 '^go[0-9]')

  if [ -z "$go_version" ]; then
    warn "Could not fetch latest Go version, using fallback"
    go_version="go1.21.5"
  fi

  local go_archive="${go_version}.linux-amd64.tar.gz"
  local download_url="https://go.dev/dl/${go_archive}"

  log "Downloading Go ${go_version}"
  wget -O "/tmp/${go_archive}" "$download_url"

  log "Installing Go to /usr/local"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "/tmp/${go_archive}"

  # Clean up
  rm "/tmp/${go_archive}"

  # Add Go to PATH if not already present
  if ! echo "$PATH" | grep -q "/usr/local/go/bin"; then
    log "Adding Go to PATH in current session"
    export PATH=$PATH:/usr/local/go/bin
  fi

  log "Go installed successfully"
}


# ================== Main ==================
main() {
  BACKUP_DIR="$BACKUP_BASE/$(date +%Y%m%d-%H%M%S)"
  log "Distro detection & dependency install"
  pm_install

  log "Prepare directories"
  mkxdg

  log "Fetch dotfiles"
  clone_or_update

  log "Place symlinks"
  place_dotfiles

  # If repo didn’t provide ~/.oh-my-zsh, install it via official script.
  if [ ! -d "$OHMYZSH_DEST" ]; then
    install_oh_my_zsh
  else
    log "Skipping oh-my-zsh installer (repo-synced)"
  fi

  # oh-my-posh binary (independent of zsh)
  install_oh_my_posh

  install_ohmyzsh_plugins

  # Install Rust and Go
  install_rust
  install_go

  # Change default shell to zsh
  change_shell_to_zsh

  log "Done."
  log "Update later: (cd $DOTDIR && git pull --ff-only)"
}
main "$@"
