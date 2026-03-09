# Vercel Dynamic DNS

Simple script for exposing a local server with [Vercel DNS](https://vercel.com/docs/custom-domains).
It runs on CRON, checking the current IP address and updating DNS records for your domain.

This fork has been modified to:
* Support optional Team IDs (for both personal and team accounts)
* Support `A` or `AAAA` records
* Be more robust in terms of error reporting
* Eliminate the need for a start script for Docker
* Use standard `cron` instead of `dcron`

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

These instructions outline how to set up a dockerized version of `vercel-ddns`.

Create 2 files in your directory:

1. `dns.config`: use `dns.config.example` and fill out appropriately
2. The following `Dockerfile`:

```dockerfile
FROM alpine:latest

WORKDIR /root

# Installing dependencies
RUN apk --no-cache add curl jq bash
SHELL ["/bin/bash", "-c"]

# Copy config
COPY dns.config /root/dns.config

# Cloning app
RUN curl -o /root/dns-sync.sh https://raw.githubusercontent.com/ohshitgorillas/vercel-ddns/master/dns-sync.sh
RUN chmod +x /root/dns-sync.sh

# Setting up cron to run every minute
RUN echo "* * * * * /root/dns-sync.sh >> /proc/1/fd/1 2>&1" >> /etc/crontabs/root

# Perform first sync immediately, then hand off to cron
CMD ["/bin/bash", "-c", "/root/dns-sync.sh && crond -f -l 2"]
```

**NOTE**: If managing `AAAA` records through Docker, you will need to enable host networking via `--network=host` or `network_mode: host`.

Run `docker build .` followed by:

```bash
docker run -d --name vercel-ddns --restart always vercel-ddns
```

For `docker compose`, you can use the example `docker-compose.yaml` file:

```yaml
services:
  vercel-ddns:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: vercel-ddns
    restart: always 
```


Run `docker compose build` then `docker compose up -d` from the working directory. 

Finally, check `docker logs vercel-ddns` or `docker compose logs vercel-ddns` to verify that everything is working.
