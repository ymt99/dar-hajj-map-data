# Generate the hajj-areas.v1.pmtiles tile pack for Makkah,
# Mina, ʿArafat, Muzdalifah, and Madinah using planetiler.
#
# Run from the repo root:
#   .\scripts\generate-tiles.ps1
#
# Requires: Java 17+ (verify with `java -version`).
#
# This script intentionally lives outside the dar-hajj app
# repo because the build artifacts (planetiler.jar, OSM extract,
# planetiler temp dir) are large and ephemeral.

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $Root "build"
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# --- Coverage rectangle -----------------------------------------------
#
# Single bounding box covering all five sites. Empty desert
# between Makkah and Madinah contains no OSM data so the file
# stays small.
#
# Format expected by planetiler --bounds: minLon,minLat,maxLon,maxLat
$Bounds = "39.55,21.27,40.05,24.55"

# --- planetiler.jar ----------------------------------------------------
$PlanetilerVersion = "0.9.0"
$PlanetilerJar = Join-Path $BuildDir "planetiler.jar"
$PlanetilerUrl = "https://github.com/onthegomap/planetiler/releases/download/v$PlanetilerVersion/planetiler.jar"

if (-not (Test-Path $PlanetilerJar)) {
    Write-Host ">>> Downloading planetiler.jar ($PlanetilerVersion) ..."
    Invoke-WebRequest -Uri $PlanetilerUrl -OutFile $PlanetilerJar
} else {
    Write-Host ">>> planetiler.jar already present, skipping download"
}

# --- Output ------------------------------------------------------------
$OutputPmtiles = Join-Path $BuildDir "hajj-areas.v1.pmtiles"
if (Test-Path $OutputPmtiles) {
    Write-Host ">>> Removing previous $OutputPmtiles"
    Remove-Item $OutputPmtiles
}

# --- Run planetiler ----------------------------------------------------
#
# Profile: openmaptiles (the default and the one map-style.json
#          targets — gives us water/landuse/place/transportation/
#          building layers).
# Source:  Geofabrik's Saudi Arabia extract; planetiler downloads
#          and caches it under build/sources automatically.
# Bounds:  the rectangle above; planetiler clips the input to it,
#          producing a tile pack that only covers our five sites.
# Maxzoom: 16, deep enough to see individual tents at Mina/ʿArafat
#          and individual hotel buildings around the Ḥaram.
#
# RAM:     planetiler is fine on 4–8 GB heap for this small
#          extract. Adjust -Xmx below if your machine has less.
Write-Host ">>> Running planetiler — this takes 5–15 min ..."

java "-Xmx6g" -jar $PlanetilerJar `
    --area=saudi-arabia `
    --bounds=$Bounds `
    --download `
    --download-threads=4 `
    --maxzoom=16 `
    --output=$OutputPmtiles

if ($LASTEXITCODE -ne 0) {
    Write-Error "planetiler exited with code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# --- Post-build summary ------------------------------------------------
$size = (Get-Item $OutputPmtiles).Length / 1MB
Write-Host ""
Write-Host "================================================="
Write-Host "  Built: $OutputPmtiles"
Write-Host "  Size : $([Math]::Round($size, 1)) MB"
Write-Host "================================================="
Write-Host ""
Write-Host "Next: cut a Release on github.com/ymt99/dar-hajj-map-data"
Write-Host "      with this asset, e.g.:"
Write-Host ""
Write-Host "  gh release create v1 $OutputPmtiles \"
Write-Host "    --title 'Hajj 1447 / 2026 tile pack' \"
Write-Host "    --notes 'Refreshed $(Get-Date -Format yyyy-MM-dd) from Geofabrik Saudi Arabia.'"
