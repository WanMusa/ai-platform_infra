# ai-platform_infra
The infrastructure for shared services for the ai platform

# This includes:
- postgreSQL
- nginx reverse proxy with automatic Let's Encrypt certificates

## Services

- `reverse-proxy`: central entrypoint on ports 80/443
- `reverse-proxy-acme`: automatic certificate issuing and renewal
- `postgres`: shared PostgreSQL
- `pgadmin`: local admin UI bound to localhost on port 8080

## Prerequisites

- Docker and Docker Compose installed on VPS
- DNS A record pointing your domain/subdomain to the VPS public IP
	- Example: `wanagents.duckdns.org -> <your-vps-ip>`

## Environment

Copy `.env.example` to `.env` and set real values:

- `LETSENCRYPT_EMAIL`: email used for cert registration and expiry notices
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`
- `PGADMIN_DEFAULT_EMAIL`
- `PGADMIN_DEFAULT_PASSWORD`

## Deploy

This repo is designed to be deployed fully via GitHub Actions.
Push to `main` and the workflow will run `docker compose up -d --remove-orphans` on the VPS.

## How App Repos Attach to HTTPS Automatically

For each app container in the same `ai_platform` Docker network, add:

```yaml
environment:
	VIRTUAL_HOST: wanagents.duckdns.org
	VIRTUAL_PORT: 8000
	LETSENCRYPT_HOST: wanagents.duckdns.org
	LETSENCRYPT_EMAIL: your-email@example.com
networks:
	- ai_platform
```

Notes:

- `VIRTUAL_PORT` must match the internal port your app listens on.
- Do not map public ports for app containers directly when using the reverse proxy.
- Certificates are requested automatically after DNS is correct and container is running.
