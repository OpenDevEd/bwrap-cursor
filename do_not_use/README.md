# Firejail Implementation (Abandoned)

This directory contains an abandoned attempt to use Firejail for sandboxing Cursor.

## Why Firejail was abandoned

I started with `firejail` but encountered several issues that made it less suitable for this use case:

1. **Complex Networking Configuration:** Firejail requires extensive whitelisting of DNS resolution files and system directories. The implementation in `firejail_cursor` shows the complexity needed just to get basic networking working.

2. **Maintenance Overhead:** The long list of whitelisted directories (`/etc/nsswitch.conf`, `/etc/hosts`, `/etc/resolv.conf`, `/run/systemd/resolve/*`, etc.) makes the configuration fragile and system-specific.

3. **Less Reliable:** Even with extensive whitelisting, networking could still fail on different distributions or system configurations.

4. **Security Model:** Firejail's whitelist-based approach is more permissive by default, requiring explicit blocking of everything you don't want, whereas bwrap's approach is more restrictive by default.

The bwrap approach is simpler, more reliable, and provides better security isolation with less configuration complexity.

## Files in this directory

- `firejail_cursor`: The abandoned Firejail implementation script
- `README.md`: This file explaining why Firejail was abandoned