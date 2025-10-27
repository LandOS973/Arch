typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path vers oh-my-zsh
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

# Source oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Historique
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Options utiles
setopt autocd              # Aller dans un dossier sans "cd"
setopt correct             # Corrige automatiquement les fautes de frappe
setopt share_history       # Partage l’historique entre sessions
setopt inc_append_history  # Sauvegarde l’historique en direct
setopt extended_glob       # Glob patterns avancés
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

# --- Auto-activation intelligente du venv local (.venv) ---
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

# Fonction appelée à chaque changement de dossier
auto_activate_venv() {
  local venv_path
  venv_path=$(find_venv_dir)

  # Si un venv est trouvé et non encore activé → activer
  if [ -n "$venv_path" ] && [ "$VIRTUAL_ENV" != "$venv_path" ]; then
    if [ -n "$VIRTUAL_ENV" ]; then
      deactivate 2>/dev/null
    fi
    source "$venv_path/bin/activate"
    # Message différé : on l'affichera au prochain prompt
    _venv_message="🔹 Activation automatique du venv trouvé : $venv_path"
  fi

  # Si aucun venv trouvé mais un est actif → désactiver
  if [ -z "$venv_path" ] && [ -n "$VIRTUAL_ENV" ]; then
    deactivate 2>/dev/null
    _venv_message="🔸 Désactivation du venv (hors projet)"
  fi
}

# Fonction exécutée avant chaque prompt → affiche le message si défini
show_venv_message() {
  if [ -n "$_venv_message" ]; then
    echo "$_venv_message"
    unset _venv_message
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd auto_activate_venv
autoload -U add-zsh-hook
add-zsh-hook precmd show_venv_message

# Activation au lancement du shell
auto_activate_venv

# Prompt Powerlevel10k (si configuré)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# FZF (si installé)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
