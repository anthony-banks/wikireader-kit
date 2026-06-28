#!/usr/bin/env python3
"""
Generate WikiReader/Resources/SeedCatalog.json from Wikipedia categories.

This is the "inject a topic quickly" tool. Point it at a topic.json whose
categories each name a Wikipedia category, and it pulls the member articles,
keeps the ones with a real (non-stub, non-disambiguation) summary, and writes
a ready-to-ship seed in the format the app expects.

    python3 Scripts/generate_catalog.py topic.json
    python3 Scripts/generate_catalog.py topic.json --limit 40 --out WikiReader/Resources/SeedCatalog.json

It fills id, title, category, and articleURL. Summaries are intentionally left
out (the app fetches them live). metric / country / startDate can't be inferred
reliably from Wikipedia, so they're left null for you to curate where it matters.

Run Scripts/validate_catalog.py afterward to confirm every entry resolves.

topic.json categories look like:
    "categories": [
      { "id": "pirates", "title": "Pirates", "symbol": "flag.fill",
        "wikipediaCategory": "Category:Golden Age of Piracy", "limit": 60 }
    ]
"""

import argparse
import json
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

try:
    import certifi
    SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    SSL_CONTEXT = ssl.create_default_context()

ACTION_API = "https://en.wikipedia.org/w/api.php"
REST_SUMMARY = "https://en.wikipedia.org/api/rest_v1/page/summary/"
MIN_EXTRACT_CHARS = 20          # mirrors WikiSummary.isUsable
REQUEST_PAUSE = 0.12
MAX_RETRIES = 4
DEFAULT_OUT = Path(__file__).resolve().parent.parent / "WikiReader" / "Resources" / "SeedCatalog.json"


def user_agent(topic):
    name = topic.get("appName", "WikiReader").replace(" ", "")
    contact = topic.get("supportEmail", "you@example.com")
    site = topic.get("websiteURL", "https://example.com")
    return f"{name}/1.0 ({site}; {contact})"


def _get(url, ua):
    req = urllib.request.Request(url, headers={"User-Agent": ua, "Accept": "application/json"})
    backoff = 1.0
    for attempt in range(MAX_RETRIES):
        try:
            with urllib.request.urlopen(req, timeout=25, context=SSL_CONTEXT) as r:
                return r.status, json.loads(r.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return 404, None
            if e.code in (429, 500, 502, 503) and attempt < MAX_RETRIES - 1:
                time.sleep(backoff); backoff *= 2; continue
            return e.code, None
        except (urllib.error.URLError, TimeoutError):
            if attempt < MAX_RETRIES - 1:
                time.sleep(backoff); backoff *= 2; continue
            return None, None
    return None, None


def category_members(category, limit, ua):
    """Article titles (ns=0) belonging to a Wikipedia category, paginated."""
    if not category.startswith("Category:"):
        category = "Category:" + category
    titles, cont = [], None
    while len(titles) < limit:
        params = {
            "action": "query", "list": "categorymembers", "cmtitle": category,
            "cmtype": "page", "cmlimit": "max", "format": "json", "formatversion": "2",
        }
        if cont:
            params["cmcontinue"] = cont
        status, data = _get(f"{ACTION_API}?{urllib.parse.urlencode(params)}", ua)
        if not data:
            break
        members = data.get("query", {}).get("categorymembers", [])
        titles.extend(m["title"] for m in members if m.get("ns") == 0)
        cont = data.get("continue", {}).get("cmcontinue")
        if not cont:
            break
        time.sleep(REQUEST_PAUSE)
    return titles[:limit]


def usable_summary(title, ua):
    """Return (canonical_title, thumbnail_url) if the page is a usable article, else None."""
    enc = urllib.parse.quote(title.replace(" ", "_"), safe="_")
    status, d = _get(REST_SUMMARY + enc, ua)
    if not d:
        return None
    if d.get("type") in ("disambiguation", "no-extract"):
        return None
    extract = (d.get("extract") or "").strip()
    if len(extract) < MIN_EXTRACT_CHARS:
        return None
    canonical = d.get("titles", {}).get("normalized") or d.get("title") or title
    thumb = (d.get("thumbnail") or {}).get("source")
    return canonical, thumb


def main():
    ap = argparse.ArgumentParser(description="Generate SeedCatalog.json from Wikipedia categories.")
    ap.add_argument("topic", help="Path to topic.json")
    ap.add_argument("--out", default=str(DEFAULT_OUT), help="Output seed path")
    ap.add_argument("--limit", type=int, default=0, help="Override per-category limit for all categories")
    args = ap.parse_args()

    topic = json.loads(Path(args.topic).read_text())
    ua = user_agent(topic)
    cats = topic.get("categories", [])
    if not cats:
        print("error: topic.json has no categories", file=sys.stderr)
        return 2

    seen = set()
    entries = []
    for cat in cats:
        cid = cat["id"]
        wiki_cat = cat.get("wikipediaCategory")
        if not wiki_cat:
            print(f"  [{cid}] no wikipediaCategory — skipping")
            continue
        limit = args.limit or cat.get("limit", 50)
        print(f"\n[{cid}] {wiki_cat}  (target {limit})")
        titles = category_members(wiki_cat, limit * 3, ua)  # over-fetch; many won't be usable
        kept = 0
        for title in titles:
            if kept >= limit:
                break
            result = usable_summary(title, ua)
            time.sleep(REQUEST_PAUSE)
            if not result:
                continue
            canonical, thumb = result
            slug = canonical.replace(" ", "_")
            eid = f"enwiki:{slug}"
            if eid in seen:
                continue
            seen.add(eid)
            entry = {
                "id": eid,
                "title": canonical,
                "category": cid,
                "articleURL": "https://en.wikipedia.org/wiki/" + urllib.parse.quote(slug, safe="_"),
            }
            if thumb:
                entry["thumbnailURL"] = thumb
            entries.append(entry)
            kept += 1
            print(f"    ✓ {canonical}")
        print(f"  kept {kept} for '{cid}'")

    out = {
        "generatedAt": topic.get("generatedAt", "generated"),
        "_note": f"Generated by generate_catalog.py for {topic.get('appName','app')}. "
                 "Run validate_catalog.py to confirm, then curate metric/country/date where useful.",
        "entries": entries,
    }
    Path(args.out).write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n")
    print(f"\nWrote {len(entries)} entries to {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
