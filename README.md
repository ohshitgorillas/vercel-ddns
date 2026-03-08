# Vercel Dynamic DNS

Simple script for exposing a local server with [Vercel DNS](https://vercel.com/docs/custom-domains).
It runs on CRON, checking the current IP address and updating DNS records for your domain.

This fork has been modified to:
* Work with accounts that have Team IDs
* Distinguish A from AAAA records

## Installation

1. Ensure that you have [jq](https://github.com/jqlang/jq) installed
2. Download `dns-sync.sh`
3. Move `dns.config.example` to `dns.config`
4. Edit the configuration variables as required
5. Open the cron settings using the command `crontab -e`
6. Add the following line to the cron job: `*/15 * * * * /path-to/vercel-ddns/dns-sync.sh`

## Usage example

```sh
# Creating
➜  ./dns-sync.sh
Updating IP: x.x.x.x
Record for SUBDOMAIN does not exist. Creating...
🎉 Done!

# Updating
➜  ./dns-sync.sh
Updating IP: x.x.x.x
Record for SUBDOMAIN already exists (id: rec_xxxxxxxxxxxxxxxxxxxxxxxx). Updating...
🎉 Done!
```

## Docker

There is a dockerized version of `vercel-ddns` with `CRON`.

Create 3 files in your directory:

1. `Dockerfile`.
2. `start.sh` - docker entry point
3. `dns.config` - configuration for `vercel-ddns`.

`Dockerfile`:

```dockerfile
FROM alpine:latest

WORKDIR /root

# Installing dependencies
RUN apk --no-cache add dcron curl jq bash
SHELL ["/bin/bash", "-c"]

# Cloning config and start file
COPY dns.config /root/dns.config
COPY start.sh /root/start.sh

# Cloning app
RUN curl -o /root/dns-sync.sh https://raw.github.com/ohshitgorillas/vercel-ddns/master/dns-sync.sh
RUN chmod +x /root/dns-sync.sh

# Setting up cron to run every minute
RUN echo "* * * * * /root/dns-sync.sh >> /var/log/dns-sync.log 2>&1" >> /etc/crontabs/root

# Starting
CMD ["bash", "/root/start.sh"]
```

`start.sh`:

```sh
# Performs the first sync and starts CRON
bash /root/dns-sync.sh && crond -f
```

## AAAA Records

The script can be modified to work with IPv6 addresses and AAAA records.

Make the following changes to `dns-sync.sh`:

1. Change line 17 to `  ip=$(curl -6 -s https://ifconfig.co)`
2. On line 30, change `\"A\"` to `\"AAAA\"`
3. On lines 51 and 75, change `"A"` to `"AAAA"`

If using Docker, you will also need to:

1. Make a local copy of `dns-sync.sh` with the above modifications, as well as `start.sh` and `dns.config`.
2. Use the Dockerfile below.
3. Enable host networking via `--network=host` or `network_mode: host`.

This Dockerfile pulls a local version of dns-sync.sh
```dockerfile
FROM alpine:latest

WORKDIR /root

# Installing dependencies
RUN apk --no-cache add dcron curl jq bash
SHELL ["/bin/bash", "-c"]

# Cloning config and start file
COPY dns.config /root/dns.config
COPY start.sh /root/start.sh
COPY dns-sync.sh /root/dns-sync.sh

# Make the main script executable
RUN chmod +x /root/dns-sync.sh

# Setting up cron to run every minute
RUN echo "* * * * * /root/dns-sync.sh >> /var/log/dns-sync.log 2>&1" >> /etc/crontabs/root

# Starting
CMD ["bash", "/root/start.sh"]
```
