#!/bin/bash

# Platform detection and package manager abstraction
# Supports macOS (Homebrew) and Linux (apt, pacman, dnf, zypper)

# Global variables set by detect_os
OS_TYPE=""
LINUX_DISTRO=""
IS_WSL=false

# Detect Linux distribution by checking available package managers
# Used as fallback when /etc/os-release is missing or ID is unknown
detect_distro_by_package_manager() {
    if command -v apt-get &>/dev/null; then
        echo "debian"
    elif command -v pacman &>/dev/null; then
        echo "arch"
    elif command -v dnf &>/dev/null; then
        echo "fedora"
    elif command -v zypper &>/dev/null; then
        echo "suse"
    else
        echo "unknown"
    fi
}

# Detect operating system and distribution
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS_TYPE="macos"
            ;;
        Linux)
            OS_TYPE="linux"
            # Check for WSL
            if grep -qi microsoft /proc/version 2>/dev/null; then
                IS_WSL=true
            fi
            if [[ -f /etc/os-release ]]; then
                # shellcheck source=/dev/null
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian|pop|linuxmint|elementary|zorin)
                        LINUX_DISTRO="debian"
                        ;;
                    arch|manjaro|endeavouros|garuda)
                        LINUX_DISTRO="arch"
                        ;;
                    fedora|rhel|centos|rocky|alma)
                        LINUX_DISTRO="fedora"
                        ;;
                    opensuse*|sles)
                        LINUX_DISTRO="suse"
                        ;;
                    *)
                        # Unknown ID, fallback to package manager detection
                        LINUX_DISTRO=$(detect_distro_by_package_manager)
                        ;;
                esac
            else
                # No /etc/os-release, fallback to package manager detection
                LINUX_DISTRO=$(detect_distro_by_package_manager)
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            print_error "Native Windows is not supported"
            print_info "Please use WSL (Windows Subsystem for Linux)"
            print_info "Install WSL: https://learn.microsoft.com/windows/wsl/install"
            exit 1
            ;;
        *)
            print_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
}

# Check if sudo is available (required for Linux package installation)
check_sudo() {
    if [[ "$OS_TYPE" != "linux" ]]; then
        return 0
    fi

    # Already root, no sudo needed
    if [[ $EUID -eq 0 ]]; then
        return 0
    fi

    if ! command -v sudo &>/dev/null; then
        print_error "sudo is required for package installation"
        print_info "Install sudo or run as root"
        exit 1
    fi
}

# Check if package manager exists
# On macOS: Homebrew is optional (jq can be installed via binary download)
# On Linux: package manager is required
check_package_manager() {
    case "$OS_TYPE" in
        macos)
            # Homebrew is optional - we can download jq binary directly
            if ! command -v brew &>/dev/null; then
                print_info "Homebrew not found (optional)"
            fi
            ;;
        linux)
            # Check sudo first
            check_sudo

            case "$LINUX_DISTRO" in
                debian)
                    if ! command -v apt-get &>/dev/null; then
                        print_error "apt-get not found"
                        exit 1
                    fi
                    ;;
                arch)
                    if ! command -v pacman &>/dev/null; then
                        print_error "pacman not found"
                        exit 1
                    fi
                    ;;
                fedora)
                    if ! command -v dnf &>/dev/null; then
                        print_error "dnf not found"
                        exit 1
                    fi
                    ;;
                suse)
                    if ! command -v zypper &>/dev/null; then
                        print_error "zypper not found"
                        exit 1
                    fi
                    ;;
                unknown)
                    print_error "No supported package manager found"
                    print_info "Supported: apt, pacman, dnf, zypper"
                    exit 1
                    ;;
            esac
            ;;
    esac
}

# Check if a package is installed
is_package_installed() {
    local pkg=$1

    case "$OS_TYPE" in
        macos)
            brew list "$pkg" &>/dev/null
            ;;
        linux)
            case "$LINUX_DISTRO" in
                debian)
                    dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
                    ;;
                arch)
                    pacman -Q "$pkg" &>/dev/null
                    ;;
                fedora)
                    rpm -q "$pkg" &>/dev/null
                    ;;
                suse)
                    rpm -q "$pkg" &>/dev/null
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
    esac
}

