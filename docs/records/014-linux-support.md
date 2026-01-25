# Record 014: Linux Support

**Status:** Proposed
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

Deferred to post v1.0.0. Track in Future todos.

## Implementation Checklist

- [ ] Add OS detection function
- [ ] Abstract package manager calls
- [ ] Add Linux CI runner
- [ ] Test on Ubuntu 22.04 LTS
- [ ] Update README with Linux instructions
- [ ] Test WSL compatibility
