#!/bin/bash

# Vercel Dynamic DNS
# https://github.com/iam-medvedev/vercel-ddns

source /root/dns.config

# Validate required config
for var in VERCEL_TOKEN DOMAIN_NAME RECORD_TYPE; do
  if [[ -z "${!var}" ]]; then
    echo "Error: $var is not set in dns.config"
    exit 1
  fi
done

# Build optional team query parameter
TEAM_QUERY=""
if [[ -n "$TEAM_ID" ]]; then
  TEAM_QUERY="?teamId=$TEAM_ID"
fi

# Check if jq is installed
if ! command -v jq >/dev/null; then
  echo "Error: 'jq' is not installed. Please install 'jq' to run this script."
  exit 1
fi

# Returns current IP (IPv4 for A records, IPv6 for AAAA records)
get_current_ip() {
  local ip
  if [[ "$RECORD_TYPE" == "AAAA" ]]; then
    ip=$(curl -6 -s --max-time 10 https://ifconfig.co)
  else
    ip=$(curl -s --max-time 10 http://whatismyip.akamai.com/)
  fi
  echo "$ip"
}

# Function to check if subdomain exists
check_subdomain_exists() {
  local subdomain="$1"
  local response
  response=$(curl -sX GET "https://api.vercel.com/v4/domains/$DOMAIN_NAME/records$TEAM_QUERY" \
    -H "Authorization: Bearer $VERCEL_TOKEN" \
    -H "Content-Type: application/json")

  if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: Vercel API error listing records: $(echo "$response" | jq -r '.error.message')" >&2
    exit 1
  fi

  local record_id
  record_id=$(echo "$response" | jq -r ".records[] | select(.name == \"$subdomain\" and .type == \"$RECORD_TYPE\") | .id")
  if [[ -n "$record_id" ]]; then
    echo "$record_id"
  else
    return 1
  fi
}

# Updates dns record
update_dns_record() {
  local ip="$1"
  local record_id="$2"
  local response
  response=$(curl -sX PATCH "https://api.vercel.com/v1/domains/records/$record_id$TEAM_QUERY" \
    -H "Authorization: Bearer $VERCEL_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "comment": "vercel-ddns",
      "name": "'$SUBDOMAIN'",
      "type": "'$RECORD_TYPE'",
      "value": "'$ip'",
      "ttl": 60
    }')

  if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: failed to update DNS record: $(echo "$response" | jq -r '.error.message')" >&2
    exit 1
  fi
}

# Creates dns record
create_dns_record() {
  local ip="$1"
  local response
  response=$(curl -sX POST "https://api.vercel.com/v4/domains/$DOMAIN_NAME/records$TEAM_QUERY" \
    -H "Authorization: Bearer $VERCEL_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "comment": "vercel-ddns",
      "name": "'$SUBDOMAIN'",
      "type": "'$RECORD_TYPE'",
      "value": "'$ip'",
      "ttl": 60
    }')

  if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: failed to create DNS record: $(echo "$response" | jq -r '.error.message')" >&2
    exit 1
  fi
}

# Get current IP
ip=$(get_current_ip)
if [[ -z "$ip" ]]; then
  echo "Error: failed to determine current IP address" >&2
  exit 1
fi
echo "Current IP: $ip"

# Check if subdomain exists
record_id=$(check_subdomain_exists "$SUBDOMAIN")
if [[ -n "$record_id" ]]; then
  echo "Record for $SUBDOMAIN.$DOMAIN_NAME already exists (id: $record_id). Updating..."
  update_dns_record "$ip" "$record_id"
else
  echo "Record for $SUBDOMAIN.$DOMAIN_NAME does not exist. Creating..."
  create_dns_record "$ip"
fi
