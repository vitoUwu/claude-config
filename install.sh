#!/usr/bin/env bash
# Claude Code environment bootstrap.
# Two ways to run:
#   1. Locally from a clone:      ./install.sh
#   2. One-liner, no clone:       curl -fsSL <RAW_URL>/install.sh | bash
#      (set REPO_URL below and push this repo first)
set -euo pipefail

# ---- fill this in after you push the repo to GitHub -------------------------
REPO_URL="${CLAUDE_CONFIG_REPO:-https://github.com/YOUR_USER/claude-config.git}"
# -----------------------------------------------------------------------------

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m warn:\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- 0. Locate the payload (bootstrap-clone if piped via curl) ---------------
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ ! -d "$SRC/claude" ]; then
  log "No local payload found — cloning $REPO_URL"
  TMP="$(mktemp -d)"
  git clone --depth 1 "$REPO_URL" "$TMP/claude-config"
  SRC="$TMP/claude-config"
fi

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  Darwin)               OS=macos   ;;
  *)                    OS=linux   ;;
esac
log "Detected OS: $OS"

# --- 1. Prerequisite tools ---------------------------------------------------
if [ "$OS" = windows ]; then
  if have winget; then
    for pkg in OpenJS.NodeJS Microsoft.PowerShell jqlang.jq; do
      log "winget install $pkg"
      winget install --accept-source-agreements --accept-package-agreements -e --id "$pkg" || warn "$pkg may already be installed"
    done
  else
    warn "winget not found — install Node.js, PowerShell 7 and jq manually"
  fi
  if have pwsh; then
    log "Installing BurntToast PowerShell module (for notification hooks)"
    pwsh -NoProfile -Command "if (-not (Get-Module -ListAvailable BurntToast)) { Install-Module BurntToast -Scope CurrentUser -Force }" || warn "BurntToast install failed"
  fi
else
  warn "Non-Windows target: the Notification/Stop/SessionEnd hooks use pwsh + BurntToast and will not fire. Install node & jq via your package manager."
fi

# Claude Code CLI
if ! have claude; then
  log "Installing Claude Code CLI"
  if [ "$OS" = windows ]; then
    pwsh -NoProfile -Command "irm https://claude.ai/install.ps1 | iex" || warn "Claude install failed — install manually"
  else
    curl -fsSL https://claude.ai/install.sh | bash || warn "Claude install failed — install manually"
  fi
fi

# --- 2. cship (statusline) + rtk (Rust Token Killer) via their installers -----
# cship — https://cship.dev/#install-curl
if have cship; then
  log "cship already installed"
elif [ "$OS" = windows ]; then
  have pwsh && { log "Installing cship (irm cship.dev/install.ps1)"; pwsh -NoProfile -Command "irm https://cship.dev/install.ps1 | iex" || warn "cship install failed"; } || warn "pwsh missing — install cship manually"
else
  log "Installing cship (curl cship.dev/install.sh)"
  curl -fsSL https://cship.dev/install.sh | bash || warn "cship install failed"
fi

# rtk — https://github.com/rtk-ai/rtk
if have rtk; then
  log "rtk already installed"
elif [ "$OS" = windows ]; then
  if have cargo; then
    log "Installing rtk (cargo install --git)"; cargo install --git https://github.com/rtk-ai/rtk || warn "rtk cargo install failed"
  else
    warn "rtk has no Windows curl installer and cargo is absent — download rtk-x86_64-pc-windows-msvc.zip from https://github.com/rtk-ai/rtk/releases and put rtk.exe in ~/.local/bin"
  fi
else
  log "Installing rtk (curl install.sh)"
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh || warn "rtk install failed"
fi
# Optional: 'rtk init -g' wires rtk's Bash-rewrite hook. Skipped — this repo's CLAUDE.md
# already documents manual 'rtk' prefixing. Run it yourself if you want the auto-hook.

# --- 3. Config files into ~/.claude ------------------------------------------
mkdir -p "$HOME/.claude"
cp "$SRC/claude/settings.json"         "$HOME/.claude/settings.json"
cp "$SRC/claude/CLAUDE.md"             "$HOME/.claude/CLAUDE.md"
cp "$SRC/claude/mcp.json"              "$HOME/.claude/.mcp.json"     # restore dot-name
cp "$SRC/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
cp -r "$SRC/claude/skills/."           "$HOME/.claude/skills/"
log "Copied settings, CLAUDE.md, .mcp.json, statusline + $(ls "$SRC/claude/skills" | wc -l) skills into ~/.claude"

# --- 4. Plugin marketplaces + enabled plugins --------------------------------
if have claude; then
  log "Registering plugin marketplaces"
  claude plugin marketplace add anthropics/claude-plugins-official || true
  claude plugin marketplace add Egonex-AI/Understand-Anything      || true
  # (thedotmack/claude-mem and JuliusBrussee/caveman are installed-but-disabled in settings.json; add if you want them)
  log "Installing enabled plugins"
  claude plugin install frontend-design@claude-plugins-official     || true
  claude plugin install understand-anything@understand-anything     || true
else
  warn "claude CLI unavailable — settings.json already lists the marketplaces/plugins; they install on first launch"
fi

log "Done. Run 'claude' then '/login' to authenticate. Restart your shell to pick up PATH changes."
