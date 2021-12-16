#!/usr/bin/env bash

set -Eeuo pipefail; shopt -s nullglob; unset CDPATH; IFS=$' \t\n'

export LC_ALL=C.UTF-8 LANG=C.UTF-8

export DEBIAN_FRONTEND=noninteractive

username=student
fullname='Student'
hostname=classroom

aptupd() {
	local target=/var/cache/apt/pkgcache.bin
	local expiry=60

	if [[ ! -f $target ]] || [[ -n $(find "$target" -maxdepth 0 -type f -mmin +"$expiry" 2>/dev/null) ]]; then
		apt-get update -q -y
	fi
}

init() {
	# Disable downloading translations
	cat >/etc/apt/apt.conf.d/99notranslations <<-EOF
		Acquire::Languages "none";
	EOF

	# Do not install recommended or suggested packages by default
	cat >/etc/apt/apt.conf.d/01norecommends <<-EOF
		APT::Install-Recommends "false";
		APT::Install-Suggests "false";
	EOF

	cat >/etc/wsl.conf <<-EOF
		[network]
		hostname = $hostname
		generateHosts = false

		[user]
		default = $username
	EOF

	if [[ -f /etc/hosts ]]; then
		sed -Ei 's/127[.]0[.]1[.]1\s+.*$/127.0.1.1\t'"$hostname"'.localdomain\t'"$hostname"'/' /etc/hosts
	fi

	aptupd && apt-get -q -y upgrade

	! id -ru "$username" &>/dev/null || return 0

	adduser --uid 1000 --disabled-password --gecos "${fullname},,," "$username"
	adduser "$username" sudo

	cat >/etc/sudoers.d/student <<-EOF
		$username ALL=(ALL) NOPASSWD:ALL
	EOF
}

shutdown() {
	if command -v neofetch &>/dev/null; then
		local file=/etc/profile.d/mymotd.sh
		if [[ ! -f $file ]] || ! grep -qF neofetch "$file"; then
			echo '! command -v neofetch >/dev/null 2>&1 || neofetch' >>"$file" && chmod +x "$file" 
		fi
		sudo -u "$username" sh -c 'touch ~/.hushlogin' &>/dev/null
	fi

	apt-get -y autoremove --purge || true
	apt-get -y autoclean          || true
}

bundle.c() {
	apt-get -qq -y install \
		gcc \
		make \
		tcc \
		#
}

bundle.python() {
	apt-get -qq -y install \
		python-is-python3 \
		python3-dev \
		python3-pip \
		#
}

bundle.javascript() {
	if ! command -v node &>/dev/null || [[ ! -f /etc/apt/sources.list.d/nodesource.list ]]; then
		local keyring=/usr/share/keyrings/nodesource.gpg
		local distro=focal
		local version=node_17.x

		curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | tee "$keyring" >/dev/null

		cat >/etc/apt/sources.list.d/nodesource.list <<-EOF
			deb [signed-by=$keyring] https://deb.nodesource.com/$version $distro main
		EOF

		apt-get update -q -y
	fi

	apt-get -qq -y install nodejs

	npm install -g --silent --no-progress npm@latest
	npm install -g --silent --no-progress typescript
}

bundle.ruby() {
	apt-get -qq -y install \
		ruby-all-dev \
		ruby-bundler \
		#

	cat >/etc/gemrc <<-EOF
		gem: --no-document
	EOF
}

bundle.standard() {
	apt-get -qq -y install \
		apt-transport-https \
		build-essential \
		ca-certificates \
		curl \
		dos2unix \
		git \
		gnupg \
		jq \
		libarchive-tools \
		libffi-dev \
		libsecret-tools \
		libssl-dev \
		libxml2 \
		libxml2-dev \
		lsb-release \
		mc \
		neofetch \
		neovim \
		openssh-client \
		procps \
		rsync \
		software-properties-common \
		tmux \
		wget \
		zlib1g-dev \
		#
}

bundle.db() {
	apt-get -qq -y install \
		libsqlite3-dev \
		litecli \
		sqlite3 \
		#
}

main() {
	init

	bundle.standard

	bundle.c
	bundle.ruby
	bundle.python
	bundle.javascript

	bundle.db

	shutdown
}

main "$@"
