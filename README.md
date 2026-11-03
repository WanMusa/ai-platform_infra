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

### Private Grafana access through Cloudflare

Grafana has no published host port and is not registered with the public reverse
proxy. The `cloudflared` container joins the internal observability network to
reach Grafana and a separate egress network to establish its outbound tunnel.
No Oracle ingress port is needed for the tunnel.

One-time Cloudflare setup:

1. In Cloudflare Zero Trust, create a remotely managed tunnel for this VPS and
	copy its tunnel token.
2. Before adding a public hostname route, create an Access application for
	`grafana.musakamil.com`. Add an Allow policy for your email address and choose
	an authentication method such as a one-time PIN or Google login. Access
	applications deny requests unless a policy allows them.
3. Add a public hostname to the tunnel: `grafana.musakamil.com`, service type
	HTTP, origin `http://grafana:3000`.
4. On the VPS, set `GRAFANA_ADMIN_PASSWORD`, `GRAFANA_HOSTNAME`, and
	`CLOUDFLARE_TUNNEL_TOKEN` in `$HOME/projects/ai-platform_infra/.env`. Keep the
	tunnel token secret; do not commit it to Git.
5. Push the infra changes to `main`. GitHub Actions validates and deploys the
	stack. Then browse to `https://grafana.musakamil.com` and authenticate through
	Cloudflare Access.

Cloudflare creates the tunnel DNS record for an active Cloudflare-managed zone.
Do not enable a public DNS-only origin route, add Grafana to `VIRTUAL_HOST`, or
open Grafana's port in the Oracle firewall. This keeps the origin reachable only
through the authenticated Cloudflare path.

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
