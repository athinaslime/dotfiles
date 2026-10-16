#!/bin/bash

USAGE_MESSAGE="usage: $0 [--region]"

case "$1" in
  --region)
    grim -g "$(slurp)" - | wl-copy
    exit 1
  ;;

  *)
    echo "$USAGE_MESSAGE"
    exit 1
  ;;
esac
