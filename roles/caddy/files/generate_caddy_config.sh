#!/usr/bin/env bash

# Fail immediately on all errors
set -e
set -o pipefail

# Enable nullglob to evaluate /etc/caddy/sites.d/*.json to <empty string> if there are no JSON files
shopt -s nullglob

# Check if caddy adapt succeeds
/home/caddy/.local/bin/caddy adapt --config /etc/caddy/Caddyfile > /dev/null

# Generate config to new file
/usr/bin/jq -cs 'reduce .[] as $item ({}; . * $item)' /etc/caddy/sites.d/*.json <(/home/caddy/.local/bin/caddy adapt --config /etc/caddy/Caddyfile) > /etc/caddy/config.json.new

# Validate that config is correct
/home/caddy/.local/bin/caddy validate --config /etc/caddy/config.json.new

# Replace old config with new one
/usr/bin/mv /etc/caddy/config.json.new /etc/caddy/config.json
