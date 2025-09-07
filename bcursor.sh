#!/usr/bin/env bash
# bcursor — sandboxed Cursor with shared profile and project RW
# Usage:
#   bcursor                # opens $PWD
#   bcursor <dir>          # opens <dir>
#   bcursor <path/to/file> # opens parent dir, focuses file

set -euo pipefail

# ---- resolve absolute path (works if either realpath or readlink -f exists) ----
resolve_abs() {
  if command -v realpath >/dev/null 2>&1; then
    realpath -m -- "$1"
  else
    readlink -f -- "$1"
  fi
}

# ---- parse arg (0 or 1 allowed) ----
if [ "$#" -gt 1 ]; then
  echo "bcursor: expected 0 or 1 argument (project dir or file). Got $#." >&2
  exit 2
fi

if [ "$#" -eq 0 ]; then
  PROJECT_PATH="$(pwd)"
  CURSOR_TARGET="$PROJECT_PATH"
else
  ARG_ABS="$(resolve_abs "$1")"
  if [ -d "$ARG_ABS" ]; then
    PROJECT_PATH="$ARG_ABS"
    CURSOR_TARGET="$ARG_ABS"
  else
    PROJECT_PATH="$(dirname "$ARG_ABS")"
    CURSOR_TARGET="$ARG_ABS"
  fi
fi

# ---- (add this after the argument parsing block) ----
# SECURITY CHECK: Ensure the project path is not a root-level directory.
PROJECT_ABS="$(resolve_abs "$PROJECT_PATH")"
if [[ "$PROJECT_ABS" == "/" || "$PROJECT_ABS" == "/usr" || "$PROJECT_ABS" == "/etc" || "$PROJECT_ABS" == "$HOME" ]]; then
  echo "bcursor: error: selecting a high-level system or home directory ('$PROJECT_ABS') is not allowed." >&2
  exit 1
fi

# ---- runtime / env setup ----
UID_NUM="$(id -u)"
XDG_RT="${XDG_RUNTIME_DIR:-/run/user/${UID_NUM}}"

mkdir -p -- "$XDG_RT"
chmod 700 "$XDG_RT" || true

# Cursor dirs (shared with non-sandboxed Cursor)
mkdir -p -- \
  "$HOME/.config/Cursor" \
  "$HOME/.cache/Cursor" \
  "$HOME/.local/share/Cursor" \
  "$HOME/.local/state/Cursor" \
  "$HOME/.cache/fontconfig"

# Session env passthrough
env_args=()
[ -n "${DISPLAY:-}" ]         && env_args+=( --setenv DISPLAY "$DISPLAY" )
[ -n "${WAYLAND_DISPLAY:-}" ] && env_args+=( --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" )
[ -S "${XDG_RT}/bus" ]        && env_args+=( --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=${XDG_RT}/bus" )
env_args+=( --setenv XDG_RUNTIME_DIR "$XDG_RT" )

# ---- bwrap args ----
args=(
  # Show entire host read-only
  --ro-bind / /

  # Kernel/virtual FS
  --proc /proc
  --dev /dev

  # Writable scratch
  --tmpfs /tmp

  # Writable spots (minimal):
  --bind "$XDG_RT" "$XDG_RT"
  --bind "$PROJECT_PATH" "$PROJECT_PATH"
  --bind "$HOME/.config/Cursor" "$HOME/.config/Cursor"
  --bind "$HOME/.cache/Cursor" "$HOME/.cache/Cursor"
  --bind "$HOME/.local/share/Cursor" "$HOME/.local/share/Cursor"
  --bind "$HOME/.local/state/Cursor" "$HOME/.local/state/Cursor"
  --bind "$HOME/.cache/fontconfig" "$HOME/.cache/fontconfig"

  --chdir "$PROJECT_PATH"
)

# X11 socket (if present)
[ -d /tmp/.X11-unix ] && args+=( --ro-bind /tmp/.X11-unix /tmp/.X11-unix )

# Optional GPU passthrough
[ -d /dev/dri ] && args+=( --bind /dev/dri /dev/dri )
for n in /dev/nvidiactl /dev/nvidia0 /dev/nvidia-uvm /dev/nvidia-uvm-tools; do
  [ -e "$n" ] && args+=( --bind "$n" "$n" )
done

# ---- run Cursor ----
exec bwrap \
  "${args[@]}" \
  "${env_args[@]}" \
  -- /usr/bin/cursor "$CURSOR_TARGET"
