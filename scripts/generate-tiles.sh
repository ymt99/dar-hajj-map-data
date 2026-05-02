#!/usr/bin/env bash
# Generate the hajj-areas.v1.pmtiles tile pack for Makkah,
# Mina, ʿArafat, Muzdalifah, and Madinah using planetiler.
#
# Run from the repo root:
#   ./scripts/generate-tiles.sh
#
# Requires: Java 17+ (verify with `java -version`).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build"
mkdir -p "$BUILD_DIR"

# --- Coverage rectangle -----------------------------------------------
#
# Single bounding box covering all five sites. Empty desert
# between Makkah and Madinah contains no OSM data so the file
# stays small.
#
# Format expected by planetiler --bounds: minLon,minLat,maxLon,maxLat
BOUNDS="39.55,21.27,40.05,24.55"

# --- planetiler.jar ---------------------------------------------------
PLANETILER_VERSION="0.10.2"
PLANETILER_JAR="$BUILD_DIR/planetiler.jar"
PLANETILER_URL="https://github.com/onthegomap/planetiler/releases/download/v$PLANETILER_VERSION/planetiler.jar"

if [[ ! -f "$PLANETILER_JAR" ]]; then
  echo ">>> Downloading planetiler.jar ($PLANETILER_VERSION) ..."
  curl -fL --retry 3 -o "$PLANETILER_JAR" "$PLANETILER_URL"
else
  echo ">>> planetiler.jar already present, skipping download"
fi

# --- Output ------------------------------------------------------------
OUTPUT_PMTILES="$BUILD_DIR/hajj-areas.v1.pmtiles"
if [[ -f "$OUTPUT_PMTILES" ]]; then
  echo ">>> Removing previous $OUTPUT_PMTILES"
  rm "$OUTPUT_PMTILES"
fi

# --- Run planetiler ----------------------------------------------------
#
# Profile: openmaptiles (default; matches map-style.json layers).
# Source:  Geofabrik Saudi Arabia (auto-downloaded + cached).
# Bounds:  rectangle covering five sites; planetiler clips input.
# Maxzoom: 16, deep enough to see individual tents/buildings.
echo ">>> Running planetiler — this takes 5–15 min ..."

java -Xmx6g -jar "$PLANETILER_JAR" \
  --area=saudi-arabia \
  --bounds="$BOUNDS" \
  --download \
  --download-threads=4 \
  --maxzoom=16 \
  --output="$OUTPUT_PMTILES"

# --- Post-build summary ------------------------------------------------
SIZE_MB=$(du -m "$OUTPUT_PMTILES" | awk '{print $1}')
echo ""
echo "================================================="
echo "  Built: $OUTPUT_PMTILES"
echo "  Size : ${SIZE_MB} MB"
echo "================================================="
echo ""
echo "Next: cut a Release on github.com/ymt99/dar-hajj-map-data"
echo "      with this asset, e.g.:"
echo ""
echo "  gh release create v1 \"$OUTPUT_PMTILES\" \\"
echo "    --title 'Hajj 1447 / 2026 tile pack' \\"
echo "    --notes \"Refreshed \$(date -u +%Y-%m-%d) from Geofabrik Saudi Arabia.\""
