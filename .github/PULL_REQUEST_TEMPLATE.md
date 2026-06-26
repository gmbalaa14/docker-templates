## Description

<!-- Briefly describe what this PR adds or changes -->

## PR Checklist

- [ ] Folder name is lowercase-hyphenated
- [ ] `docker-compose.yml` is present and valid (`docker compose config` passes)
- [ ] `README.md` is present and follows the template structure
- [ ] `.env.example` is present with all variables documented
- [ ] No hardcoded passwords or secrets in `docker-compose.yml`
- [ ] No hardcoded IP addresses in `docker-compose.yml`
- [ ] No hardcoded absolute host paths or tilde paths in `docker-compose.yml`
- [ ] `name: <project-name>` set at top of `docker-compose.yml`
- [ ] All host ports wrapped in `${VAR:-default}` env vars
- [ ] NPM opt-in commented block present at bottom of `docker-compose.yml`
- [ ] Root `README.md` templates table updated
- [ ] `docker compose up -d` tested locally
