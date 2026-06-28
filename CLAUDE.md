# CLAUDE.md — WikiReader Kit

Context for any agent working in this repo.

## What this is
A reusable iOS template for building offline-first **Wikipedia reader apps** on
any topic. The engine is topic-neutral; a new app = inject a "Topic Pack"
(categories + catalog + branding + copy). Forked from the *Criminally Intrigued*
app. See `README.md` and `NEW_APP_GUIDE.md` for the full flow.

## Make a new app
```bash
python3 Scripts/scaffold.py topic.json --out ~/Desktop/<app>   # rename, bundle id, config, accent
cd ~/Desktop/<app>
python3 Scripts/generate_catalog.py topic.json                 # pull catalog from Wikipedia
python3 Scripts/validate_catalog.py                            # confirm entries resolve
open <App>.xcodeproj
```

## ⚠️ Before shipping any app — personalize the placeholders
The `topic.json` files ship with **placeholder contact info** that MUST be
replaced with real values before building for release:
- `supportEmail` → real contact email (Wikimedia blocks placeholder User-Agents)
- `websiteURL` → real site (e.g. a GitHub Pages page)
- `privacyURL` → a live privacy-policy page (App Store requires it)

These default to `example.com` / `you@example.com`. They appear in About, the
Wikimedia User-Agent, and App Store metadata. Shipping with placeholders will
get the app rejected and/or rate-limited by Wikimedia.

## Key facts
- Topic-specific config lives ONLY in `<App>/Topic/TopicConfig.swift` (generated
  from `topic.json`). The engine elsewhere should not need editing.
- Categories are config-driven; model is `Entry` with a generic optional `metric`.
- When picking Wikipedia categories, use ones with **direct article pages** (not
  just subcategories) — `generate_catalog.py` prints kept-counts per tab.
- Apps are iPhone-only and export-compliance-exempt
  (`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`).
- Verified: the template and a scaffolded app both build via `xcodebuild`.
