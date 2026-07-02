# Contributing to docker-templates

Thank you for contributing! This guide covers everything you need to know to add a new template or improve an existing one.

## Table of Contents

- [Documentation Site](#documentation-site)
- [Folder and File Naming](#folder-and-file-naming)
- [Required Files Per Template](#required-files-per-template)
- [Docker Compose Best Practices](#docker-compose-best-practices)
- [Shared Networks](#shared-networks)
- [Security Warning Requirements](#security-warning-requirements)
- [Portainer and Docker Desktop Compatibility](#portainer-and-docker-desktop-compatibility)
- [Submitting a PR](#submitting-a-pr)
- [PR Checklist](#pr-checklist)
- [Code of Conduct](#code-of-conduct)

---

## Documentation Site

This repo uses an [Astro Starlight](https://starlight.astro.build/) documentation site at `docs/`, published to [gmbalaa14.github.io/docker-templates](https://gmbalaa14.github.io/docker-templates/).

**When adding a new template**, you must also add a documentation page for it:

1. Create `docs/src/content/docs/templates/<your-service>.mdx`
2. Follow the section structure used by existing template pages:
   - Introduction → When to Use → Architecture (Mermaid diagram) → Prerequisites → Configuration → Workflow → Use Cases → Integration → References
3. Add the new template to the `sidebar` array in `docs/astro.config.mjs`
4. Add a Mermaid architecture diagram using the `<Mermaid>` component (`import Mermaid from '../../components/Mermaid.astro'`)

**Per-template `README.md` files are stubs** — they contain only a link to the docs site. Do not add full documentation to a per-template README; put it in the MDX page instead.

To build the docs site locally:
```bash
make docs
# OR
cd docs && npm ci && npm run build
# OR for live preview
cd docs && npm run dev
```

---

## Folder and File Naming

- **Folder names** must be all lowercase with hyphens as separators: `my-service`, not `MyService` or `my_service`.
- Each template lives in its own top-level folder unless it is a logical sub-variant of an existing grouping (e.g., `kafka/confluent/`).
- The compose file must be named **`docker-compose.yml`**.
- Each folder must contain a **`README.md`** (all caps, `.md` extension).
- The historical `kafka/` folder uses a nested structure — follow the same pattern for future Kafka variants.

---

## Required Files Per Template

Every template folder must contain:

| File | Required | Notes |
|---|---|---|
| `docker-compose.yml` | Yes | The Compose configuration |
| `README.md` | Yes | Stub linking to the docs site (see [Documentation Site](#documentation-site)) |
| `.env.example` | Yes (if any env vars used) | All variables with comments; no real secrets |

The `README.md` in each template folder is a **stub** — it points readers to the docs site where the full documentation lives. Do not write full documentation in the per-template README.

---

## Docker Compose Best Practices

### No hardcoded credentials

Passwords, API keys, and secrets must never appear in the committed compose file. Use `${MY_SECRET}` references and document the variable in `.env.example` with a blank value and a generation command where applicable.

### No hardcoded host IP addresses

Advertised listener IPs (as in Kafka templates) must use a variable: `${KAFKA_HOST_IP}`. Leave the default blank to force the user to set it.

### No hardcoded host filesystem paths

Avoid bind mounts to absolute paths like `/home/user/data:/data`. Use named Docker volumes as the default. If a bind mount is genuinely needed, use an env var: `${DATA_DIR:-./data}:/data`.

### No tilde paths

Tilde paths (`~/service-data`) do not expand correctly inside Portainer. Use named volumes instead.

### Fixed project name

Add `name: <service-name>` at the top of every compose file to lock the Docker project name and prevent named volume conflicts when the folder is cloned to a non-standard path.

### Parameterise ports

Wrap all host-side port mappings in env vars with sensible defaults: `"${MY_SERVICE_PORT:-8080}:8080"`. This allows users to resolve port conflicts without editing the compose file.

### Use `restart: unless-stopped`

Prefer `unless-stopped` over `always` so that a deliberately stopped container does not auto-restart.

### Document image tags

`:latest` tags are acceptable for ease of maintenance but must be noted in the README. For version-sensitive templates, pin to a specific tag.

---

## Shared Networks

This repo uses two pre-created shared bridge networks. Do not own or create these networks inside a compose file — declare them as `external: true`.

| Network | Purpose |
|---|---|
| `proxy-net` | Allows Nginx Proxy Manager to reverse-proxy opted-in services |
| `kafka-ui-net` | Allows Kafka UI to reach Kafka clusters |

### NPM opt-in block

Every new template **must** include this commented block at the bottom of `docker-compose.yml`:

```yaml
# ── Nginx Proxy Manager integration (optional) ─────────────────────────
# Requires proxy-net to exist: docker network create proxy-net
# Uncomment to allow NPM to reverse-proxy this service.
# networks:
#   default:
#   proxy-net:
#     external: true
#     name: proxy-net
```

### Kafka cluster templates

Templates that are Kafka clusters must join `kafka-ui-net` as an external network so the shared Kafka UI can reach their brokers.

---

## Security Warning Requirements

Use the following blockquote format for prominent warnings:

```markdown
> **WARNING:** ...
> **SECURITY:** ...
> **REQUIRED:** ...
> **CRITICAL:** ...
```

A warning block is required whenever a template has any of the following:

- Hardcoded or default credentials (warn to change them)
- `privileged: true` or `user: root`
- Docker socket mount (`/var/run/docker.sock`)
- Required env vars with no default (explain what happens if they are missing)
- Data loss risk on `docker compose down -v`

---

## Portainer and Docker Desktop Compatibility

Every template README must include a **Deploy with Portainer** section and a **Docker Desktop Notes** section.

Key requirements:

- No tilde paths in volumes — use named volumes.
- Note that Portainer's **Environment variables** UI replaces `.env` files for Git-based stacks.
- For services requiring kernel tuning (e.g., `vm.max_map_count`), document both the Linux command and the Docker Desktop path.
- For services that require a host IP (e.g., Kafka), document how to find it on Linux, macOS, Docker Desktop Mac, and Docker Desktop Windows.

---

## Submitting a PR

1. Fork the repository.
2. Create a feature branch: `git checkout -b add-<service-name>`
3. Add your template folder with all required files.
4. Verify the compose file starts correctly:
   ```bash
   cp .env.example .env
   # Fill in required values
   docker compose up -d && docker compose ps
   ```
5. Update the **Templates** table in the root `README.md` with a row for your service.
6. Add a documentation page at `docs/src/content/docs/templates/<your-service>.mdx` and add it to the sidebar in `docs/astro.config.mjs`.
7. Open a pull request against `main` using the checklist below.

---

## PR Checklist

Copy this into your pull request description:

```
- [ ] Folder name is lowercase-hyphenated
- [ ] docker-compose.yml is present and valid (docker compose config passes)
- [ ] README.md stub present (contains <!-- stub --> and link to docs site)
- [ ] .env.example is present with all variables documented
- [ ] No hardcoded passwords or secrets in docker-compose.yml
- [ ] No hardcoded IP addresses in docker-compose.yml
- [ ] No hardcoded absolute host paths or tilde paths in docker-compose.yml
- [ ] name: <project-name> set at top of docker-compose.yml
- [ ] All host ports wrapped in ${VAR:-default} env vars
- [ ] NPM opt-in commented block present at bottom of docker-compose.yml
- [ ] Root README.md templates table updated
- [ ] docs/src/content/docs/templates/<service>.mdx created
- [ ] Sidebar entry added in docs/astro.config.mjs
- [ ] docker compose up -d tested locally
- [ ] make docs builds without errors
```

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md). By participating you agree to abide by its terms.
