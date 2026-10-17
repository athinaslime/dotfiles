#!/bin/bash

USAGE_MESSAGE="usage: $0 [--region | --monitor | --device | --devmon]"

case "$1" in
  --region)
    grim -g "$(slurp)" - | wl-copy
    exit 1
  ;;

  --monitor)
    grim -o "$2" - | wl-copy
    exit 0
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

    grim -o "$2" /tmp/mon_cap.png

    v4l2-ctl --device "$TARGET_DEVICE" \
      --set-fmt-video=width=1920,height=1080,pixelformat=MJPG \
      --stream-mmap --stream-to=- --stream-count=1 | \
      magick /tmp/mon_cap.png - +append png:- | \
      wl-copy -t image/png

    rm /tmp/mon_cap.png
  ;;

  *)
    echo "$USAGE_MESSAGE"
    exit 1
  ;;
esac
