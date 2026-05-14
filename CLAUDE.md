# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker image for running a BorgBackup server. It builds a Debian-based container with openssh-daemon that accepts SSH key auth for borg clients. Each client SSH key in `/sshkeys/clients/` maps to a separate borg repository.

## Key Files

- `Dockerfile` - Builds the image from `debian:<version>-slim`, installs `borgbackup` + `openssh-server`
- `data/run.sh` - Entrypoint script: adjusts PUID/PGID, generates SSH host keys, imports client keys into `authorized_keys` with restricted `borg serve` commands, starts sshd
- `data/sshd_config` - Hardened SSH config: pubkey-only, no forwarding, no TTY, SFTP disabled
- `.woodpecker.yml` - CI pipeline using Woodpecker CI with Docker Buildx for multi-platform builds
- `docker-compose.yml` - Example compose file

## Architecture

The entrypoint (`run.sh`) works as follows:
1. Adjusts `borg` user/group IDs to match host PUID/PGID
2. Validates `/backup` and `/sshkeys` volumes exist and that at least one client key is present (sshd won't start otherwise)
3. Generates SSH host keys (ed25519, rsa) in `/sshkeys/host/` if missing
4. Iterates over files in `/sshkeys/clients/`, creating an `authorized_keys` entry per client with:
   - `restrict` flag + `command=` wrapping a `borg serve --restrict-to-path` command
   - If `BORG_ADMIN` is set, that client gets unrestricted access to all repos
   - If `BORG_APPEND_ONLY=yes`, non-admin clients get `--append-only`
5. Starts `/usr/sbin/sshd -D -e`

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `BORG_APPEND_ONLY` | `no` | Restrict clients to append-only mode |
| `BORG_ADMIN` | unset | Client key name that gets full access to all repos |
| `BORG_SERVE_ARGS` | unset | Extra args passed to `borg serve` |
| `PUID` | `1000` | User ID for `borg` user |
| `PGID` | `1000` | Group ID for `borg` group |

## CI/CD

Built via Woodpecker CI (`.woodpecker.yml`). Matrix builds target:
- `unstable-slim` → `linux/arm64/v8` tag `unstable`

Builds publish to Docker Hub (`nold360/borgserver`) and GHCR (`ghcr.io/nold360/borgserver`).

## Building Locally

```bash
docker build -t borgserver:dev .
docker build --build-arg BASE_IMAGE=debian:trixie-slim -t borgserver:trixie .
```
