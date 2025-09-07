#!/usr/bin/env bash
# bcursor — full host FS read-only; sandbox $HOME=~/.cursor; project mounted at /home/app/work

set -euo pipefail

APP_HOME="${HOME}/.cursor"               # host dir used as sandbox HOME
WORKDIR="$(pwd)"                         # host project dir
UID_NUM="$(id -u)"
XDG_RT="${XDG_RUNTIME_DIR:-/run/user/${UID_NUM}}"

mkdir -p -- "$APP_HOME" "$XDG_RT"
chmod 700 "$XDG_RT" || true

# Pass-through session env
env_args=()
[[ -n "${DISPLAY:-}"         ]] && env_args+=( --setenv DISPLAY "$DISPLAY" )
[[ -n "${WAYLAND_DISPLAY:-}" ]] && env_args+=( --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" )
[[ -S "${XDG_RT}/bus"        ]] && env_args+=( --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=${XDG_RT}/bus" )
env_args+=( --setenv XDG_RUNTIME_DIR "$XDG_RT" )

args=(
  # Full host visible read-only (DNS, certs, libs intact)
  --ro-bind / /

  # Kernel/virtual FS
  --proc /proc
  --dev /dev

  # Writable scratch
  --tmpfs /tmp

  # Make XDG_RUNTIME_DIR writable
  --bind "$XDG_RT" "$XDG_RT"

  # Overlay /home and provide sandbox HOME = ~/.cursor
  --tmpfs /home
  --dir /home
  --bind "$APP_HOME" /home/app
  --setenv HOME /home/app

  # Create a mountpoint under the writable /home and bind project there
  --dir /home/app/work
  --bind "$WORKDIR" /home/app/work
  --chdir /home/app/work
)

# X11 socket dir (if using X11)
[[ -d /tmp/.X11-unix ]] && args+=( --ro-bind /tmp/.X11-unix /tmp/.X11-unix )

# Optional GPU passthrough
[[ -d /dev/dri ]] && args+=( --bind /dev/dri /dev/dri )
for n in /dev/nvidiactl /dev/nvidia0 /dev/nvidia-uvm /dev/nvidia-uvm-tools; do
  [[ -e "$n" ]] && args+=( --bind "$n" "$n" )
done

# Launch Cursor pointed at /home/app/work
exec bwrap \
  "${args[@]}" \
  "${env_args[@]}" \
  -- /usr/bin/cursor /home/app/work
