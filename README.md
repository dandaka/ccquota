# cclimits

Read your Claude Code subscription usage limits from the terminal.

```
Current session
1% used
Resets 4am (Europe/Lisbon)

Current week (all models)
88% used
Resets Feb 20 at 1pm (Europe/Lisbon)

Current week (Sonnet only)
63% used
Resets 9pm (Europe/Lisbon)

Extra usage
100% used
$42.95 / $42.50 spent · Resets Mar 1 (Europe/Lisbon)
```

## Why

Claude Code has a built-in `/usage` command, but it only works interactively inside a session. There is no official CLI flag or API to read subscription quota data programmatically. This tool automates the interactive session using tmux and exposes the output as plain text or JSON.

## Requirements

### Supported platforms

| OS                    | Support                               |
| --------------------- | ------------------------------------- |
| macOS (Apple Silicon) | ✅ Fully supported                    |
| macOS (Intel)         | ✅ Fully supported                    |
| Linux                 | ✅ Should work (tmux must be in PATH) |
| Windows               | ❌ Not supported (no tmux)            |

### Prerequisites

**Claude Code** — must be installed, authenticated, and available as `claude` in your PATH.

```bash
# Verify
claude --version
```

If not installed, follow the [Claude Code setup guide](https://docs.anthropic.com/en/docs/claude-code/setup).

**tmux** — used to run Claude headlessly and capture its output.

```bash
# macOS
brew install tmux

# Ubuntu / Debian
sudo apt install tmux

# Fedora / RHEL
sudo dnf install tmux
```

**Claude Pro or Max subscription** — the `/usage` command is only available for paid plans.

## Install

```bash
npm install -g cclimits
```

Or run without installing:

```bash
npx cclimits
```

## Usage

```bash
cclimits           # plain text output
cclimits --json    # JSON output
```

### JSON output

```json
{
  "currentsession": { "percent": 1, "reset": "Resets 4am (Europe/Lisbon)" },
  "currentweekallmodels": {
    "percent": 88,
    "reset": "Resets Feb 20 at 1pm (Europe/Lisbon)"
  },
  "currentweeksonnetonly": {
    "percent": 63,
    "reset": "Resets 9pm (Europe/Lisbon)"
  },
  "extrausage": {
    "percent": 100,
    "reset": "$42.95 / $42.50 spent · Resets Mar 1 (Europe/Lisbon)"
  }
}
```

### Use in scripts

```bash
# Alert when weekly usage is above 90%
pct=$(cclimits --json | python3 -c "import sys,json; print(json.load(sys.stdin)['currentweekallmodels']['percent'])")
[ "$pct" -gt 90 ] && echo "Warning: weekly usage at ${pct}%"
```

## How it works

There is no official API for Claude Code subscription quota data. This tool:

1. Spawns a headless `claude` session inside a detached tmux pane
2. Waits for the prompt to appear, then sends `/usage` followed by Escape (to dismiss autocomplete) and Enter
3. Waits for the usage panel to render, captures the pane output
4. Strips progress bar characters and ANSI codes, returns clean text or JSON

## Limitations

- Adds ~5–10 seconds startup time (Claude Code initialization)
- Depends on Claude Code's TUI layout — may break if Anthropic changes the `/usage` output format
- Requires an active Claude Code subscription (Pro or Max)
- Windows is not supported

## License

MIT
