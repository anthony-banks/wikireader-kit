# Making a New App — Step by Step

This is the full walkthrough for spinning up a new Wikipedia-reader app from the
kit. Budget ~30 minutes to a running app; the App Store steps mirror what you've
done before.

---

## 1. Write a `topic.json`

Copy `topic.example.json` (or one in `topics/`) and edit. Schema:

| Key | Required | Notes |
|---|---|---|
| `appName` | ✅ | Display name (≤30 chars for the App Store). Also the Xcode target. |
| `bundleId` | ✅ | e.g. `com.yourname.lostatsea`. Must be unique in App Store Connect. |
| `accentHex` | ✅ | Brand color, e.g. `#1B4965`. Applied to the icon-less accent + tint. |
| `categories` | ✅ | 1–5 tabs. Each: `id`, `title`, `symbol` (SF Symbol), `wikipediaCategory`, optional `limit`. |
| `tagline`, `aboutText` | – | Shown in About. |
| `supportEmail`, `websiteURL`, `privacyURL` | – | Used in About + the Wikimedia User-Agent + App Store. Set these before shipping. |
| `metricLabel` | – | A per-entry number facet (e.g. `"victims"`, `"ships"`). `null` hides the metric chip + filter. |
| `metricSymbol`, `metricThresholds` | – | SF Symbol + filter thresholds for the metric. |
| `showRegionFilter`, `showDateFacet` | – | Toggle the country and year facets (default true). |
| `disclaimerTitle`, `disclaimerBody` | – | First-launch content warning. `null` = none. |

### Choosing Wikipedia categories
Each tab pulls from one Wikipedia category. **Pick categories that contain
*direct article pages***, not just subcategories — e.g. `Category:Golden Age of
Piracy` is all subcategories (0 articles), but `Category:18th-century pirates`
has ~185. `generate_catalog.py` prints how many it kept per tab; if a tab comes
back empty, swap the category. Quick check:

```bash
curl -s "https://en.wikipedia.org/w/api.php?action=query&list=categorymembers&cmtitle=Category:18th-century%20pirates&cmtype=page&cmlimit=500&format=json&formatversion=2" \
  | python3 -c "import sys,json;print(len(json.load(sys.stdin)['query']['categorymembers']))"
```

---

## 2. Scaffold the app

```bash
python3 Scripts/scaffold.py topic.json --out ~/Desktop/<folder>
```

This copies the template, renames the Xcode project to your `appName`, sets the
bundle id, writes a configured `TopicConfig.swift`, and applies your accent color.

---

## 3. Generate the catalog

```bash
cd ~/Desktop/<folder>
python3 Scripts/generate_catalog.py topic.json
```

Pulls each category's articles, keeps the ones with a real (non-stub,
non-disambiguation) summary, and writes `<App>/Resources/SeedCatalog.json`. It
fills `id`, `title`, `category`, `articleURL`. `metric` / `country` / `startDate`
can't be inferred from Wikipedia — leave them null, or curate the ones you care
about (only needed if you enabled those facets).

---

## 4. Validate

```bash
python3 Scripts/validate_catalog.py
```

Confirms every entry resolves on Wikipedia — both the card summary and the full
article body. Fix or remove anything flagged. Re-run until clean.

---

## 5. Build & run

```bash
open <App>.xcodeproj
```

- ⌘R in the simulator. You'll see your tabs, filtering, search, reading view.
- ⌘U runs the test suite (model/decoding/catalog-integrity checks).
- Tap an entry → it fetches + caches the Wikipedia article for offline reading,
  with the CC BY-SA attribution footer.

---

## 6. Branding

- **Accent color** — already set from `accentHex`. To fine-tune light/dark or the
  fill/pressed shades, edit `<App>/Resources/Assets.xcassets/Accent*.colorset`.
- **App icon** — replace `AppIcon.appiconset/AppIcon-1024.png` with a 1024×1024
  PNG (no transparency).

---

## 7. Ship it (App Store Connect)

Same flow as before:
1. Host a privacy policy (the app's `privacyURL`) — "Data Not Collected".
2. App Store Connect → new app, your bundle id, price.
3. Metadata: description, keywords, screenshots (6.9″ slot), age rating.
4. App Privacy → **Data Not Collected**.
5. Xcode: **Any iOS Device → Product → Archive → Distribute → Upload**.
6. Attach build, **Add for Review → Submit**.

Notes carried over from Criminally Intrigued:
- The app is iPhone-only and export-compliance-exempt
  (`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`) — no iPad screenshots, no
  compliance prompt.
- Every article shows the mandatory CC BY-SA 4.0 attribution; lead your review
  notes with that + the offline/filter features (it's more than a web view).

---

## Reference: what's topic-specific vs engine

You edit only the **Topic Pack**:
- `<App>/Topic/TopicConfig.swift`
- `<App>/Resources/SeedCatalog.json` (generated)
- `<App>/Resources/Assets.xcassets/AccentColor.colorset` + `AppIcon`

Everything else is the shared engine and should not need changes.
