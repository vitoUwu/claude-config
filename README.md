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
| `claude/skills/` | `~/.claude/skills/` | 4 bespoke skills |

**Skills (14 total):**
- **4 bespoke** — vendored in `claude/skills/`: audit-website, diagnose, prd, review.
- **4 from `cursor/plugins`** — installed via the [skills CLI](https://github.com/vercel-labs/skills):
  blast-radius, fix-ci, thermo-nuclear-code-quality-review, thermo-nuclear-review.
- **6 from `mattpocock/skills`** — installed via the skills CLI: grill-me, grill-with-docs, handoff,
  improve-codebase-architecture, design-an-interface, qa. (The last two are in mattpocock's
  `deprecated/` folder — installable today but may be removed upstream; re-vendor if that happens.)

Prerequisite tools the script installs: **Claude Code CLI, Node.js, PowerShell 7, jq, BurntToast**,
plus **cship** (statusline, via <https://cship.dev>) and **rtk** (Rust Token Killer, via
<https://github.com/rtk-ai/rtk>) from their official installers.
Plugin marketplaces it registers: `claude-plugins-official`, `understand-anything`
(enables `frontend-design` + `understand-anything`). Skills from `cursor/plugins` and
`mattpocock/skills` are pulled with `npx skills@latest add`.

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
- **Windows-focused.** The hooks call `pwsh` + BurntToast (Windows toasts). On Linux/macOS the
  script warns and skips them; everything else still installs.
- **rtk on Windows** has no curl installer — the script uses `cargo install` if cargo is present,
  otherwise it points you to the release zip. cship installs via `irm cship.dev/install.ps1`.
- `claude.png` referenced by the hooks doesn't exist on the source machine — BurntToast tolerates
  the missing logo. Drop a `claude.png` into `~/.claude/` if you want an icon.
- `claude-mem` and `caveman` marketplaces are omitted (they're installed-but-disabled on the source
  machine); uncomment in `install.sh` if wanted.
- Credentials are **not** included — you log in fresh on each machine.
