# Deployment & Usage — device-fingerprint

This document describes how to deploy, test and roll back the device-fingerprint randomization service included in this repository.

Files added/changed by this feature
- files/etc/init.d/device-fingerprint  (main init script)
- files/etc/hotplug.d/iface/99-fingerprint (hotplug hook to run after wireless ifup)
- Scripts/Install-Fingerprint.sh (copies both files into firmware files during packaging)

Purpose
- Ensure the router's device fingerprint (SSID, MAC, hostname, IPv6 behavior) is randomized for privacy while preserving the WiFi password if it already exists on the device. A strong password is only generated if the device has no wireless key configured (first-boot scenario).

How it is installed into the firmware
1. The packaging script will copy files from files/ into the firmware overlay under wrt/files during CI/build:
   - Scripts/Install-Fingerprint.sh handles installation and sets executable bits for the init and hotplug scripts.

Runtime behavior
- On first run (no wireless key configured):
  - The init script generates a 16-character strong password (includes upper/lower/digits/special), sets SSIDs, MACs, hostname, and writes the key into UCI (persisted in /etc/config/wireless).
- On subsequent reboots: 
  - If wireless.<iface>.key exists and is non-empty, the script preserves it (does not overwrite).
  - SSID, MAC, hostname randomization and IPv6 adjustments still occur as configured; hotplug hook ensures changes re-apply after wireless device comes up.

How to enable & test on device
1. SSH into device.
2. Enable the service and run it once:
   - /etc/init.d/device-fingerprint enable
   - /etc/init.d/device-fingerprint start
3. Confirm logs (system log):
   - logread | grep -i fingerprint -n
4. Verify wireless UCI settings:
   - uci show wireless
   - To check key for first wireless iface: uci get wireless.@wifi-iface[0].key

Reboot test
1. Record pre-reboot key:
   - KPRE=$(uci get wireless.@wifi-iface[0].key)
2. Reboot the device: reboot
3. After device comes back up, check again:
   - KPOST=$(uci get wireless.@wifi-iface[0].key)
4. Both should match (if KPRE was non-empty), otherwise a new key will only be created if there was none before.

Cleaning fingerprint cache files
- To reduce sensitive data residing in /tmp, the script will remove fingerprint cache files older than 24 hours during its cleaning routine. The cache files created during runtime are limited to /tmp/.fingerprint_cache.* with permissions 600.

Rollback / recovery
- The script performs a backup of /etc/config into /etc/config.backup before making changes.
- If critical operations (for example, `uci commit wireless`) fail repeatedly, the script will call restore_config() to attempt to revert to the backup.
- Manual rollback steps:
  1. scp or open a shell to device
  2. Stop the service: /etc/init.d/device-fingerprint stop
  3. If you need to restore previous config: cp -r /etc/config.backup/* /etc/config/ && uci commit

Security notes
- Passwords are never logged in plaintext to syslog; they are temporarily written to /tmp/.fingerprint_cache.<iface> with mode 600 for debugging and are removed by cleanup after 24 hours.
- The script attempts to avoid writing to global /tmp indiscriminately and leaves runtime-critical sockets and files intact.

Notes for maintainers
- This feature is intended for use in your own fork or private builds and is not intended to be upstreamed without review of platform-specific driver behaviors.
- Some platforms (closed-source drivers or vendor init scripts) might still override wireless settings during boot; ensure the hotplug hook or rc.local delay is compatible with your target image.
