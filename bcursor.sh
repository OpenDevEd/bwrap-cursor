#!/usr/bin/env bash
# bcursor — sandboxed Cursor with shared profile and project RW
# Usage:
#   bcursor                # opens $PWD
#   bcursor <dir>          # opens <dir>
#   bcursor <path/to/file> # opens parent dir, focuses file
#   bcursor <file1> <file2> <project> # opens multiple files/projects
#   bcursor --dryrun       # shows the command that would be executed

set -euo pipefail

# ---- resolve absolute path (works if either realpath or readlink -f exists) ----
resolve_abs() {
  if command -v realpath >/dev/null 2>&1; then
    realpath -m -- "$1"
  else
    readlink -f -- "$1"
  fi
}

# ---- parse args ----
DRYRUN=0
if [ "$#" -gt 0 ] && [ "$1" = "--dryrun" ]; then
  DRYRUN=1
  shift
fi

# Handle multiple arguments
if [ "$#" -eq 0 ]; then
  PROJECT_PATH="$(pwd)"
  CURSOR_TARGETS=("$PROJECT_PATH")
else
  # Use the first file/directory to determine the project path
  FIRST_ARG_ABS="$(resolve_abs "$1")"
  if [ -d "$FIRST_ARG_ABS" ]; then
    PROJECT_PATH="$FIRST_ARG_ABS"
  else
    PROJECT_PATH="$(dirname "$FIRST_ARG_ABS")"
  fi
  
  # All arguments become targets
  CURSOR_TARGETS=("$@")
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
  "$HOME/.cache/fontconfig" \
  "$HOME/.cache/com.vercel.cli"

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
  --bind "$HOME/.cache/com.vercel.cli" "$HOME/.cache/com.vercel.cli"

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
if [ "$DRYRUN" -eq 1 ]; then
  echo "bwrap \\"
  for arg in "${args[@]}"; do
    echo "  \"$arg\" \\"
  done
  for arg in "${env_args[@]}"; do
    echo "  \"$arg\" \\"
  done
  echo -n "  -- /usr/bin/cursor"
  for target in "${CURSOR_TARGETS[@]}"; do
    echo -n " \"$target\""
  done
  echo
else
  exec bwrap \
    "${args[@]}" \
    "${env_args[@]}" \
    -- /usr/bin/cursor "${CURSOR_TARGETS[@]}"
fi
