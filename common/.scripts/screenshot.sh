#!/bin/bash
USAGE_MESSAGE="usage: $0 [--region | --monitor | --full | --window | --device | --devmon | --install]"

install_packages() {
  local -A PKG
  PKG[grim]=grim
  PKG[slurp]=slurp
  PKG[jq]=jq
  PKG[v4l2-ctl]=v4l-utils
  PKG[wl-copy]=wl-clipboard
  PKG[magick]=imagemagick
  PKG[hyprpicker]=hyprpicker

  local missing=()
  for cmd in "${!PKG[@]}"; do
    command -v "$cmd" &>/dev/null || missing+=("${PKG[$cmd]}")
  done

  if [ ${#missing[@]} -eq 0 ]; then
    echo "all packages are already installed."
    return 0
  fi

  echo "packages to install: ${missing[*]}"
  sudo pacman -S --needed -- "${missing[@]}"
}

check_deps() {
  for cmd in grim slurp jq v4l2-ctl wl-copy magick hyprpicker; do
    command -v "$cmd" &>/dev/null || { echo "error: '$cmd' is not installed." >&2; exit 1; }
  done
}

copy() { wl-copy -t image/png; echo "screenshot of $1 copied to clipboard (image/png)."; }

pick_device() {
  local devices choice
  devices=$(v4l2-ctl --list-devices | awk '/\(/ {name=$0; getline; print name " (" $1 ")"}' | sed 's/\t//g')
  [ -n "$devices" ] || { echo "no devices found." >&2; return 1; }
  choice=$(echo "$devices" | vicinae dmenu --placeholder "Select device...")
  [ -n "$choice" ] || return 1
  echo "$choice" | grep -o '/dev/video[0-9]\+'
}

capture_device() {
  v4l2-ctl --device "$1" \
    --set-fmt-video=width=1920,height=1080,pixelformat=MJPG \
    --stream-mmap --stream-to=- --stream-count=1
}

case "$1" in
  --install)
    install_packages
    ;;
  --region)
    hyprpicker -rzq & FREEZE_PID=$!
    trap 'kill "$FREEZE_PID" 2>/dev/null' EXIT
    sleep 0.01
    GEOMETRY=$(slurp) || exit 1
    grim -g "$GEOMETRY" - | copy "selected area"
    ;;
  --monitor)
    MONITOR_NAME=$(hyprctl activeworkspace -j | jq -r '.monitor')
    grim -o "$MONITOR_NAME" - | copy "monitor ($MONITOR_NAME)"
    ;;
  --full)
    grim - | copy "all monitors"
    ;;
  --window)
    WINDOW_INFO=$(hyprctl activewindow -j)
    [ -n "$WINDOW_INFO" ] || { echo "could not get active window information using hyprctl." >&2; exit 1; }
    GEOMETRY=$(echo "$WINDOW_INFO" | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    WINDOW_CLASS=$(echo "$WINDOW_INFO" | jq -r '.class')
    grim -g "$GEOMETRY" - | copy "active window ($WINDOW_CLASS)"
    ;;
  --device)
    TARGET_DEVICE=$(pick_device) || exit 1
    capture_device "$TARGET_DEVICE" | copy "device ($TARGET_DEVICE)"
    ;;
  --devmon)
    TARGET_DEVICE=$(pick_device) || exit 1
    MONITOR_CHOICE=$(hyprctl monitors -j | jq -r '.[].name' | vicinae dmenu --placeholder "Select monitor...")
    [ -n "$MONITOR_CHOICE" ] || exit 1
    MON_CAP=$(mktemp --suffix=.png)
    trap 'rm -f "$MON_CAP"' EXIT
    grim -o "$MONITOR_CHOICE" "$MON_CAP"
    capture_device "$TARGET_DEVICE" | magick "$MON_CAP" - +append png:- | copy "device + monitor ($MONITOR_CHOICE)"
    ;;
  "")
    echo "missing required argument." >&2
    echo "$USAGE_MESSAGE" >&2
    exit 1
    ;;
  *)
    echo "unknown option '$1'." >&2
    echo "$USAGE_MESSAGE" >&2
    exit 1
    ;;
esac
