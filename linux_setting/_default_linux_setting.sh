#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Development Environment Setup Script for Rocky Linux
# ==============================================================================
# This script installs and configures:
# - System updates and essential tools (git, curl, lsof)
# - NVM (Node Version Manager) and Node.js v20
# - Package managers (pnpm, gitmoji-cli)
# - AI CLI tools (Claude, Codex, Gemini)
# - uv (Python package manager)
# - OpenJDK 21
# - Custom bash aliases
# ==============================================================================

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

print_header() {
  echo ""
  echo "============================================================"
  echo "  $1"
  echo "============================================================"
}

print_step() {
  echo ""
  echo ">>> $1"
}

print_success() {
  echo "✓ $1"
}

print_warning() {
  echo "✗ WARNING: $1"
}

print_error() {
  echo "✗ ERROR: $1"
}

# ------------------------------------------------------------------------------
# System Prerequisites
# ------------------------------------------------------------------------------

print_header "SYSTEM PREREQUISITES"

print_step "Checking DNF availability"
if ! command -v dnf >/dev/null 2>&1; then
  print_error "dnf command not found. Please run on Rocky Linux."
  exit 1
fi
print_success "DNF is available"

print_step "Determining DNF command (sudo or root)"
if [ "$(id -u)" -ne 0 ]; then
  DNF="sudo dnf"
  print_success "Using: sudo dnf"
else
  DNF="dnf"
  print_success "Using: dnf (running as root)"
fi

print_step "Updating system packages"
$DNF -y update
print_success "System packages updated"

print_step "Installing Git"
$DNF -y install git
print_success "Git installed"

print_step "Ensuring curl is available"
if ! command -v curl >/dev/null 2>&1; then
  $DNF -y install curl
  print_success "curl installed"
else
  print_success "curl already available"
fi

print_step "Installing lsof (List open files utility)"
$DNF -y install lsof
print_success "lsof installed"

# ------------------------------------------------------------------------------
# Node.js Environment (NVM + Node v20)
# ------------------------------------------------------------------------------

print_header "NODE.JS ENVIRONMENT"

print_step "Installing NVM (Node Version Manager)"
NVM_VERSION="v0.40.3"
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

print_step "Loading NVM into current shell"
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
  print_success "NVM loaded successfully. Version: $(nvm --version)"

  print_step "Installing Node.js v20"
  nvm install 20
  nvm use 20
  nvm alias default 20
  print_success "Node.js v20 installed and set as default"

  print_step "Verifying Node.js installation"
  if command -v node >/dev/null 2>&1; then
    print_success "Node.js Version: $(node --version)"
    print_success "npm Version: $(npm --version)"
  else
    print_warning "Node.js not found in PATH"
  fi

  print_step "Installing pnpm (Fast, disk space efficient package manager)"
  if npm install -g pnpm; then
    if command -v pnpm >/dev/null 2>&1; then
      print_success "pnpm installed. Version: $(pnpm --version)"
    else
      print_warning "pnpm installed but command not found in PATH"
    fi
  else
    print_error "Failed to install pnpm"
  fi

  print_step "Installing gitmoji-cli (Emoji guide for commit messages)"
  if npm install -g gitmoji-cli; then
    if command -v gitmoji >/dev/null 2>&1; then
      print_success "gitmoji-cli installed. Version: $(gitmoji --version 2>/dev/null || echo 'installed')"
    else
      print_warning "gitmoji-cli installed but command not found in PATH"
    fi
  else
    print_error "Failed to install gitmoji-cli"
  fi

  # --------------------------------------------------------------------------
  # AI CLI Tools Installation
  # --------------------------------------------------------------------------

  print_header "AI CLI TOOLS"

  # Claude CLI
  print_step "Installing Claude CLI (@anthropic-ai/claude-code)"
  if npm install -g @anthropic-ai/claude-code; then
    if command -v claude >/dev/null 2>&1; then
      print_success "Claude CLI installed. Version: $(claude --version 2>/dev/null || echo 'installed')"
    else
      print_warning "Claude CLI installed but command not found in PATH"
    fi
  else
    print_error "Failed to install Claude CLI"
  fi

  # Codex CLI
  print_step "Installing Codex CLI (@openai/codex)"
  if npm install -g @openai/codex; then
    if command -v codex >/dev/null 2>&1; then
      print_success "Codex CLI installed. Version: $(codex --version 2>/dev/null || echo 'installed')"
    else
      print_warning "Codex CLI installed but command not found in PATH"
    fi
  else
    print_error "Failed to install Codex CLI"
  fi

  # Gemini CLI
  print_step "Installing Gemini CLI (@google/gemini-cli)"
  if npm install -g @google/gemini-cli; then
    if command -v gemini >/dev/null 2>&1; then
      print_success "Gemini CLI installed. Version: $(gemini --version 2>/dev/null || echo 'installed')"
    else
      print_warning "Gemini CLI installed but command not found in PATH"
    fi
  else
    print_error "Failed to install Gemini CLI"
  fi

  print_success "AI CLI tools installation complete"

