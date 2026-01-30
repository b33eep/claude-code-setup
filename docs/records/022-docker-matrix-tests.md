# Record 022: Docker Matrix Tests for deps.json

**Status:** Planned
**Priority:** Low
**Date:** 2026-01-30

## Problem

Skills with `deps.json` define platform-specific install commands:

```json
{
  "dependencies": [{
    "name": "yt-dlp",
    "install": {
      "macos": "brew install yt-dlp",
      "debian": "apt-get install -y python3-pip && pip3 install --user yt-dlp",
      "arch": "pacman -S --noconfirm yt-dlp",
      "fedora": "dnf install -y python3-pip && pip3 install --user yt-dlp"
    }
  }]
}
```

Currently we only test:
- JSON structure is valid
- Expected fields exist
- Command strings look plausible

We do NOT test:
- Commands actually work on target platforms
- Package names are correct
- Dependencies resolve properly

## Solution

Add GitHub Actions workflow with Docker matrix:

```yaml
# .github/workflows/deps-validation.yml
name: Validate deps.json

on:
  push:
    paths:
      - 'skills/*/deps.json'
  workflow_dispatch:

jobs:
  validate:
    strategy:
      matrix:
        include:
          - distro: debian
            image: debian:bookworm
          - distro: arch
            image: archlinux:latest
          - distro: fedora
            image: fedora:latest
          - distro: suse
            image: opensuse/tumbleweed

    runs-on: ubuntu-latest
    container: ${{ matrix.image }}

    steps:
      - uses: actions/checkout@v4

      - name: Install jq
        run: |
          # distro-specific jq install

      - name: Validate deps.json commands
        run: |
          for deps_file in skills/*/deps.json; do
            # Extract install command for this distro
            # Run it
            # Verify command -v succeeds
          done
```

## Trade-offs

| Pro | Con |
|-----|-----|
| Catches broken commands before release | Slow (Docker pull + package install) |
| Tests real package manager behavior | Flaky (network, mirrors) |
| Documents supported distros | Maintenance overhead |

## Decision

- Run on `workflow_dispatch` (manual) and when deps.json changes
- NOT on every PR (too slow, too flaky)
- Failure = warning, not blocking

## Implementation

1. [ ] Create `.github/workflows/deps-validation.yml`
2. [ ] Test with youtube-transcript skill
3. [ ] Add badge to README (optional)

## References

- [Record 021](021-youtube-transcript-skill.md) - deps.json format
- [Record 014](014-linux-support.md) - Linux distro detection
