#!/usr/bin/env bash
# Validates each docker-compose template directory against repo conventions.
# Usage: ./scripts/validate.sh [dir1 dir2 ...]  (defaults to all template dirs)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }

fail() { red "[FAIL] $1"; ((ERRORS++)) || true; }
warn() { yellow "[WARN] $1"; ((WARNINGS++)) || true; }
pass() { green "[PASS] $1"; }

# Discover template dirs (any dir containing docker-compose.yml)
if [[ $# -gt 0 ]]; then
  TEMPLATE_DIRS=("$@")
else
  mapfile -t TEMPLATE_DIRS < <(find "$ROOT" -name "docker-compose.yml" -not -path "*/.git/*" -exec dirname {} \; | sort)
fi

# Read README image version table into memory for drift check
README="$ROOT/README.md"

check_readme_version() {
  local dir="$1"
  local image="$2"
  # Extract just the tag portion (after last colon)
  local tag="${image##*:}"
  # Check if the README table contains this image string
  if ! grep -qF "$image" "$README" 2>/dev/null; then
    fail "$dir: README.md templates table does not contain image version '$image' — update the Image Version column"
  fi
}

for DIR in "${TEMPLATE_DIRS[@]}"; do
  COMPOSE="$DIR/docker-compose.yml"
  LABEL="${DIR#"$ROOT"/}"

  echo ""
  echo "── $LABEL ──"

  # 1. Required files
  for f in docker-compose.yml README.md .env.example; do
    if [[ ! -f "$DIR/$f" ]]; then
      fail "$LABEL: missing required file '$f'"
    fi
  done

  [[ ! -f "$COMPOSE" ]] && continue

  # 2. Folder name is lowercase-hyphenated (leaf dir)
  LEAF="$(basename "$DIR")"
  if ! echo "$LEAF" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
    fail "$LABEL: folder name '$LEAF' must be lowercase-hyphenated (a-z, 0-9, hyphens only)"
  else
    pass "$LABEL: folder name OK"
  fi

  # 3. name: field at top of compose file
  if ! grep -qE '^name:' "$COMPOSE"; then
    fail "$LABEL: docker-compose.yml missing top-level 'name:' field"
  else
    pass "$LABEL: 'name:' field present"
  fi

  # 4. All host ports use ${VAR:-default} — no bare integer port mappings
  # Match lines like: - "8080:8080" or - 8080:8080 (not containing ${)
  if grep -E '^\s*-\s+"?[0-9]+:[0-9]+"?\s*$' "$COMPOSE" | grep -qv '\${'; then
    fail "$LABEL: hardcoded host port found — wrap in \${VAR:-default} syntax"
  else
    pass "$LABEL: host ports use env-var syntax"
  fi

  # 5. No hardcoded secrets (literal values after password:/secret:/token: not using ${)
  if grep -iE '^\s+(password|secret|token):\s+[^$"{][^\s]' "$COMPOSE" | grep -qv '#'; then
    fail "$LABEL: possible hardcoded secret — use \${VAR} references instead"
  else
    pass "$LABEL: no hardcoded secrets detected"
  fi

  # 6. No hardcoded non-loopback IPs
  if grep -vE '^\s*#' "$COMPOSE" | grep -qE '\b(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)[0-9]+\.[0-9]+\b'; then
    fail "$LABEL: hardcoded private IP found — use \${VARIABLE} or hostname instead"
  else
    pass "$LABEL: no hardcoded IPs"
  fi

  # 7. No hardcoded absolute host bind-mount paths (except /var/run/docker.sock)
  if grep -E '^\s+-\s+/(home|root|tmp|opt|srv|mnt|data)/' "$COMPOSE" | grep -qv '\${'; then
    fail "$LABEL: hardcoded absolute host path in volume mount — use named volumes or \${VAR}"
  else
    pass "$LABEL: no hardcoded host paths"
  fi

  # 8. restart: unless-stopped (not always)
  if grep -qE '^\s+restart:\s+always' "$COMPOSE"; then
    fail "$LABEL: use 'restart: unless-stopped' instead of 'restart: always'"
  else
    pass "$LABEL: restart policy OK"
  fi

  # 9. NPM opt-in comment block (warning only)
  if ! grep -q 'Nginx Proxy Manager' "$COMPOSE"; then
    warn "$LABEL: NPM opt-in comment block missing (add if service can be reverse-proxied)"
  else
    pass "$LABEL: NPM opt-in block present"
  fi

  # 10. Docker socket mount has WARNING comment
  if grep -q '/var/run/docker.sock' "$COMPOSE"; then
    # Check for a WARNING comment within 3 lines above the socket mount
    if ! grep -B3 '/var/run/docker.sock' "$COMPOSE" | grep -qi 'warning\|warn\|caution\|note'; then
      fail "$LABEL: Docker socket mount present but no '# WARNING:' comment above it"
    else
      pass "$LABEL: Docker socket WARNING comment present"
    fi
  fi

  # 11. privileged: true has WARNING comment
  if grep -qE '^\s+privileged:\s+true' "$COMPOSE"; then
    if ! grep -B3 'privileged: true' "$COMPOSE" | grep -qi 'warning\|warn\|caution\|note'; then
      fail "$LABEL: 'privileged: true' present but no '# WARNING:' comment above it"
    else
      pass "$LABEL: privileged WARNING comment present"
    fi
  fi

  # 12. README contains all 11 required section headings
  README_FILE="$DIR/README.md"
  if [[ -f "$README_FILE" ]]; then
    REQUIRED_SECTIONS=("Prerequisites" "Ports" "Volumes" "Setup" "Start" "Stop" "Portainer" "Docker Desktop" "Nginx Proxy Manager" "References")
    for section in "${REQUIRED_SECTIONS[@]}"; do
      if ! grep -qi "## .*$section\|### .*$section" "$README_FILE"; then
        warn "$LABEL: README.md may be missing section '$section'"
      fi
    done
    pass "$LABEL: README sections checked"
  fi

  # 13. .env.example vars match ${VAR} references in docker-compose.yml
  if [[ -f "$DIR/.env.example" ]]; then
    # Extract var names from compose file: ${VAR} and ${VAR:-default}
    # Match only up to the var name (stop before :- or }) to avoid matching default values
    COMPOSE_VARS=$(grep -oE '\$\{[A-Z_][A-Z_0-9]*' "$COMPOSE" | grep -oE '[A-Z_][A-Z_0-9]+' | sort -u)
    ENV_VARS=$(grep -E '^[A-Z_][A-Z_0-9]*=' "$DIR/.env.example" | cut -d= -f1 | sort -u)
    MISSING_IN_ENV=""
    while IFS= read -r var; do
      if ! echo "$ENV_VARS" | grep -qx "$var"; then
        MISSING_IN_ENV="$MISSING_IN_ENV $var"
      fi
    done <<< "$COMPOSE_VARS"
    if [[ -n "$MISSING_IN_ENV" ]]; then
      fail "$LABEL: vars used in docker-compose.yml but missing from .env.example:$MISSING_IN_ENV"
    else
      pass "$LABEL: .env.example covers all compose vars"
    fi
  fi

  # 14. README image version column matches primary image in docker-compose.yml
  PRIMARY_IMAGE=$(grep -E '^\s+image:' "$COMPOSE" | head -1 | awk '{print $2}' | tr -d '"'"'" | tr -d "'")
  if [[ -n "$PRIMARY_IMAGE" ]] && [[ "$PRIMARY_IMAGE" != *'${'* ]]; then
    check_readme_version "$LABEL" "$PRIMARY_IMAGE"
    if [[ $ERRORS -eq 0 ]] || ! grep -qF "$PRIMARY_IMAGE" "$README" 2>/dev/null; then
      :
    else
      pass "$LABEL: README image version matches compose"
    fi
    if grep -qF "$PRIMARY_IMAGE" "$README" 2>/dev/null; then
      pass "$LABEL: README image version matches compose ($PRIMARY_IMAGE)"
    fi
  fi

done

echo ""
echo "══════════════════════════════════════"
if [[ $ERRORS -gt 0 ]]; then
  red "FAILED: $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
else
  green "PASSED: 0 errors, $WARNINGS warning(s)"
  exit 0
fi