else
  print_warning "nvm.sh not found in $NVM_DIR - Node.js installation skipped"
fi

# ------------------------------------------------------------------------------
# Python Environment (uv)
# ------------------------------------------------------------------------------

print_header "PYTHON ENVIRONMENT"

print_step "Installing uv (Python package manager)"
if command -v curl >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
elif command -v wget >/dev/null 2>&1; then
  wget -qO- https://astral.sh/uv/install.sh | sh
else
  $DNF -y install curl
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

print_step "Loading uv into current shell"
export PATH="$HOME/.local/bin:$PATH"

if command -v uv >/dev/null 2>&1; then
  print_success "uv installed. Version: $(uv --version)"

  print_step "Installing Python 3.13 via uv"
  uv python install 3.13
  print_success "Python 3.13 installed via uv"

  print_step "Verifying Python installation"
  if uv python list | grep -q "3.13"; then
    PYTHON_VERSION=$(uv python list | grep "3.13" | head -n 1 | awk '{print $2}')
    print_success "Python 3.13 available: $PYTHON_VERSION"
  else
    print_warning "Python 3.13 installation verification failed"
  fi
else
  print_warning "uv not found in PATH: $PATH"
fi

# ------------------------------------------------------------------------------
# Java Development Kit
# ------------------------------------------------------------------------------

print_header "JAVA DEVELOPMENT KIT"

print_step "Installing OpenJDK 21"
$DNF -y install java-21-openjdk
print_success "OpenJDK 21 installed"

# ------------------------------------------------------------------------------
# Claude MCP Server Configuration
# ------------------------------------------------------------------------------

print_header "CLAUDE MCP SERVERS"

# Check if claude command is available
if command -v claude >/dev/null 2>&1; then

  # Sequential Thinking MCP Server
  print_step "Adding Sequential Thinking MCP server"
  if claude mcp add --scope user sequential-thinking npx @modelcontextprotocol/server-sequential-thinking; then
    print_success "Sequential Thinking MCP server added"
  else
    print_warning "Failed to add Sequential Thinking MCP server"
  fi

  # Gemini CLI MCP Server
  print_step "Adding Gemini CLI MCP server"
  if claude mcp add gemini-cli -- npx -y gemini-mcp-tool; then
    print_success "Gemini CLI MCP server added"
  else
    print_warning "Failed to add Gemini CLI MCP server"
  fi

  # Codex CLI MCP Server
  print_step "Adding Codex CLI MCP server"
  if claude mcp add codex-cli-mcp-tool -- npx -y codex-cli-mcp-tool; then
    print_success "Codex CLI MCP server added"
  else
    print_warning "Failed to add Codex CLI MCP server"
  fi

  # Context7 MCP Server (HTTP Transport)
  print_step "Adding Context7 MCP server"
  if claude mcp add --transport http context7 "https://mcp.context7.com/mcp"; then
    print_success "Context7 MCP server added"
  else
    print_warning "Failed to add Context7 MCP server"
  fi

  # Chrome DevTools MCP Server
  print_step "Adding Chrome DevTools MCP server"
  if claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp; then
    print_success "Chrome DevTools MCP server added"
  else
    print_warning "Failed to add Chrome DevTools MCP server"
  fi

  print_success "Claude MCP servers configuration complete"

else
  print_warning "Claude CLI not found - skipping MCP server configuration"
  print_warning "Install Claude CLI first, then run MCP setup manually"
fi

# ------------------------------------------------------------------------------
# Shell Configuration
# ------------------------------------------------------------------------------

print_header "SHELL CONFIGURATION"

print_step "Configuring .bashrc aliases"
BASHRC="$HOME/.bashrc"

if ! grep -q "alias ll=" "$BASHRC" 2>/dev/null; then
  {
    echo ""
    echo "# Custom aliases"
    echo "alias ll='ls -al'"
  } >> "$BASHRC"
  print_success "Added 'll' alias to $BASHRC"
else
  print_success "'ll' alias already exists in $BASHRC"
fi

# ------------------------------------------------------------------------------
# Setup Complete
# ------------------------------------------------------------------------------

print_header "SETUP COMPLETE"
echo ""
echo "All installations completed successfully!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc"
echo "  2. Verify installations:"
echo "     - node --version"
echo "     - npm --version"
echo "     - pnpm --version"
echo "     - gitmoji --version"
echo "     - claude --version"
echo "     - codex --version"
echo "     - gemini --version"
echo "     - uv --version"
echo "     - uv python list"
echo "     - java --version"
echo ""
echo "  3. Verify Claude MCP servers:"
echo "     - claude mcp list"
echo ""
echo "  4. To use Python 3.13 with uv:"
echo "     - uv run --python 3.13 python --version"
echo "     - uv venv --python 3.13"
echo ""
echo "MCP Servers Configured:"
echo "  - sequential-thinking: Advanced reasoning and problem-solving"
echo "  - gemini-cli: Google Gemini AI integration"
echo "  - codex-cli-mcp-tool: OpenAI Codex integration"
echo "  - context7: Up-to-date library documentation"
echo "  - chrome-devtools: Browser automation and testing"
echo ""
