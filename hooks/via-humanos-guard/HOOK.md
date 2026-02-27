---
name: via-humanos-guard
description: "Intercepts tool calls and blocks unauthorized actions that lack a valid VIA Humanos mandate. Enforces compliance automatically."
homepage: https://github.com/Humanos-App/via-humanos
metadata:
  openclaw:
    emoji: "shield"
    events:
      - "tool.pre"
    requires:
      env:
        - VIA_API_KEY
        - VIA_API_URL
        - VIA_SIGNATURE_SECRET
      bins:
        - curl
        - jq
    os:
      - darwin
      - linux
---

# VIA Humanos Guard Hook

Automatically enforces human authorization mandates before tool execution. Instead of relying on the agent to "remember" to check mandates, this hook intercepts every tool call and blocks unauthorized actions.

## What It Does

1. Listens for `tool.pre` events (before any tool executes)
2. Checks if the tool call matches a protected pattern (configurable)
3. Calls the VIA Protocol API to verify a valid mandate exists
4. If no valid mandate: blocks execution and notifies the user
5. If valid mandate: allows execution to proceed

## Configuration

In `~/.openclaw/openclaw.json`:

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "via-humanos-guard": {
          "enabled": true,
          "env": {
            "VIA_API_KEY": "your-api-key",
            "VIA_API_URL": "https://api.humanos.com",
            "VIA_SIGNATURE_SECRET": "your-secret"
          }
        }
      }
    }
  }
}
```

### Protected Tool Patterns

Set `VIA_PROTECTED_TOOLS` to a comma-separated list of tool name patterns that require mandates. Defaults to common sensitive operations if not set.

```json
{
  "env": {
    "VIA_PROTECTED_TOOLS": "bash:curl.*payment,bash:curl.*transfer,bash:curl.*sign"
  }
}
```

## Requirements

- `curl` and `jq` on PATH
- VIA Protocol API credentials (VIA_API_KEY, VIA_API_URL, VIA_SIGNATURE_SECRET)

## Installation

```bash
cp -r hooks/via-humanos-guard/ ~/.openclaw/hooks/via-humanos-guard
openclaw hooks enable via-humanos-guard
```
