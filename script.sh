#!/usr/bin/env bash
set -e

echo "=== 🚀 Mise à jour du système ==="
sudo pacman -Syu --noconfirm

echo "=== 🧰 Installation des paquets de base ==="
sudo pacman -S --noconfirm git curl wget base-devel zsh fzf neovim python-pip gnome-tweaks gnome-shell-extensions chromium linux-firmware

echo -e "KEYMAP=fr\nFONT=Lat2-Terminus16" | sudo tee /etc/vconsole.conf >/dev/null

chromium https://extensions.gnome.org/extension/3843/just-perfection/ >/dev/null 2>&1 & disown

echo "=== PARAMS JUST PERFECTION => minimal et Dash Visibility décochée === \n"

echo "=== ⚙️ Installation de paru (AUR helper) ==="
if ! command -v paru &> /dev/null; then
  cd /tmp
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
  cd ~
else
  echo "Paru déjà installé ✅"
fi

echo "=== 💻 Installation des applis de dev et outils utiles ==="
paru -S --noconfirm \
  visual-studio-code-bin \
  zotero-bin \
  discord \
  mattermost-desktop-bin \
  ttf-jetbrains-mono \
  ttf-jetbrains-mono-nerd \
  bitwarden-bin \
  neofetch

echo "=== 🔐 Génération clé SSH GitHub ==="
if [ ! -f ~/.ssh/id_ed25519_github ]; then
  ssh-keygen -t ed25519 -C "thomas.landais9733@gmail.com" -f ~/.ssh/id_ed25519_github -N ""
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519_github
  echo ""
  echo "👉 Voici ta clé publique à copier sur GitHub :"
  cat ~/.ssh/id_ed25519_github.pub
  echo ""
else
  echo "Clé SSH déjà existante ✅"
fi

echo "=== 💥 Installation de Oh My Zsh ==="
rm -rf ~/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "=== 🎨 Installation de Powerlevel10k et des plugins ==="
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all

echo "=== 🧩 Création du fichier .zshrc ==="
cat > ~/.zshrc <<'EOF'
# Désactive le prompt instantané Powerlevel10k
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path vers Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Thème
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Historique
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Options utiles
setopt autocd
setopt correct
setopt share_history
setopt inc_append_history
setopt extended_glob
autoload -U compinit && compinit

# Aliases pratiques
alias ll='ls -lh'
alias la='ls -lha'
alias gs='git status'
alias gl='git pull'
alias gp='git push'
alias gc='git commit -m'
alias v='nvim'
alias ..='cd ..'
alias ...='cd ../..'

# Couleurs et complétion
autoload -U colors && colors
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

# --- Activation automatique d'un venv local ---
find_venv_dir() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.venv/bin/activate" ]; then
      echo "$dir/.venv"
      return
    fi
    dir=$(dirname "$dir")
  done
}

auto_activate_venv() {
  local venv_path
  venv_path=$(find_venv_dir)

  if [ -n "$venv_path" ] && [ "$VIRTUAL_ENV" != "$venv_path" ]; then
    [ -n "$VIRTUAL_ENV" ] && deactivate 2>/dev/null
    source "$venv_path/bin/activate"
    _venv_message="🔹 Activation auto du venv : $venv_path"
  fi

  if [ -z "$venv_path" ] && [ -n "$VIRTUAL_ENV" ]; then
    deactivate 2>/dev/null
    _venv_message="🔸 Désactivation du venv (hors projet)"
  fi
}

show_venv_message() {
  if [ -n "$_venv_message" ]; then
    echo "$_venv_message"
    unset _venv_message
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd auto_activate_venv
add-zsh-hook precmd show_venv_message
auto_activate_venv

# Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
EOF

echo "=== 🧠 Configuration de VS Code ==="
mkdir -p ~/.config/Code/User
cat > ~/.config/Code/User/settings.json <<'EOF'
{
  "editor.fontFamily": "'JetBrainsMono Nerd Font Mono', 'JetBrainsMono Nerd Font', 'monospace'",
  "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font', monospace",
  "terminal.integrated.shell.linux": "/usr/bin/zsh",
  "editor.fontLigatures": true,
  "workbench.startupEditor": "newUntitledFile",
  "workbench.colorTheme": "Default Dark Modern",
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1500,
  "editor.minimap.enabled": false
}
EOF

echo "=== 🐚 Passage à zsh comme shell par défaut ==="
chsh -s $(which zsh)

source ~/.zshrc

echo ""
echo "✅ Installation terminée !"
echo "🔑 Copie ta clé SSH affichée ci-dessus sur GitHub (Settings → SSH Keys → New Key)"
echo "🎨 Lance 'p10k configure' pour personnaliser ton prompt Powerlevel10k"
echo "🧰 Ouvre 'GNOME Tweaks' pour ajuster la police JetBrainsMono Nerd Font"
echo "🧠 VS Code, Discord, Zotero, Chromium et Mattermost sont prêts !"
echo "🚀 Redémarre le terminal pour profiter du setup complet."
