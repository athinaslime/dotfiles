#!/bin/bash

USAGE_MESSAGE="usage: $0 [--enable | --up | --down]"
CACHE_DIRECTORY="${XDG_RUNTIME_DIR:-/tmp}"
CACHE_FILE="$CACHE_DIRECTORY/cc-audio-loopback-module-id"
VOLUME_STEP="5%"

sink_input_for_module() {
  pactl -f json list sink-inputs \
    | jq -r --arg mod "$1" '.[] | select(.owner_module==$mod) | .index'
}

current_volume_percent() {
  pactl -f json list sink-inputs \
    | jq -r --arg si "$1" '.[] | select((.index|tostring)==$si) | .volume["front-left"].value_percent' \
    | tr -d '%'
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
