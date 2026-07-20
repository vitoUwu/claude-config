#!/usr/bin/env bash
# Claude Code environment bootstrap.
# Two ways to run:
#   1. Locally from a clone:  bash install.sh
#   2. One-liner, no clone:   curl -fsSL https://raw.githubusercontent.com/vitoUwu/claude-config/main/install.sh | bash
set -euo pipefail

# Override with CLAUDE_CONFIG_REPO if you fork this.
REPO_URL="${CLAUDE_CONFIG_REPO:-https://github.com/vitoUwu/claude-config.git}"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m warn:\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- 0. Locate the payload; if piped via curl, clone then re-exec from a FILE -
# Re-exec matters: under `curl | bash` the script lives on stdin, so any child
# that reads stdin (e.g. `npx skills`) would swallow the rest of the script and
# echo it. Re-exec from the cloned FILE with stdin detached (</dev/null) so the
# script runs to completion AND no child can read the leftover pipe.
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ ! -d "$SRC/claude" ]; then
  log "No local payload found — cloning $REPO_URL"
  TMP="$(mktemp -d)"
  git clone --depth 1 "$REPO_URL" "$TMP/claude-config"
  exec bash "$TMP/claude-config/install.sh" </dev/null
fi

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  Darwin)               OS=macos   ;;
  *)                    OS=linux   ;;
esac
log "Detected OS: $OS"

# --- 1. Prerequisite tools (Node, npm, jq, git, curl) ------------------------
if [ "$OS" = windows ]; then
  if have winget; then
    for pkg in OpenJS.NodeJS jqlang.jq Git.Git; do
      log "winget install $pkg"
      winget install --accept-source-agreements --accept-package-agreements -e --id "$pkg" || warn "$pkg may already be installed"
    done
  else
    warn "winget not found — install Node.js, jq and git manually"
  fi
else
  # Linux / macOS — install ONLY what's missing. (Requesting 'npm' alongside a
  # NodeSource 'nodejs' triggers apt's "npm conflicts with nodejs" breakage;
  # NodeSource/nvm Node already bundles npm/npx, so we never ask for npm.)
  SUDO=""; [ "$(id -u)" -ne 0 ] && have sudo && SUDO=sudo
  NEED=""
  have npx || have node || NEED="$NEED nodejs"
  have jq   || NEED="$NEED jq"
  have git  || NEED="$NEED git"
  have curl || NEED="$NEED curl"
  if [ -n "$NEED" ]; then
    if   have apt-get; then log "apt-get install$NEED"; $SUDO apt-get update -y && $SUDO apt-get install -y $NEED || warn "apt install failed"
    elif have dnf;     then log "dnf install$NEED";     $SUDO dnf install -y $NEED || warn "dnf install failed"
    elif have pacman;  then log "pacman -S$NEED";       $SUDO pacman -Sy --noconfirm $NEED || warn "pacman install failed"
    elif have zypper;  then log "zypper install$NEED";  $SUDO zypper install -y $NEED || warn "zypper install failed"
    elif have brew;    then log "brew install${NEED/nodejs/node}"; brew install ${NEED/nodejs/node} || warn "brew install failed"
    else warn "No known package manager — install node, jq, git, curl yourself"
    fi
  else
    log "Node, jq, git, curl already present — skipping package install"
  fi
  # Plain distro 'nodejs' may omit npm; NodeSource/nvm bundle it.
  have npx || warn "npx missing — install Node LTS (with npm) via NodeSource or nvm, then re-run"
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

# cship reads its config from ~/.config/cship.toml (not ~/.claude).
mkdir -p "$HOME/.config"
cp "$SRC/config/cship.toml" "$HOME/.config/cship.toml"
log "Copied cship.toml into ~/.config"

