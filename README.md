# dar-hajj-map-data

Offline-first OpenStreetMap vector tile pack for the
[hajjguide.xyz](https://hajjguide.xyz) **Anchor** feature.

The app fetches the latest `hajj-areas.vN.pmtiles` from this repo's
Releases at runtime, decodes it client-side via
[`pmtiles`](https://github.com/protomaps/PMTiles), and renders it
with [`maplibre-gl`](https://maplibre.org/). No tile server, no
API keys, no recurring costs.

> **This repo holds tile binaries only.** It is intentionally
> separate from the (private) app repo because GitHub Release
> assets on private repos require auth and cannot be fetched
> anonymously by a browser.

---

## Coverage — five sites only

The tile pack covers **only** the five Hajj sites. **No other
location is included.** Outside the rectangles below, the map will
show OSM's online raster fallback (with attribution) at our scale,
or — if you've gone offline — a blank canvas.

| Site | Approx. coords | Why it's in the pack |
|---|---|---|
| **Makkah** (Masjid al-Ḥarām) | 21.4225°N, 39.8262°E | Tawaf, Sa'i, hotels around the Haram |
| **Mina** | 21.4133°N, 39.8933°E | Tents on 8/11/12/13 Dhu al-Ḥijjah |
| **Muzdalifah** | 21.3833°N, 39.9379°E | Sleeping under the open sky on the night of 9–10 |
| **ʿArafat** (Jabal al-Raḥmah) | 21.3550°N, 39.9839°E | Wuqūf on 9 Dhu al-Ḥijjah |
| **Madinah** (Masjid al-Nabawī) | 24.4672°N, 39.6111°E | Pre/post-Hajj ziyārah |

The bounding box used by the generator is:

```
South-West: 21.27°N, 39.55°E
North-East: 24.55°N, 40.05°E
```

Empty desert in between is included structurally but contains
no OSM data, so the file stays small.

## ⚠️ Important — read before relying on this

- **Supplemental tool, not a substitute.** This map is meant to
  help you orient yourself near the rituals and find your tent
  cluster. It is *not* a navigation app. Stay aware of your
  group, your guides, and the people around you. Do not rely on
  it 100%.
- **GPS — not Google Maps.** The position dot is your phone's
  GPS reading. It can be off by 30+ meters near tall buildings,
  in dense crowds, or at the Jamarāt bridge. The arrow will
  still get you to the right cluster of tents, but please use
  judgment.
- **Coverage is strict.** Only the five sites listed above are
  rendered from this offline pack. Outside that rectangle, the
  map either falls back to online OSM (when network is
  available) or shows a blank canvas. **If you travel outside
  these five sites, this app cannot help you navigate.**
- **OSM data is community-edited and may be wrong.** Tents,
  fences, and temporary structures change every Hajj. Treat the
  map as a strong hint, not as ground truth.

## What's in this repo

```
dar-hajj-map-data/
├── README.md                ← you are here
├── LICENSE-DATA             ← ODbL 1.0 (the OSM data terms)
├── LICENSE-CODE             ← MIT (the generation script)
├── scripts/
│   ├── generate-tiles.ps1   ← Windows / PowerShell generator
│   └── generate-tiles.sh    ← macOS / Linux generator
└── .gitignore               ← keeps build artifacts out of git
```

The actual `.pmtiles` files live in
[Releases](../../releases) — they are too large to commit to git
and version much faster than the rest of the repo.

## How to (re)generate the tile pack

You only need to do this when you want to refresh the OSM data
(e.g. yearly, before Hajj season). The generated file is the
same regardless of which OS you run from.

### Prerequisites

- **Java 17 or newer** (planetiler requires it). Verify with
  `java -version`.
- ~3 GB free disk space (for the OSM extract + planetiler temp
  data). The final `.pmtiles` itself is ~30–100 MB.
- ~500 MB of bandwidth on first run (planetiler.jar ≈ 85 MB,
  Saudi Arabia OSM extract ≈ 250 MB).

### Windows (PowerShell)

```powershell
.\scripts\generate-tiles.ps1
```

### macOS / Linux (bash)

```bash
chmod +x ./scripts/generate-tiles.sh
./scripts/generate-tiles.sh
```

Both scripts:

1. Download `planetiler.jar` (latest stable) into `./build/`
2. Download Saudi Arabia OSM extract (cached, redownloads only
   if older than 7 days)
3. Run planetiler with our bbox and `--maxzoom=16` against the
   default OpenMapTiles profile
4. Output `./build/hajj-areas.vN.pmtiles`

### Publishing a new version to Releases

```bash
gh release create v1.0.0-2026 ./build/hajj-areas.v1.pmtiles \
  --title "Hajj 1447 / 2026 tile pack" \
  --notes "Refreshed from Geofabrik Saudi Arabia extract on $(date -u +%Y-%m-%d). Coverage: Makkah + Mina + ʿArafat + Muzdalifah + Madinah."
```

The app reads from the **`v1` Release tag**'s
`hajj-areas.v1.pmtiles` asset. To bump to a new schema (e.g. v2
with new layers), publish a `v2` Release and update the URL in
the app's `src/lib/pmtiles.ts`.

## Why a separate repo?

The main app repo is private. Private-repo Release assets
require auth tokens and cannot be fetched anonymously by a
browser. Since this map data is just OSM (a public resource
under ODbL), there's nothing sensitive in it, and a public
companion repo is the simplest way to expose it.

## License

- **Map data** — © OpenStreetMap contributors, available under
  the [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/).
  Attribution is rendered inside the app's map view.
- **Generation script** — MIT, see `LICENSE-CODE`.
