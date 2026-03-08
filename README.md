# Vercel Dynamic DNS

Simple script for exposing a local server with [Vercel DNS](https://vercel.com/docs/custom-domains).
It runs on CRON, checking the current IP address and updating DNS records for your domain.

This fork has been modified to:
* Support optional Team IDs (for both personal and team accounts)
* Distinguish A from AAAA records
* Be more robust in terms of error reporting

## Installation

1. Ensure that you have [jq](https://github.com/jqlang/jq) installed
2. Download `dns-sync.sh`
3. Move `dns.config.example` to `dns.config`
4. Edit the configuration variables as required
5. Open the cron settings using the command `crontab -e`
6. Add the following line to the cron job: `* * * * * /path-to/vercel-ddns/dns-sync.sh`

## Usage example

```sh
# Creating
➜  ./dns-sync.sh
Current IP: x.x.x.x
Record for SUBDOMAIN.example.com does not exist. Creating...
Done.

# Updating
➜  ./dns-sync.sh
Current IP: x.x.x.x
Record for SUBDOMAIN.example.com already exists (id: rec_xxxxxxxxxxxxxxxxxxxxxxxx). Updating...
Done.
```

## Docker

There is a dockerized version of `vercel-ddns` with `CRON`.

Create 2 files in your directory:

1. `Dockerfile`.
2. `dns.config` - configuration for `vercel-ddns`.

`Dockerfile`:

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
RUN echo "* * * * * /root/dns-sync.sh >> /var/log/dns-sync.log 2>&1" >> /etc/crontabs/root

# Perform first sync immediately, then hand off to cron
CMD ["/bin/bash", "-c", "/root/dns-sync.sh && crond -f -l 2"]
```

## IPv4 vs IPv6

The `RECORD_TYPE` variable in `dns.config` controls whether the script manages an `A` (IPv4) or `AAAA` (IPv6) record:

```sh
# "A" for IPv4 (default), "AAAA" for IPv6
RECORD_TYPE="A"
```

The script automatically uses the correct IP lookup endpoint for the chosen record type.

If using Docker with IPv6, enable host networking via `--network=host` or `network_mode: host`.
