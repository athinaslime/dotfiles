#!/bin/bash

USAGE_MESSAGE="usage: $0 [--enable | --up | --down]"
CACHE_DIRECTORY="${XDG_RUNTIME_DIR:-/tmp}"
CACHE_FILE="$CACHE_DIRECTORY/cc-audio-loopback-module-id"
VOLUME_STEP="5%"

sink_input_for_module() {
  pactl list sink-inputs | awk -v mod="$1" '
    /^Sink Input #/ { idx = $0; sub(/^Sink Input #/, "", idx) }
    $0 ~ ("Owner Module: " mod "$") { print idx }
  '
}

current_volume_percent() {
  pactl list sink-inputs | sed -n "/Sink Input #$1\$/,/Sink Input #/p" \
    | grep -m1 "Volume:" | grep -oP '\d+(?=%)' | head -1
}

case "$1" in
  --enable)
    mkdir -p "$CACHE_DIRECTORY"
    module_id=$(pactl load-module module-loopback)
    echo "$module_id" > "$CACHE_FILE"
    ;;

  --up|--down)
    module_id=$(cat "$CACHE_FILE" 2>/dev/null)
    if [ -z "$module_id" ]; then
      echo "no loopback module cached; run --enable first" >&2
      exit 1
    fi

    sink_input=$(sink_input_for_module "$module_id")
    if [ -z "$sink_input" ]; then
      echo "cached module id $module_id has no matching sink input" >&2
      exit 1
    fi

    if [ "$1" = "--up" ]; then
      current=$(current_volume_percent "$sink_input")
      new=$(( current + ${VOLUME_STEP%\%} ))
      [ "$new" -gt 100 ] && new=100
      
      pactl set-sink-input-volume "$sink_input" "${new}%"
    else
      pactl set-sink-input-volume "$sink_input" "-$VOLUME_STEP"
    fi
    ;;

  *)
    echo "$USAGE_MESSAGE" >&2
    exit 1
    ;;
esac
