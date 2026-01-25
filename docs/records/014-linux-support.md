# Record 014: Linux Support

**Status:** Accepted
**Date:** 2026-01-25

## Context

Currently, claude-code-setup only supports macOS. The install script has a hard dependency on Homebrew (lines 646-649):

```bash
if ! command -v brew &> /dev/null; then
    print_error "Homebrew not found. Please install from https://brew.sh"
    exit 1
fi
```

This excludes:
- Linux users (Ubuntu, Debian, Arch, etc.)
- WSL (Windows Subsystem for Linux) users
- CI/CD environments running on Linux

## Problem

1. **Limited audience** - Many developers use Linux
2. **CI limitations** - GitHub Actions Linux runners are faster/cheaper than macOS
3. **Team diversity** - Teams with mixed OS cannot share the same setup

## Proposed Solution

### Phase 1: Package Manager Abstraction

Replace Homebrew-specific code with OS detection:

```bash
install_dependency() {
    local pkg=$1
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$pkg"
    elif command -v brew &>/dev/null; then
        brew install "$pkg"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "$pkg"
    else
        print_error "No supported package manager found"
        exit 1
    fi
}
```

### Phase 2: Dependency Review

Current dependencies:
| Dependency | macOS | Linux Alternative |
|------------|-------|-------------------|
| `jq` | `brew install jq` | `apt install jq` |
| `npx` | via Node.js | Same |

### Phase 3: Testing

- Add Linux runner to GitHub Actions
- Test on Ubuntu LTS (most common)
- Document any platform-specific behavior

## Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| Docker container | Works everywhere | Adds complexity, not native |
| Nix package | Reproducible | Learning curve, less common |
| Manual instructions | No code changes | Poor UX |

## Decision

Accepted. Implement together with lib/ refactoring (Record 015).

## Implementation Plan

### Scope

Linux support + lib/ refactoring (as per Record 015). The script is at 997 lines; adding Linux support inline would push it to ~1100 lines. Refactoring creates clean separation for platform-specific code.

### lib/ Structure

```
install.sh              # Main entry point (~120 lines)
lib/
├── helpers.sh          # Colors, printing, JSON utilities
├── modules.sh          # Module discovery, selection
├── mcp.sh              # MCP server installation
├── skills.sh           # Skill installation
├── statusline.sh       # ccstatusline configuration
├── update.sh           # Update logic
└── platform.sh         # OS detection, package manager [NEW]
```

### lib/platform.sh

```bash
# OS detection
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS_TYPE="macos"
            ;;
        Linux)
            OS_TYPE="linux"
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian) LINUX_DISTRO="debian" ;;
                    arch|manjaro) LINUX_DISTRO="arch" ;;
                    fedora|rhel|centos) LINUX_DISTRO="fedora" ;;
                    *) LINUX_DISTRO="unknown" ;;
                esac
            fi
            ;;
        *) print_error "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac
}

# Package manager abstraction
install_package() {
    local pkg=$1
    case "$OS_TYPE" in
        macos) brew install "$pkg" --quiet ;;
        linux)
            case "$LINUX_DISTRO" in
                debian) sudo apt-get install -y -qq "$pkg" ;;
                arch) sudo pacman -S --noconfirm "$pkg" ;;
                fedora) sudo dnf install -y "$pkg" ;;
                *) print_error "Install $pkg manually"; exit 1 ;;
            esac
            ;;
    esac
}
```

### CI Matrix (.github/workflows/test.yml)

```yaml
strategy:
  matrix:
    os: [macos-latest, ubuntu-22.04]
runs-on: ${{ matrix.os }}
```

### Supported Package Managers

| OS | Package Manager |
|----|-----------------|
| macOS | Homebrew |
| Ubuntu/Debian | apt-get |
| Arch/Manjaro | pacman |
| Fedora/RHEL | dnf |

### Implementation Order

1. Create lib/ directory
2. Extract helpers.sh, modules.sh, mcp.sh, skills.sh, statusline.sh, update.sh
3. Refactor install.sh to source lib/*.sh
4. Run tests (verify refactor works)
5. Create lib/platform.sh with detect_os(), install_package()
6. Integrate platform detection into do_install()
7. Update CI with Linux matrix
8. Test on Linux CI
9. Update README, Records, bump version

## Implementation Checklist

- [x] Add OS detection function
- [x] Abstract package manager calls
- [x] Add Linux CI runner
- [x] Test on Ubuntu 22.04 LTS
- [x] Update README with Linux instructions
- [x] Test WSL compatibility (via /proc/version detection)