# --- 3. Config files into ~/.claude ------------------------------------------
mkdir -p "$HOME/.claude"
cp "$SRC/claude/settings.json"         "$HOME/.claude/settings.json"
cp "$SRC/claude/CLAUDE.md"             "$HOME/.claude/CLAUDE.md"
cp "$SRC/claude/mcp.json"              "$HOME/.claude/.mcp.json"     # restore dot-name
cp "$SRC/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
mkdir -p "$HOME/.claude/skills"
for skill in "$SRC"/claude/skills/*/; do
  dest="$HOME/.claude/skills/$(basename "$skill")"
  # Don't clobber a symlinked skill the user points elsewhere (e.g. ~/.agents/skills).
  if [ -L "$dest" ]; then warn "skipping symlinked skill: $(basename "$skill")"; continue; fi
  rm -rf "$dest" && cp -r "$skill" "$dest"
done
log "Copied settings, CLAUDE.md, .mcp.json, statusline + $(ls "$SRC/claude/skills" | wc -l) bespoke skills into ~/.claude"

# --- 4. Skills from cursor/plugins (installed via the skills CLI) ------------
# Needs Node/npx (installed in step 1). Docs: https://github.com/vercel-labs/skills
if have npx; then
  log "Installing cursor/plugins skills via npx skills"
  npx -y skills@latest add cursor/plugins --global --yes \
    --skill blast-radius \
    --skill fix-ci \
    --skill thermo-nuclear-code-quality-review \
    --skill thermo-nuclear-review </dev/null || warn "npx skills add failed — install them manually"

  # mattpocock/skills. Note: design-an-interface & qa are in the repo's deprecated/
  # folder upstream — they install today but may be removed; re-vendor if that happens.
  log "Installing mattpocock/skills"
  npx -y skills@latest add mattpocock/skills --global --yes \
    --skill grill-me \
    --skill grill-with-docs \
    --skill handoff \
    --skill improve-codebase-architecture \
    --skill design-an-interface \
    --skill qa </dev/null || warn "npx skills add (mattpocock) failed — install them manually"

  # squirrelscan/skills
  log "Installing squirrelscan/skills"
  npx -y skills@latest add squirrelscan/skills --global --yes \
    --skill audit-website </dev/null || warn "npx skills add (squirrelscan) failed — install it manually"

  # jakubkrehel/make-interfaces-feel-better
  log "Installing jakubkrehel/make-interfaces-feel-better"
  npx -y skills@latest add https://github.com/jakubkrehel/make-interfaces-feel-better --global --yes \
    --skill make-interfaces-feel-better </dev/null || warn "npx skills add (make-interfaces-feel-better) failed — install it manually"

  # emilkowalski/skill
  log "Installing emilkowalski/skill (emil-design-eng)"
  npx -y skills@latest add https://github.com/emilkowalski/skill --global --yes \
    --skill emil-design-eng </dev/null || warn "npx skills add (emil-design-eng) failed — install it manually"

  # raphaelsalaja/skill
  log "Installing raphaelsalaja/skill (12-principles-of-animation)"
  npx -y skills@latest add https://github.com/raphaelsalaja/skill --global --yes \
    --skill 12-principles-of-animation </dev/null || warn "npx skills add (12-principles-of-animation) failed — install it manually"

  # ibelick/ui-skills
  log "Installing ibelick/ui-skills (fixing-accessibility)"
  npx -y skills@latest add https://github.com/ibelick/ui-skills --global --yes \
    --skill fixing-accessibility </dev/null || warn "npx skills add (fixing-accessibility) failed — install it manually"

  # vercel-labs/agent-skills
  log "Installing vercel-labs/agent-skills (vercel-react-best-practices)"
  npx -y skills@latest add https://github.com/vercel-labs/agent-skills --global --yes \
    --skill vercel-react-best-practices </dev/null || warn "npx skills add (vercel-react-best-practices) failed — install it manually"

  # millionco/react-doctor
  log "Installing millionco/react-doctor (react-doctor)"
  npx -y skills@latest add https://github.com/millionco/react-doctor --global --yes \
    --skill react-doctor </dev/null || warn "npx skills add (react-doctor) failed — install it manually"
else
  warn "npx not found — skipping cursor/plugins + mattpocock skills"
fi

# --- 5. Plugin marketplaces + enabled plugins --------------------------------
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