# Install a package using the appropriate package manager
install_package() {
    local pkg=$1

    case "$OS_TYPE" in
        macos)
            if ! brew install "$pkg" --quiet; then
                print_error "Failed to install $pkg via Homebrew"
                exit 1
            fi
            ;;
        linux)
            case "$LINUX_DISTRO" in
                debian)
                    if ! sudo apt-get install -y -qq "$pkg"; then
                        print_error "Failed to install $pkg via apt"
                        exit 1
                    fi
                    ;;
                arch)
                    if ! sudo pacman -S --noconfirm --quiet "$pkg"; then
                        print_error "Failed to install $pkg via pacman"
                        exit 1
                    fi
                    ;;
                fedora)
                    if ! sudo dnf install -y -q "$pkg"; then
                        print_error "Failed to install $pkg via dnf"
                        exit 1
                    fi
                    ;;
                suse)
                    if ! sudo zypper install -y -q "$pkg"; then
                        print_error "Failed to install $pkg via zypper"
                        exit 1
                    fi
                    ;;
                *)
                    print_error "Cannot install $pkg: unsupported distribution"
                    print_info "Please install $pkg manually and re-run the installer"
                    exit 1
                    ;;
            esac
            ;;
    esac
}

# Get package manager name for display
get_package_manager_name() {
    case "$OS_TYPE" in
        macos)
            echo "Homebrew"
            ;;
        linux)
            case "$LINUX_DISTRO" in
                debian) echo "apt" ;;
                arch) echo "pacman" ;;
                fedora) echo "dnf" ;;
                suse) echo "zypper" ;;
                *) echo "unknown" ;;
            esac
            ;;
    esac
}

# Download jq binary directly (macOS fallback when no Homebrew)
install_jq_binary() {
    local arch
    local url
    local install_dir="$HOME/.local/bin"

    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        url="https://github.com/jqlang/jq/releases/latest/download/jq-macos-arm64"
    else
        url="https://github.com/jqlang/jq/releases/latest/download/jq-macos-amd64"
    fi

    mkdir -p "$install_dir"

    if ! curl -fsSL "$url" -o "$install_dir/jq"; then
        print_error "Failed to download jq"
        return 1
    fi

    chmod +x "$install_dir/jq"

    # Add to PATH for current session
    export PATH="$install_dir:$PATH"

    # Check if ~/.local/bin is in PATH permanently
    if ! echo "$PATH" | grep -q "$install_dir"; then
        echo ""
        print_warning "Add ~/.local/bin to your PATH for future sessions:"
        print_info "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
    fi

    return 0
}

# Install jq with cascade logic (macOS)
# 1. Check if jq exists -> done
# 2. If brew exists -> brew install jq
# 3. Fallback -> download binary
install_jq() {
    # Already installed?
    if command -v jq &>/dev/null; then
        print_info "jq (found)"
        return 0
    fi

    case "$OS_TYPE" in
        macos)
            if command -v brew &>/dev/null; then
                echo "  + jq (installing via Homebrew...)"
                if ! brew install jq --quiet; then
                    print_error "Failed to install jq via Homebrew"
                    exit 1
                fi
            else
                echo "  + jq (downloading binary...)"
                if ! install_jq_binary; then
                    print_error "Failed to install jq"
                    print_info "Install manually: https://jqlang.github.io/jq/download/"
                    exit 1
                fi
            fi
            ;;
        linux)
            echo "  + jq (installing via $(get_package_manager_name)...)"
            install_package jq
            ;;
    esac

    print_success "jq installed"
}

# Get OS display name
get_os_display_name() {
    local name=""
    case "$OS_TYPE" in
        macos)
            name="macOS"
            ;;
        linux)
            if [[ -f /etc/os-release ]]; then
                # shellcheck source=/dev/null
                . /etc/os-release
                name="${PRETTY_NAME:-Linux}"
            else
                name="Linux"
            fi
            # Append WSL indicator
            if [[ "$IS_WSL" = true ]]; then
                name="$name (WSL)"
            fi
            ;;
        *)
            name="$(uname -s)"
            ;;
    esac
    echo "$name"
}
