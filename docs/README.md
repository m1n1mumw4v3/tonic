# Estus Internal Wiki

Personal, internal-only reference for how the Estus iOS app's logic works under the hood — engines, knowledge bases, scoring, data flow. Never deployed; never user-facing.

## Run locally

From this directory (`docs/`):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mkdocs serve
```

Then open <http://127.0.0.1:8000>.

## Build

```bash
mkdocs build
```

Output goes to `docs/site/` (gitignored).

## Adding pages

1. Create a markdown file under `docs/docs/...`.
2. Add it to the `nav:` block in `mkdocs.yml`.
3. `mkdocs serve` autoreloads.

## When to update content

See [`contributing.md`](docs/contributing.md) for the file → wiki page mapping. The short version: when you change logic in `RecommendationEngine`, `PersonalizationScorer`, `SafetyRules`, the knowledge bases, or any feature view-model, update the corresponding page in the same change. The same rule lives in the project root `CLAUDE.md`.
