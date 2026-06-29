FROM python:3.11-slim

# Install system dependencies required for parsing libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install proxy tools in one layer to minimise image size.
# hadolint ignore=DL3013
RUN pip install --no-cache-dir "pip==24.0" \
    && pip install --no-cache-dir "headroom-ai[proxy,code]"

ENV HEADROOM_TELEMETRY=off
ENV PYTHONUNBUFFERED=1

EXPOSE 8787

CMD ["headroom", "proxy", "--port", "8787", "--host", "0.0.0.0"]
