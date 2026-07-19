#!/usr/bin/env bash
# Re-renders the store-art source images straight out of the real menu backdrop
# (shaders/menuSky.gdshader) and then rebuilds every capsule. Run from the
# project root:  ./Steam/render_masters.sh
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/masters"
mkdir -p "$OUT"

POSTER_W=2560 POSTER_H=1440 POSTER_TIME=0.8 POSTER_OUT="$OUT/master_wide.png" \
  godot --resolution 400x260 res://Scenes/posterShot.tscn

POSTER_W=1400 POSTER_H=2100 POSTER_TIME=0.8 POSTER_OUT="$OUT/master_tall.png" \
  godot --resolution 400x260 res://Scenes/posterShot.tscn

git checkout project.godot 2>/dev/null || true
python3 "$HERE/generate_art.py"
