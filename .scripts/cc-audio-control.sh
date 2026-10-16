#!/bin/bash

USAGE_MESSAGE="usage: $0 [--enable | --up | --down]"
CACHE_DIRECTORY="${XDG_RUNTIME_DIR:-/tmp}"
CACHE_FILE="$CACHE_DIRECTORY/cc-audio-loopback-module-id"
VOLUME_STEP=5

case "$1" in
  --enable)
    mkdir -p "$CACHE_DIRECTORY"

    existing=$(cat "$CACHE_FILE" 2>/dev/null)
    if [ -n "$existing" ] && pactl list short modules | awk -v mod="$existing" '$1 == mod { f=1 } END { exit !f }'; then
      echo "loopback already enabled in module $existing." >&2
      exit 1
    fi

    module_id=$(pactl load-module module-loopback) || {
      echo "failed to load module-loopback." >&2
      exit 1
    }

    echo "$module_id" > "$CACHE_FILE"
  ;;

  --up|--down)
    module_id=$(cat "$CACHE_FILE" 2>/dev/null)

    if [ -z "$module_id" ]; then
      echo "no loopback module cached, run --enable first." >&2
      exit 1
    fi

    if ! pactl list short modules | awk -v mod="$module_id" '$1 == mod { found=1 } END { exit !found }'; then
      echo "cached module $module_id is no longer loaded, run --enable again." >&2
      rm -f "$CACHE_FILE"
      exit 1
    fi

    sink_input_id=$(pactl list sink-inputs | awk -v mod="$module_id" '
      /^Sink Input #/ { id = substr($3, 2) }
      /Owner Module:/ && $3 == mod { print id; exit }
    ')

    if [ -z "$sink_input_id" ]; then
      echo "module $module_id is loaded but has no sink input." >&2
      exit 1
    fi

    current=$(pactl list sink-inputs | awk -v id="$sink_input_id" '
      /^Sink Input #/ { cur = substr($3, 2) }
      cur == id && /^[[:space:]]*Volume:/ {
        match($0, /[0-9]+%/)
        print substr($0, RSTART, RLENGTH - 1)
        exit
      }
    ')

    if [ -z "$current" ]; then
      echo "could not read current volume." >&2
      exit 1
    fi

    if [ "$1" = "--up" ]; then
      new=$(( current + VOLUME_STEP ))
    else
      new=$(( current - VOLUME_STEP ))
    fi

    [ "$new" -gt 100 ] && new=100
    [ "$new" -lt 0 ] && new=0

    pactl set-sink-input-volume "$sink_input_id" "${new}%"
  ;;

  *)
    echo "$USAGE_MESSAGE" >&2
    exit 1
  ;;
esac
