#!/usr/bin/env bash
# Detects default host port conflicts across all docker-compose templates.
# Usage: ./scripts/check-ports.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFLICTS=0

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }

declare -A PORT_OWNER

mapfile -t COMPOSE_FILES < <(find "$ROOT" -name "docker-compose.yml" -not -path "*/.git/*" | sort)

for COMPOSE in "${COMPOSE_FILES[@]}"; do
  LABEL="${COMPOSE#"$ROOT"/}"
  LABEL="${LABEL%/docker-compose.yml}"

  # Extract default port values from ${VAR:-PORT} patterns on host side of port mappings
  # Also capture bare port lines as fallback
  while IFS= read -r line; do
    # Match: - "${VAR:-8080}:..." or - "8080:..." — extract host port
    port=$(echo "$line" | grep -oE '\$\{[^}]+:-([0-9]+)\}:[0-9]+' | grep -oE ':-([0-9]+)' | tr -d ':-' | head -1)
    if [[ -z "$port" ]]; then
      port=$(echo "$line" | grep -oE '"?([0-9]+):[0-9]+"?' | cut -d: -f1 | tr -d '"' | head -1)
    fi
    [[ -z "$port" ]] && continue

    if [[ -n "${PORT_OWNER[$port]+_}" ]]; then
      red "[CONFLICT] Port $port: '${PORT_OWNER[$port]}' and '$LABEL' both use this default port"
      ((CONFLICTS++)) || true
    else
      PORT_OWNER[$port]="$LABEL"
    fi
  done < <(grep -E '^\s+-\s+"?\$?\{?' "$COMPOSE" | grep -E ':[0-9]+"?\s*$')
done

echo ""
if [[ $CONFLICTS -gt 0 ]]; then
  yellow "WARNING: $CONFLICTS default port conflict(s) found — see above."
  yellow "If intentional (e.g. mutually exclusive templates), document in README.md Port Reference."
  exit 0
else
  green "PASSED: no default port conflicts across ${#PORT_OWNER[@]} mapped ports"
  exit 0
fi
