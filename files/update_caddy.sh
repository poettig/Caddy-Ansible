#!/usr/bin/env bash

if [ -f /home/caddy/.local/bin/caddy ]; then
	old_version=$(/home/caddy/.local/bin/caddy version | cut -d' ' -f1) || { echo "Failed to get current caddy version."; exit 1; }
else
	old_version=""
fi

git_releases=$(curl -L https://api.github.com/repos/caddyserver/caddy/releases 2> /dev/null) || { echo "Failed to get releases from Github"; exit 1; }
git_version=$(echo "$git_releases" | jq -r 'first(.[] | select(.prerelease==false)) | .tag_name') || { echo "Failed to get latest version number from releases."; exit 1; }
git_changelog_url=$(echo "$git_releases" | jq -r 'first(.[] | select(.prerelease==false)) | .html_url')

if [[ "$old_version" != "$git_version" || "$1" == "-f" ]]; then
	if ! update_log=$(
			podman run --pull=newer -v /home/caddy/.local/bin/:/caddy-target --rm docker.io/golang:latest bash -c "
				apt-get -qq update 2>&1;
				apt-get -qq install curl jq wget tar 2>&1;
				curl -s https://api.github.com/repos/caddyserver/xcaddy/releases/latest | jq -r '.assets[] | select(.name | contains(\"linux_amd64.tar.gz\")) | .browser_download_url' | wget -q -i - -O - | tar xzf -;
				./xcaddy build --with github.com/kdf-leierkasten/caddy_leierkasten_auth --with github.com/mholt/caddy-l4 --with github.com/greenpau/caddy-security --output /caddy-target/caddy 2>&1
			"
	); then
		echo "Caddy update failed. Output:"
		echo "$update_log"
		exit 1
	fi

	echo "Updated caddy to '$(/home/caddy/.local/bin/caddy version | cut -d' ' -f1)'. Old version was '$old_version', current git version is '$git_version'."
	echo

	echo "You can find the changelog at $git_changelog_url"
	echo

	echo "Update log:"
	echo "--------------------------------------------"
	echo "$update_log"

	sudo systemctl restart caddy

	echo "Journal of caddy service after restart:"
	echo "--------------------------------------------"
	journalctl --no-pager -q _SYSTEMD_INVOCATION_ID="$(systemctl show --value -p InvocationID caddy)"
	echo
fi