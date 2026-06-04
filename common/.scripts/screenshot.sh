#!/bin/bash

for cmd in grim slurp jq v4l2-ctl wl-copy magick hyprpicker; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "error: '$cmd' is not installed." >&2
    exit 1
  fi
done

trap '[[ -n "$FREEZE_PID" ]] && kill "$FREEZE_PID" 2>/dev/null' EXIT

USAGE_MESSAGE="usage: $0 [--region | --monitor | --full | --window | --device | --devmon]"

case "$1" in
  --region)
    hyprpicker -rzq &
    FREEZE_PID=$!
    sleep 0.01

    if ! GEOMETRY=$(slurp); then
      exit 1
    fi

    if [ -n "$FREEZE_PID" ]; then
      kill "$FREEZE_PID" 2>/dev/null
      unset FREEZE_PID
    fi

    grim -g "$GEOMETRY" - | wl-copy

    echo "screenshot of selected area copied to clipboard (image/png)."
    ;;
  --monitor)
    MONITOR_NAME=$(hyprctl activeworkspace -j | jq -r '.monitor')

    grim -o "$MONITOR_NAME" - | wl-copy

    echo "screenshot of monitor ($MONITOR_NAME) copied to clipboard (image/png)."
    ;;
  --full)
    grim - | wl-copy

    echo "screenshot of all monitors copied to clipboard (image/png)."
    ;;
  --window)
    WINDOW_INFO=$(hyprctl activewindow -j)

    if [ -z "$WINDOW_INFO" ]; then
      echo "could not get active window information using hyprctl." >&2
      exit 1
    fi

    X=$(echo "$WINDOW_INFO" | jq -r '.at[0]')
    Y=$(echo "$WINDOW_INFO" | jq -r '.at[1]')
    W=$(echo "$WINDOW_INFO" | jq -r '.size[0]')
    H=$(echo "$WINDOW_INFO" | jq -r '.size[1]')

    GEOMETRY="${X},${Y} ${W}x${H}"

    grim -g "$GEOMETRY" - | wl-copy

    WINDOW_CLASS=$(echo "$WINDOW_INFO" | jq -r '.class')
    echo "screenshot of active window ($WINDOW_CLASS) copied to clipboard (image/png)."
    ;;
  --device)
    DEVICES=$(v4l2-ctl --list-devices | awk '/\(/ {name=$0; getline; print name " (" $1 ")"}' | sed 's/\t//g')

    if [ -z "$DEVICES" ]; then
      echo "no devices found." >&2
      exit 1
    fi

    CHOICE=$(echo "$DEVICES" | vicinae dmenu --placeholder "Select device...")

    if [ -z "$CHOICE" ]; then
      exit 1
    fi

    TARGET_DEVICE=$(echo "$CHOICE" | grep -o '/dev/video[0-9]\+')

    v4l2-ctl --device "$TARGET_DEVICE" \
        --set-fmt-video=width=1920,height=1080,pixelformat=MJPG \
        --stream-mmap --stream-to=- --stream-count=1 \
        | wl-copy -t image/png

    echo "screenshot of device ($TARGET_DEVICE) copied to clipboard (image/png)."
    ;;
  --devmon)
    DEVICES=$(v4l2-ctl --list-devices | awk '/\(/ {name=$0; getline; print name " (" $1 ")"}' | sed 's/\t//g')

    if [ -z "$DEVICES" ]; then
      echo "no devices found." >&2
      exit 1
    fi

    DEVICE_CHOICE=$(echo "$DEVICES" | vicinae dmenu --placeholder "Select device...")
    if [ -z "$DEVICE_CHOICE" ]; then
      exit 1
    fi

    TARGET_DEVICE=$(echo "$DEVICE_CHOICE" | grep -o '/dev/video[0-9]\+')

    MONITORS=$(hyprctl monitors -j | jq -r '.[].name')
    MONITOR_CHOICE=$(echo "$MONITORS" | vicinae dmenu --placeholder "Select monitor...")
    if [ -z "$MONITOR_CHOICE" ]; then
      exit 1
    fi

    grim -o "$MONITOR_CHOICE" /tmp/mon_cap.png

    v4l2-ctl --device "$TARGET_DEVICE" \
      --set-fmt-video=width=1920,height=1080,pixelformat=MJPG \
      --stream-mmap --stream-to=- --stream-count=1 | \
      magick /tmp/mon_cap.png - +append png:- | \
      wl-copy -t image/png

    rm /tmp/mon_cap.png
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
