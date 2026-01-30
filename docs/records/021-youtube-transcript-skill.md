# Record 021: YouTube Transcript Skill

**Status:** Done
**Date:** 2026-01-30

## Problem

YouTube videos often contain valuable information (tutorials, conference talks, documentation) that users want to analyze with Claude. Currently, users must:

1. Manually copy transcripts (if available)
2. Watch entire videos
3. Lose visual references ("Look at this diagram...")

## Solution

A command skill `/youtube-transcript` that:

1. **Downloads transcript with timestamps** via yt-dlp
2. **Detects visual references** in text (e.g., "look at this", "this diagram", "as you can see")
3. **Extracts frames** at those timestamps via ffmpeg
4. **Works cross-platform** (macOS + Linux)

## Design

### Workflow

```
User: /youtube-transcript https://youtube.com/watch?v=xyz

Claude:
1. Checks if yt-dlp and ffmpeg are installed
2. Downloads transcript (with timestamps)
3. Analyzes text for visual references
4. Extracts frames as needed
5. Presents transcript + images
```

### Tools & Dependencies

| Tool | macOS | Debian/Ubuntu | Arch | Fedora |
|------|-------|---------------|------|--------|
| yt-dlp | `brew install yt-dlp` | `pip install yt-dlp` | `pacman -S yt-dlp` | `pip install yt-dlp` |
| ffmpeg | `brew install ffmpeg` | `apt install ffmpeg` | `pacman -S ffmpeg` | `dnf install ffmpeg` |

**Note:** yt-dlp is not available in all Linux repos, hence pip as fallback.

### Visual Reference Patterns

Regex patterns for detecting where frames would be useful:

**German:**
- `schau(t)? (mal )?(hier|das)`
- `(dieses|das|dieser) (Diagramm|Bild|Schema|Chart|Graph|Screen|Slide)`
- `wie (du|ihr|Sie) (hier )?(siehst|sehen)`
- `auf (dem|diesem) (Bildschirm|Screen|Slide)`
- `hier sehen wir`

**English:**
- `look at this`
- `as you can see`
- `this (diagram|chart|slide|screen|image)`
- `let me show you`
- `here we have`
- `on the screen`

### Output Structure

```
<scratchpad>/youtube-{video_id}/
├── transcript.srt          # SRT format with timestamps
├── frames/
│   ├── 00_01_23.jpg       # Frame at 1:23
│   ├── 00_05_47.jpg       # Frame at 5:47
│   └── ...
└── video.mp4              # Video (only if frames extracted)
```

### Skill Structure

```
skills/youtube-transcript/
├── SKILL.md               # Command skill definition
└── deps.json              # Dependencies specification
```

## Installer Integration

### deps.json Format

```json
{
  "dependencies": [
    {
      "name": "yt-dlp",
      "check": "command -v yt-dlp",
      "install": {
        "macos": "brew install yt-dlp",
        "debian": "apt-get install -y python3-pip && pip3 install --user yt-dlp",
        "arch": "pacman -S --noconfirm yt-dlp",
        "fedora": "dnf install -y python3-pip && pip3 install --user yt-dlp",
        "suse": "zypper install -y python3-pip && pip3 install --user yt-dlp"
      },
      "post_install_hint": "Add ~/.local/bin to PATH"
    },
    {
      "name": "ffmpeg",
      "check": "command -v ffmpeg",
      "install": {
        "macos": "brew install ffmpeg",
        "debian": "apt-get install -y ffmpeg",
        "arch": "pacman -S --noconfirm ffmpeg",
        "fedora": "dnf install -y ffmpeg",
        "suse": "zypper install -y ffmpeg"
      }
    }
  ]
}
```

### lib/skills.sh Extension

New function `install_skill_deps()`:
1. Check if `deps.json` exists in skill directory
2. For each dependency: check if installed, install if missing
3. Use platform-specific install command

New function `run_install_cmd()`:
1. If root, run command as-is
2. If not root, prepend `sudo` to package manager commands (apt-get, dnf, pacman, zypper)
3. Does NOT add sudo to pip/brew commands

### pip Handling

pip3 might need `--break-system-packages` on newer Debian/Ubuntu (PEP 668).
Solution: Use `pip3 install --user` to install in user directory.

## Implementation Plan

### Phase 1: Installer Integration
- [x] Create `deps.json` format
- [x] Add `install_skill_deps()` to lib/skills.sh
- [x] Add `run_install_cmd()` for smart sudo handling
- [x] Handle pip for yt-dlp (--user install)
- [x] Call from `install_skill()`

### Phase 2: Skill Content
- [x] SKILL.md with instructions for Claude
- [x] Test dependency installation on macOS
- [x] Test dependency installation on Linux (manual container test)

### Phase 3: Tests
- [x] Test scenario for skill installation (14-skill-dependencies.sh)
- [x] Test dependency detection (deps.json structure)
- [x] Test sudo handling logic
- [x] Test POSIX compatibility (no grep -oP)
- [ ] Test cross-platform (GitHub Actions matrix) - future

## Decisions

1. **Transcript source**: YouTube Auto-Transcription via yt-dlp (`--write-auto-sub`). Whisper only as fallback when no subtitles available.
2. **Frame extraction**: Automatic at visual references
3. **Video length**: No limit
4. **Output location**: Scratchpad (temporary, not project-specific)
5. **yt-dlp installation**: pip3 --user (avoids PEP 668 issues)
6. **deps.json**: Declarative dependencies per skill
7. **Video format**: Use explicit format ID (`-f 18`) instead of `-f worst` to avoid yt-dlp hanging

## Alternatives Considered

| Alternative | Rejected because |
|-------------|------------------|
| YouTube API directly | Requires API key, more complex |
| Browser extension | Not CLI-compatible |
| Transcript only without frames | Visual info lost |
| System pip install | PEP 668 issues on newer distros |
| Hardcoded deps in install.sh | Not scalable for more skills |

## References

- yt-dlp: https://github.com/yt-dlp/yt-dlp
- ffmpeg: https://ffmpeg.org/
- PEP 668: https://peps.python.org/pep-0668/
