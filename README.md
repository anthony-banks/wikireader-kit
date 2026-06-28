# WikiReader Kit

A reusable iOS app template for building clean, offline-first **Wikipedia reader
apps** on any topic. The engine (browsing, filtering, search, offline caching,
bookmarks, reading view, CC BY-SA attribution) is fixed and topic-neutral — to
make a new app you inject a **Topic Pack**: categories, a catalog, branding, and
copy. No engine code to touch.

Forked and generalized from the *Criminally Intrigued* app.

## What a new app needs

1. A `topic.json` (name, bundle id, accent color, categories → Wikipedia
   categories, copy). See `topic.example.json` and ready-made files in `topics/`.
2. Run two scripts. That's it.

## Quickstart

```bash
# 1. Stamp out a new app from a topic file
python3 Scripts/scaffold.py topics/pirates.json --out ~/Desktop/lost-at-sea

# 2. Pull its catalog from Wikipedia (verified, ready to ship)
cd ~/Desktop/lost-at-sea
python3 Scripts/generate_catalog.py topic.json

# 3. Confirm every entry resolves (card + article body)
python3 Scripts/validate_catalog.py

# 4. Build & run
open LostAtSea.xcodeproj
```

Then the App Store steps (icon, screenshots, metadata) — see `NEW_APP_GUIDE.md`.

## The one file you edit by hand

Everything topic-specific lives in **`<App>/Topic/TopicConfig.swift`** (the
scaffold generates it from `topic.json`, but you can hand-edit anytime):
name, tagline, About copy, contact URLs, the category tabs, the optional
"metric" facet (e.g. *victims*, *ships*, *year built*), which filters show, and
an optional first-launch disclaimer.

## Scripts

| Script | Purpose |
|---|---|
| `scaffold.py` | Stamp a new app from `topic.json` (rename, bundle id, config, accent). |
| `generate_catalog.py` | Build `SeedCatalog.json` from your Wikipedia categories (keeps only real, non-stub articles). |
| `validate_catalog.py` | Check every catalog entry resolves on Wikipedia (card summary **and** full article body). |

## Architecture (the engine — you shouldn't need to touch it)

- **App/** — entry point, environment (SwiftData container + repositories), root tabs.
- **Topic/** — `TopicConfig.swift` ← the injectable config.
- **Models/** — `Entry` (`@Model`), `TopicCategory`, DTOs.
- **Services/** — `HTTPClient` (Wikimedia UA + 429 backoff), `WikipediaService`.
- **Repositories/** — catalog seed, article cache, bookmarks, offline downloader.
- **Features/** — category list, detail/reading view, filters, saved, settings, about.
- **DesignSystem/** — semantic colors (swap `AccentColor` to rebrand), typography, components.

See `NEW_APP_GUIDE.md` for the full, step-by-step walkthrough.
