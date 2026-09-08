# claude-profile

Run [Claude Code](https://code.claude.com) under several Anthropic accounts on one Mac,
at the same time. One terminal on your personal account, another on your work account,
each with its own login, sessions and plugins, all sharing your `CLAUDE.md`, rules and skills.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/RayChang/claude-profile/main/install.sh | sh
```

The installer puts `claude-profile` in `~/.local/bin`, installs `jq` (Homebrew) and
Claude Code (official installer) if they are missing, and adds `~/.local/bin` to your PATH.

## Quick start

```sh
claude-profile new work          # creates ~/.claude-work, installs the claude-work command, opens the browser login

claude-work                      # second account
claude                           # first account, unchanged — run both side by side
claude-profile status            # who is logged in where
```

`new` drops an executable `claude-<name>` next to `claude-profile` (in `~/.local/bin`), so it
works in zsh, bash, fish or anything else with no shell-config edits.
Add as many profiles as you like with `claude-profile new <name>`.

## Commands

| Command | What it does |
|---|---|
| `new <name> [--no-login]` | Create `~/.claude-<name>`, seed it from `~/.claude`, then run the login flow |
| `login <name>` | Run `claude auth login` for that profile |
| `run <name> [args]` | Launch `claude` under the profile (checks links, syncs settings, passes args through) |
| `sync [--force] <name>` | Copy `~/.claude/settings.json` into the profile if the profile's copy is unmodified |
| `relink <name>` | Re-create the shared symlinks |
| `launcher <name>` | (Re)create the `claude-<name>` command |
| `status` | List profiles with account email and Keychain entry |

## How it works

Claude Code reads `CLAUDE_CONFIG_DIR` to decide where its config lives. When it is set,
Claude Code also keys its macOS Keychain entry to that directory
(`Claude Code-credentials-<sha256(dir)[0:8]>`), so each profile is a fully separate login.
`claude-profile run` just exports that variable and `exec`s `claude`; child processes
(subagents, hooks) inherit it and stay on the same account.

What a profile contains:

| Path in `~/.claude-<name>` | Kind | Why |
|---|---|---|
| `CLAUDE.md`, `RTK.md`, `rules/`, `output-styles/`, `skills/`, `commands/`, `agents/` | symlink → `~/.claude` | Read-only; edit once, applies everywhere |
| `settings.json` | copy, kept in sync | Claude Code rewrites it and refuses to write through symlinks |
| `.claude.json` | seeded (MCP servers + onboarding flags only) | Holds the account; must be separate |
| `projects/*/memory/` | copied once | Auto-memory starting point; diverges afterwards |
| `plugins/`, sessions, history | created by Claude Code | Per profile |

`sync` keeps a snapshot (`.settings.synced`) of the last copy. If the profile's
`settings.json` still matches the snapshot, it is refreshed from `~/.claude`; if you edited it
inside the profile, `sync` leaves it alone and tells you to use `--force`.

Hooks and status-line commands referenced by absolute paths in `settings.json` keep working
from any profile. Plugins listed in `enabledPlugins` are installed again on the profile's first
launch (expect a one-time download).

## Show the active profile in the status line

If you use a custom `statusLine` script, `CLAUDE_CONFIG_DIR` is set in its environment, so:

```bash
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
  profile="${CLAUDE_CONFIG_DIR##*/}"; profile="${profile#.claude-}"
  # render "$profile" wherever you like
fi
```

## Remove a profile

```sh
claude-profile run work auth logout     # clears the Keychain entry
rm -rf ~/.claude-work ~/.local/bin/claude-work
```

## Uninstall

```sh
rm ~/.local/bin/claude-profile ~/.local/bin/claude-<name>   # the script and each launcher it created
```

## Requirements

macOS, Claude Code 2.1+, `jq`, `curl`. Verified against Claude Code 2.1.263.
Linux should work (credentials go to `.credentials.json` inside the profile) but is untested.

## License

MIT
