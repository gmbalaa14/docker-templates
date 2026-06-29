## Description

<!-- Briefly describe what this PR adds or changes -->

## PR Checklist

### Structure
- [ ] Folder name is lowercase-hyphenated
- [ ] `docker-compose.yml` is present and valid (`docker compose config` passes)
- [ ] `README.md` is present and follows the template structure (all 11 required sections)
- [ ] `.env.example` is present and documents **every** `${VAR}` referenced in `docker-compose.yml`
- [ ] `name: <project-name>` set at top of `docker-compose.yml`
- [ ] All host ports wrapped in `${VAR:-default}` env vars
- [ ] NPM opt-in commented block present at bottom of `docker-compose.yml`
- [ ] `restart: unless-stopped` used (not `restart: always`)

### Security
- [ ] No hardcoded passwords or secrets in `docker-compose.yml` — use `${VAR}` references
- [ ] No hardcoded IP addresses in `docker-compose.yml` — use `${VAR}` or hostnames
- [ ] No hardcoded absolute host paths or tilde paths in `docker-compose.yml`
- [ ] `# WARNING:` comment present above any Docker socket mount (`/var/run/docker.sock`)
- [ ] `# WARNING:` comment present above any `privileged: true` declaration

### Image & Versioning
- [ ] Image pinned to a specific stable version tag (not `:latest`)
- [ ] Image version column in root `README.md` templates table updated to match `docker-compose.yml`
- [ ] `postgres:12` or other EOL base images not introduced (use current supported versions)

### Testing
- [ ] `docker compose up -d` tested locally and all containers reach running/healthy state
- [ ] Root `README.md` templates table row added/updated (description, ports, image version, notes)
