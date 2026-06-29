# Headroom — LLM Token Optimizer Proxy for Claude Code

Headroom is a lightweight local proxy that sits between Claude Code and the Anthropic API. It optimises token usage through intelligent caching and context compression, reducing cost and latency without changing how you use Claude Code.

## Prerequisites

- Docker and Docker Compose v2
- Port 8787 free on the host (configurable via `.env`)
- Claude CLI installed on any machine that will use the proxy

## Ports

| Port | Purpose |
|------|---------|
| 8787 | Headroom proxy (bound to `127.0.0.1` by default) |

## Volumes

| Volume | Purpose |
|--------|---------|
| `headroom_data` | Proxy memory, session cache, and configuration |

## Setup

```bash
cp .env.example .env
```

Edit `.env` to match your environment:

| Variable | Default | Description |
|----------|---------|-------------|
| `HEADROOM_PORT` | `8787` | Host port the proxy listens on |
| `HEADROOM_BIND_HOST` | `127.0.0.1` | Network interface to bind — see [Network Modes](#network-modes) |
| `TZ` | `Asia/Kolkata` | Container timezone (IANA format) |
| `HEADROOM_CODE_AWARE_ENABLED` | `1` | `1` enables code-aware token optimisation, `0` disables it |

## Network Modes

| Mode | `HEADROOM_BIND_HOST` | Accessible from | Use when |
|------|----------------------|-----------------|----------|
| **Local** (default) | `127.0.0.1` | Same machine only | Running Claude Code on the same host as Docker |
| **Network** | `0.0.0.0` | Any machine on your LAN | Proxy on a dedicated server; clients on other machines |

> **SECURITY — Network mode:** Setting `HEADROOM_BIND_HOST=0.0.0.0` exposes port 8787 to every device on your network. Anyone who can reach that port can route API calls through your Anthropic account. Restrict access using a host firewall (e.g. `ufw allow from 192.168.1.0/24 to any port 8787`) and only use this on trusted networks.

## Start

`docker compose up -d` will build the image automatically on the first run. Subsequent starts reuse the built image.

```bash
docker compose up -d
```

## Stop & Cleanup

```bash
# Stop (proxy memory and cache preserved)
docker compose down

# Stop and remove all Headroom data
docker compose down -v
```

> **WARNING:** `docker compose down -v` permanently deletes all cached sessions and proxy memory stored in `headroom_data`.

## Using with Claude Code

To route a single Claude Code session through the proxy, set `ANTHROPIC_BASE_URL` before running:

```bash
# Local mode
ANTHROPIC_BASE_URL=http://127.0.0.1:8787 claude

# Network mode (proxy on another machine)
ANTHROPIC_BASE_URL=http://192.168.1.50:8787 claude
```

For a persistent, switchable setup see [Conditional Launch](#conditional-launch) below.

## Conditional Launch

> **NOTE:** Start the Headroom container (`docker compose up -d`) before using the `--headroom` / `-Headroom` flag. The proxy must be running for Claude Code to connect.

The scripts below wrap the `claude` command so you can switch between direct and proxied modes without editing any files. Both scripts read an optional `HEADROOM_PROXY_URL` environment variable, making it easy to point at a remote proxy without touching the script.

---

### Linux / macOS / WSL2

Add the following to `~/.bashrc` (bash) or `~/.zshrc` (zsh):

```bash
claude_launch() {
    local real_claude
    real_claude=$(command -v claude)

    if [[ -z "$real_claude" ]]; then
        echo "Error: could not locate the Claude CLI installation." >&2
        return 1
    fi

    local proxy_url="${HEADROOM_PROXY_URL:-http://127.0.0.1:8787}"

    if [[ "$1" == "--headroom" ]]; then
        shift
        echo "Launching Claude SECURELY (Behind Headroom Proxy at ${proxy_url})..."
        ANTHROPIC_BASE_URL="$proxy_url" "$real_claude" "$@"
    else
        echo "Launching Claude DIRECTLY (Bypassing Headroom)..."
        unset ANTHROPIC_BASE_URL
        "$real_claude" "$@"
    fi
}

alias claude=claude_launch
```

Then reload your shell:

```bash
source ~/.bashrc   # bash
source ~/.zshrc    # zsh
```

**Usage:**

```bash
# Launch Claude directly (no proxy)
claude

# Launch Claude behind Headroom (local — default)
claude --headroom

# Launch Claude behind Headroom on a remote machine
HEADROOM_PROXY_URL=http://192.168.1.50:8787 claude --headroom
```

> **WSL2 note:** Docker Desktop automatically forwards `127.0.0.1:8787` from the Windows host into the WSL2 VM. Use the same `http://127.0.0.1:8787` address regardless of whether you are running the script from WSL2 or Windows.

---

### Windows (PowerShell)

Add the following to your PowerShell profile. Open it with:

```powershell
notepad $PROFILE
```

```powershell
function Claude-Conditional-Launch {
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [switch]$Headroom
    )

    $realClaude = (Get-Command claude -CommandType Application -ErrorAction SilentlyContinue).Source

    if (-not $realClaude) {
        Write-Error "Could not locate the global Claude CLI installation."
        return
    }

    $proxyUrl = if ($env:HEADROOM_PROXY_URL) { $env:HEADROOM_PROXY_URL } else { "http://127.0.0.1:8787" }

    if ($Headroom) {
        Write-Host "Launching Claude SECURELY (Behind Headroom Proxy at $proxyUrl)..." -ForegroundColor Green
        $env:ANTHROPIC_BASE_URL = $proxyUrl
        Start-Process -FilePath $realClaude -ArgumentList $args -NoNewWindow -Wait
        Remove-Item env:ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue
    } else {
        Write-Host "Launching Claude DIRECTLY (Bypassing Headroom)..." -ForegroundColor Cyan
        Remove-Item env:ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue
        Start-Process -FilePath $realClaude -ArgumentList $args -NoNewWindow -Wait
    }
}

Set-Alias -Name claude -Value Claude-Conditional-Launch -Option AllScope -Force
```

Then reload your profile:

```powershell
. $PROFILE
```

**Usage:**

```powershell
# Launch Claude directly (no proxy)
claude

# Launch Claude behind Headroom (local — default)
claude -Headroom

# Launch Claude behind Headroom on a remote machine
$env:HEADROOM_PROXY_URL = "http://192.168.1.50:8787"
claude -Headroom
```

## Deploy with Portainer

1. In Portainer, go to **Stacks → Add stack**.
2. Choose **Repository** and point to this repo, or paste the contents of `docker-compose.yml` directly.
3. Add environment variables under the **Environment variables** section (equivalent to `.env`):
   - `HEADROOM_PORT` → `8787`
   - `HEADROOM_BIND_HOST` → `127.0.0.1` (or `0.0.0.0` for network mode)
   - `TZ` → your timezone
   - `HEADROOM_CODE_AWARE_ENABLED` → `1`
4. Click **Deploy the stack**.

> **Portainer note:** The stack uses `build: .`, so Portainer must have access to the `Dockerfile` via the repository option. Alternatively, publish the image to a registry and replace `build: .` with `image: <your-image>` before deploying.

## References

- [Headroom on PyPI](https://pypi.org/project/headroom-ai/)
- [Headroom documentation](https://headroom.ai/docs)
