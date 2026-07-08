# claude-config

My Claude Code environment — settings, global instructions, custom skills, and the
two vendored binaries it depends on. `install.sh` puts everything in place and installs
the prerequisite tooling.

## What's in here

| Path | Goes to | Purpose |
|------|---------|---------|
| `claude/settings.json` | `~/.claude/settings.json` | model (`opus[1m]`), `effortLevel: high`, `auto` permission mode, notification hooks, enabled plugins |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | global instructions (RTK usage + Karpathy guidelines) |
| `claude/mcp.json` | `~/.claude/.mcp.json` | chrome-devtools MCP server (disabled by default) |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | fallback statusline script |
| `claude/skills/` | `~/.claude/skills/` | 3 bespoke skills |

**Skills (14 total):**
- **3 bespoke** — vendored in `claude/skills/`: diagnose, prd, review.
- **4 from `cursor/plugins`** — installed via the [skills CLI](https://github.com/vercel-labs/skills):
  blast-radius, fix-ci, thermo-nuclear-code-quality-review, thermo-nuclear-review.
- **6 from `mattpocock/skills`** — installed via the skills CLI: grill-me, grill-with-docs, handoff,
  improve-codebase-architecture, design-an-interface, qa. (The last two are in mattpocock's
  `deprecated/` folder — installable today but may be removed upstream; re-vendor if that happens.)
- **1 from `squirrelscan/skills`** — installed via the skills CLI: audit-website.

Prerequisite tools the script installs: **Claude Code CLI, Node.js/npm, jq, git**, plus
**cship** (statusline, via <https://cship.dev>) and **rtk** (Rust Token Killer, via
<https://github.com/rtk-ai/rtk>) from their official installers.
Plugin marketplaces it registers: `claude-plugins-official`, `understand-anything`
(enables `frontend-design` + `understand-anything`). Skills from `cursor/plugins`,
`mattpocock/skills` and `squirrelscan/skills` are pulled with `npx skills@latest add`.

## Run it

**From a clone:**
```bash
git clone https://github.com/vitoUwu/claude-config.git
cd claude-config
bash install.sh
```

**One command, no clone:**
```bash
curl -fsSL https://raw.githubusercontent.com/vitoUwu/claude-config/main/install.sh | bash
```
Run via curl, the script clones itself into a temp dir to fetch the payload (config + vendored skills).

After it finishes: **restart your shell** (PATH change), run `claude`, then `/login`.

## Notes / caveats
- **Linux/macOS:** installs Node/jq/git via the system package manager (apt/dnf/pacman/zypper/brew),
  and **strips the `pwsh` + BurntToast notification hooks** from `settings.json` (they're Windows
  desktop toasts and would error otherwise). Everything else installs normally.
- **Windows:** the hooks stay; PowerShell 7 + BurntToast are *not* auto-installed — install them
  yourself if you want the toast notifications, or the hooks just no-op.
- If `npx skills@latest` errors, your distro's Node is too old — install Node LTS via NodeSource or
  nvm and re-run.
- `claude-mem` and `caveman` marketplaces are omitted (installed-but-disabled on the source machine);
  uncomment in `install.sh` if wanted.
- Credentials are **not** included — you log in fresh on each machine.
