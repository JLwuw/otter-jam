#!/bin/sh
printf '\033c\033]0;%s\a' OtterJam
base_path="$(dirname "$(realpath "$0")")"
"$base_path/OtterJam.x86_64" "$@"
