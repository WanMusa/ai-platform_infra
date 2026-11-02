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

## Observability

Grafana, Loki and Alloy run as shared infrastructure services. Alloy reads logs
only from containers explicitly labeled for collection, through a restricted
Docker socket proxy. The initial `Resume Builder V3` dashboard is provisioned in
the `Applications` folder. Add the same labels to another app's Compose services
and create a dashboard JSON file to onboard it later.

Loki stores logs in the persistent `loki_data` volume and deletes them after seven
days. The initial dashboard covers V3 worker logs; events include job ID, stage,
duration and sanitized error type, not resume text, prompts, API responses or
credentials.

Before the first deployment, set `GRAFANA_ADMIN_PASSWORD` in the VPS `.env` to a
unique strong password. Grafana listens on the VPS loopback interface only; it is
not registered with the public reverse proxy. After deployment, install and join
the VPS to your Tailscale tailnet if you have not already, then run:

```bash
sudo tailscale serve --bg 3000
sudo tailscale serve status
```

Use the HTTPS `*.ts.net` address shown by `tailscale serve status` from your
tailnet devices. If prompted, enable HTTPS certificates for the tailnet. Do not
enable Funnel or add a public `VIRTUAL_HOST` for Grafana.

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
