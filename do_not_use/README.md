# Firejail Implementation (Abandoned)

This directory contains an abandoned attempt to use Firejail for sandboxing Cursor.

## Why Firejail was abandoned

I started with `firejail` but encountered several issues that made it less suitable for this use case:

1. **Complex Networking Configuration:** Firejail requires extensive whitelisting of DNS resolution files and system directories. The implementation in `firejail_cursor` shows the complexity needed just to get basic networking working.

2. **Maintenance Overhead:** The long list of whitelisted directories (`/etc/nsswitch.conf`, `/etc/hosts`, `/etc/resolv.conf`, `/run/systemd/resolve/*`, etc.) makes the configuration fragile and system-specific (though this is the same with bwrap).

3. **Less Reliable:** Even with extensive whitelisting, networking could still fail on different distributions or system configurations.

4. **Security Model:** Firejail's whitelist-based approach is more permissive by default, requiring explicit blocking of everything you don't want, whereas bwrap's approach is more restrictive by default.

## Previous Attempts

Before settling on the current bwrap approach, several other methods were tried:

1. **AppImage with --appimage:** Initially tried using Cursor's AppImage with the `--appimage` flag, but this proved similarly difficult to sandbox properly while maintaining networking functionality.

2. **Debian Package (.deb):** After Cursor released a .deb package, this was also attempted, but encountered the same networking challenges as the AppImage approach.

## Common Networking Issue

In the experimentation with both firejail and bwrap, when the directories are too restrictive, networking stops working, presumably because essential files for DNS resolution can no longer be found. This is a fundamental challenge when trying to balance security isolation with functional networking capabilities.

The bwrap approach ultimately proved simpler, more reliable, and provides better security isolation with less configuration complexity.

## Files in this directory

- `firejail_cursor`: The abandoned Firejail implementation script
- `README.md`: This file explaining why Firejail was abandoned