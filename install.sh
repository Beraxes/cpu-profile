#!/usr/bin/env bash
#
# Installer for cpu-profile and game-pin
#

set -e

INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$1" = "--uninstall" ]; then
    echo "Uninstalling cpu-profile and game-pin from ${INSTALL_DIR}..."
    rm -f "${INSTALL_DIR}/cpu-profile"
    rm -f "${INSTALL_DIR}/game-pin"
    echo "Uninstalled successfully."
    exit 0
fi

echo "==> Installing cpu-profile & game-pin..."

mkdir -p "${INSTALL_DIR}"

install -m 755 "${SCRIPT_DIR}/bin/cpu-profile" "${INSTALL_DIR}/cpu-profile"
ln -sf "cpu-profile" "${INSTALL_DIR}/game-pin"

echo "==> Installed to ${INSTALL_DIR}:"
echo "  ✓ ${INSTALL_DIR}/cpu-profile"
echo "  ✓ ${INSTALL_DIR}/game-pin -> cpu-profile"

# Check if INSTALL_DIR is in PATH
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
    echo ""
    echo "⚠️  Note: ${INSTALL_DIR} is not in your current \$PATH."
    echo "   Add it to your shell config (~/.bashrc or ~/.zshrc):"
    echo "   export PATH=\"\${HOME}/.local/bin:\$PATH\""
fi

echo ""
echo "Installation complete! Try running:"
echo "  cpu-profile"
echo "  cpu-profile status"
