#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 SimplexY-tech
# Install device fingerprint randomization service into firmware

PKG_DIR="$GITHUB_WORKSPACE/wrt/files"

# Create directory structure
mkdir -p "$PKG_DIR/etc/init.d"
mkdir -p "$PKG_DIR/etc/hotplug.d/iface"

# Copy the fingerprint randomization script
if [ -f "$GITHUB_WORKSPACE/files/etc/init.d/device-fingerprint" ]; then
    cp "$GITHUB_WORKSPACE/files/etc/init.d/device-fingerprint" "$PKG_DIR/etc/init.d/"
    chmod +x "$PKG_DIR/etc/init.d/device-fingerprint"
    echo "✓ Device fingerprint service installed to $PKG_DIR/etc/init.d"
else
    echo "✗ Device fingerprint service file not found!"
    exit 1
fi

# Copy hotplug hook if present
if [ -f "$GITHUB_WORKSPACE/files/etc/hotplug.d/iface/99-fingerprint" ]; then
    cp "$GITHUB_WORKSPACE/files/etc/hotplug.d/iface/99-fingerprint" "$PKG_DIR/etc/hotplug.d/iface/"
    chmod +x "$PKG_DIR/etc/hotplug.d/iface/99-fingerprint"
    echo "✓ Hotplug hook installed to $PKG_DIR/etc/hotplug.d/iface"
fi

# Ensure it has proper permissions in the compiled firmware
find "$PKG_DIR/etc/init.d" -type f -exec chmod 755 {} \;
find "$PKG_DIR/etc/hotplug.d/iface" -type f -exec chmod 755 {} \; || true

echo "Device fingerprint initialization complete!"
