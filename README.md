# pikiosk

Manage a fleet of Raspberry Pi kiosks (full-screen Chromium) from one place.

| Component | Where | What it is |
|---|---|---|
| **Central** | [`central/`](central) | Flask web app (Docker) that stores each Pi's URL, rotation and zoom, and tracks check-ins. |
| **Local manager** | [`localmanager/`](localmanager) | Runs on each Pi: launches the kiosk, checks in with Central, serves a small local config UI. Installed with Ansible. |

> `localmanager` used to live in its own repo, `pikiosk-localmanager`. Its full
> history was merged here under `localmanager/`.

## Install a Pi

On a fresh Raspberry Pi OS install, as the `pi` user:

```bash
wget https://raw.githubusercontent.com/Pingue/pikiosk/main/localmanager/setup.sh
bash setup.sh
```

This clones this repo to `/opt/pikiosk` and runs the Ansible playbook in
`localmanager/ansible`. Pass `-m` to skip the manager URL prompt and `-l` to
skip fetching a logo.

## Run Central

```bash
docker run -p 5000:5000 -v ./data:/data ghcr.io/pingue/pikiosk:latest
```

or build locally with `docker compose up --build`.

## Development

```bash
# Central
pip install -r central/requirements.txt pytest && python -m pytest central/tests
# Local manager
pip install -r localmanager/requirements.txt pytest && python -m pytest localmanager/tests
```

CI (`.github/workflows/ci.yml`) runs ruff, shellcheck, ansible-lint, both test
suites and a Docker build on every PR.

## Releases

Every merge to `main` runs `.github/workflows/release.yml`:

1. CI must pass.
2. [GitVersion](GitVersion.yml) works out the next semantic version from
   conventional-commit messages (`feat:` → minor, `fix:`/`perf:` → patch,
   `!`/`BREAKING CHANGE:` → major) and tags it `vX.Y.Z`. **PR titles must be
   conventional commits** (CI checks this), since squash-merges use the title.
3. The Central image is published to `ghcr.io/pingue/pikiosk`
   (`:vX.Y.Z`-style version tag and `:latest`, amd64 + arm64).
4. A GitHub Release is created with generated notes and a
   `pikiosk-localmanager-vX.Y.Z.tar.gz` asset.

## TODO (local manager)

- Not working on first boot (trying before network?)
- Occasional race condition causing login to fail because pikiosk has already taken `DISPLAY=:0`; maybe pause until a display is available
- Check: screensaver isn't disabled
