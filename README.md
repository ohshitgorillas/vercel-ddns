# Vercel Dynamic DNS

Simple script for exposing a local server with [Vercel DNS](https://vercel.com/docs/custom-domains).
It runs on CRON, checking the current IP address and updating DNS records for your domain.

This fork has been modified to:
* Support optional Team IDs (for both personal and team accounts)
* Support `A` or `AAAA` records
* Be more robust in terms of error reporting
* Eliminate the need for a start script for Docker
* Use standard `cron` instead of `dcron`
* Publish a multi-arch image (`linux/amd64`, `linux/arm64`) to GHCR on every push to `master`

## Bare Metal Installation

1. Ensure that you have [jq](https://github.com/jqlang/jq) installed
2. Download `dns-sync.sh` and `dns.config.example`
3. Move `dns.config.example` to `dns.config`
4. Edit the configuration variables as required (`TEAM_ID` is optional)
5. Open the cron settings using the command `crontab -e`
6. Add the following line to the cron job: `* * * * * /path-to/vercel-ddns/dns-sync.sh`

### Usage example

```sh
# Creating
➜  ./dns-sync.sh
Current IP: x.x.x.x
Record for SUBDOMAIN.example.com does not exist. Creating...

# Updating
➜  ./dns-sync.sh
Current IP: x.x.x.x
Record for SUBDOMAIN.example.com already exists (id: rec_xxxxxxxxxxxxxxxxxxxxxxxx). Updating...
```

## Docker Setup

The image is published to GHCR as `ghcr.io/ohshitgorillas/vercel-ddns:latest`
(multi-arch: `linux/amd64`, `linux/arm64`). It does **not** bake `dns.config` in —
the config holds your `VERCEL_TOKEN`, so it must be bind-mounted at runtime.

1. Copy `dns.config.example` to `dns.config` and fill in your values.
2. Run the container, mounting the config read-only at `/root/dns.config`:

```bash
docker run -d \
  --name vercel-ddns \
  --restart always \
  -v "$(pwd)/dns.config:/root/dns.config:ro" \
  ghcr.io/ohshitgorillas/vercel-ddns:latest
```

Or with `docker compose`:

```yaml
services:
  vercel-ddns:
    image: ghcr.io/ohshitgorillas/vercel-ddns:latest
    container_name: vercel-ddns
    restart: always
    volumes:
      - ./dns.config:/root/dns.config:ro
```

**NOTE:** If managing `AAAA` records, enable host networking with `--network=host`
(`docker run`) or `network_mode: host` (compose) so the container can see the host's
public IPv6 address.

Check `docker logs vercel-ddns` (or `docker compose logs vercel-ddns`) to verify the
first sync ran cleanly.

### Building locally

If you'd rather build the image yourself:

```bash
docker build -t vercel-ddns .
docker run -d --name vercel-ddns --restart always \
  -v "$(pwd)/dns.config:/root/dns.config:ro" vercel-ddns
```

Available tags on GHCR:
* `latest` — tip of `master`
* `master` — same as `latest`
* `sha-<short-sha>` — pinned to a specific commit
* semver tags (`vX.Y.Z`) once tagged releases are cut
