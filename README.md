# ccquota

Read your Claude Code subscription usage limits from the terminal.

```
Current session
1% used
Resets 4am (Europe/Lisbon)

Current week (all models)
88% used
Resets Feb 20 at 1pm (Europe/Lisbon)
Pace: 130%

Current week (Sonnet only)
63% used
Resets 9pm (Europe/Lisbon)
Pace: 95%

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
git clone https://github.com/dandaka/ccquota.git
cd ccquota
npm install -g .
```

## Usage

```bash
ccquota           # plain text output
ccquota --json    # JSON output
```

### Pace

Pace tells you whether you're on track to stay within your quota by the reset time.

- **100%** — using exactly the right amount for the time elapsed
- **>100%** — burning faster than sustainable (e.g. 130% = 30% over pace)
- **<100%** — well under the limit

Pace is shown for weekly and monthly windows. It's omitted for the current session (no fixed window start) and for extra pay-as-you-go usage.

### JSON output

```json
{
  "currentsession": { "percent": 1, "reset": "Resets 4am (Europe/Lisbon)" },
  "currentweekallmodels": {
    "percent": 88,
    "pace": 130,
    "reset": "Resets Feb 20 at 1pm (Europe/Lisbon)"
  },
  "currentweeksonnetonly": {
    "percent": 63,
    "pace": 95,
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
pct=$(ccquota --json | python3 -c "import sys,json; print(json.load(sys.stdin)['currentweekallmodels']['percent'])")
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
