#!/bin/sh
# claude-profile installer
#
#   curl -fsSL https://raw.githubusercontent.com/RayChang/claude-profile/main/install.sh | sh
#
# Installs claude-profile into ~/.local/bin and makes sure its dependencies exist:
#   - jq          (installed via Homebrew if missing)
#   - Claude Code (installed via the official installer if missing)
#
# Environment overrides:
#   CLAUDE_PROFILE_BIN=<dir>   install location (default: $HOME/.local/bin)
#   CLAUDE_PROFILE_REF=<ref>   git ref to install from (default: main)
set -eu

REPO="RayChang/claude-profile"
REF="${CLAUDE_PROFILE_REF:-main}"
BIN_DIR="${CLAUDE_PROFILE_BIN:-$HOME/.local/bin}"
RAW="https://raw.githubusercontent.com/$REPO/$REF"

say()  { printf '%s\n' "$*"; }
fail() { printf 'install: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[ "$(uname -s)" = "Darwin" ] || say "note: claude-profile is tested on macOS only; continuing anyway"
have curl || fail "curl is required"

# 1. jq — used to seed each profile's .claude.json
if ! have jq; then
  if have brew; then
    say "jq not found; installing with Homebrew..."
    brew install jq
  else
    fail "jq is required. Install Homebrew (https://brew.sh) and re-run, or install jq by hand."
  fi
fi

# 2. Claude Code itself
if ! have claude && [ ! -x "$HOME/.local/bin/claude" ]; then
  say "Claude Code not found; running the official installer..."
  curl -fsSL https://claude.ai/install.sh | bash
  [ -x "$HOME/.local/bin/claude" ] || have claude || \
    fail "Claude Code did not install; see https://code.claude.com/docs/en/setup"
fi

# 3. claude-profile
mkdir -p "$BIN_DIR"
tmp="$(mktemp)"
curl -fsSL "$RAW/claude-profile" -o "$tmp"
head -1 "$tmp" | grep -q '^#!/usr/bin/env bash' || fail "downloaded file does not look like claude-profile (bad CLAUDE_PROFILE_REF?)"
install -m 0755 "$tmp" "$BIN_DIR/claude-profile"
rm -f "$tmp"

# 4. Make sure the bin dir is on PATH for new shells (rc file chosen from $SHELL)
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    bin_disp="$(printf '%s' "$BIN_DIR" | sed "s|^$HOME|\$HOME|")"
    case "$(basename "${SHELL:-sh}")" in
      zsh)  rc="$HOME/.zshrc";              line="export PATH=\"$bin_disp:\$PATH\"" ;;
      bash) if [ "$(uname -s)" = "Darwin" ]; then rc="$HOME/.bash_profile"; else rc="$HOME/.bashrc"; fi
            line="export PATH=\"$bin_disp:\$PATH\"" ;;
      fish) rc="$HOME/.config/fish/config.fish"; line="set -gx PATH \"$bin_disp\" \$PATH" ;;
      *)    rc="$HOME/.profile";            line="export PATH=\"$bin_disp:\$PATH\"" ;;
    esac
    mkdir -p "$(dirname "$rc")"
    grep -qsF "$line" "$rc" || printf '\n# added by claude-profile installer\n%s\n' "$line" >> "$rc"
    say "added $bin_disp to PATH in $rc (open a new terminal to pick it up)"
    ;;
esac

say ""
say "claude-profile installed: $BIN_DIR/claude-profile"
say ""
say "Next steps:"
say "  claude-profile new work     # creates the profile, installs the 'claude-work' command, opens login"
say "  claude-work                 # 2nd account; plain 'claude' keeps the 1st"
say ""
say "More: claude-profile --help"
