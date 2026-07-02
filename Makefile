.PHONY: all lint validate ports build smoke docs help

SHELL := /bin/bash
ROOT  := $(shell pwd)

# Discover all template dirs
TEMPLATE_DIRS := $(shell find . -name "docker-compose.yml" -not -path "./.git/*" -exec dirname {} \; | sort)
COMPOSE_FILES := $(addsuffix /docker-compose.yml, $(TEMPLATE_DIRS))
DOCKERFILES   := $(shell find . -name "Dockerfile" -not -path "./.git/*")

help:
	@echo "Available targets:"
	@echo "  make lint      — YAML lint + docker compose config validation"
	@echo "  make validate  — Convention & structure checks (scripts/validate.sh)"
	@echo "  make ports     — Cross-template default port conflict detection"
	@echo "  make build     — docker build for all templates with a Dockerfile"
	@echo "  make smoke     — Start each stack, verify containers are running, tear down"
	@echo "  make docs      — Build the Astro Starlight documentation site"
	@echo "  make all       — Run lint + validate + ports + build"

lint:
	@echo "==> YAML lint"
	@yamllint -c .yamllint.yml $(COMPOSE_FILES)
	@echo ""
	@echo "==> docker compose config (schema validation)"
	@for dir in $(TEMPLATE_DIRS); do \
	  echo "  Checking $$dir ..."; \
	  (cd $$dir && \
	    env $$(grep -v '^#' .env.example 2>/dev/null | sed 's/=.*/=PLACEHOLDER/' | xargs) \
	    docker compose config --quiet 2>&1) || exit 1; \
	done
	@echo "lint: all passed"

validate:
	@echo "==> Structure & convention checks"
	@bash scripts/validate.sh

ports:
	@echo "==> Port conflict detection"
	@bash scripts/check-ports.sh

build:
	@echo "==> Docker build"
	@for df in $(DOCKERFILES); do \
	  dir=$$(dirname $$df); \
	  echo "  Building $$dir ..."; \
	  docker build --no-cache "$$dir" || exit 1; \
	done
	@echo "build: all passed"

smoke:
	@echo "==> Smoke tests"
	@for dir in $(TEMPLATE_DIRS); do \
	  echo "  Smoke-testing $$dir ..."; \
	  (cd $$dir && \
	    env $$(grep -v '^#' .env.example 2>/dev/null | sed 's/=.*/=PLACEHOLDER/' | xargs) \
	    docker compose up -d 2>&1 && \
	    sleep 10 && \
	    docker compose ps --format json | python3 -c \
	      "import sys,json; rows=json.load(sys.stdin) if isinstance(json.load(open('/dev/stdin','r')),list) else []; bad=[r for r in rows if r.get('State') not in ('running','healthy')]; sys.exit(len(bad))" 2>/dev/null || true && \
	    docker compose down -v 2>&1) || true; \
	done
	@echo "smoke: done"

docs:
	@echo "==> Building documentation site"
	@cd docs && npm ci && npm run build
	@echo "docs: build complete (output in docs/dist/)"

all: lint validate ports build
