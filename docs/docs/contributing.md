# Contributing to the Wiki

This wiki is only useful if it's accurate. The maintenance contract is simple: **when you change logic in the app, update the corresponding wiki page in the same change.**

## File → wiki page mapping

| If you edited this file | Update this page |
|---|---|
| `Estus/Utilities/RecommendationEngine.swift` | [`engines/recommendation-engine.md`](engines/recommendation-engine.md) and [`cross-cutting/scoring-pipeline.md`](cross-cutting/scoring-pipeline.md) |
| `Estus/Utilities/PersonalizationScorer.swift` | [`engines/personalization-scorer.md`](engines/personalization-scorer.md) |
| `Estus/Utilities/SafetyRules.swift` | [`engines/safety-rules.md`](engines/safety-rules.md) |
| `Estus/Utilities/SupplementNameMatcher.swift` | [`engines/supplement-name-matcher.md`](engines/supplement-name-matcher.md) |
| `Estus/Utilities/CheckInInsightGenerator.swift` | [`engines/check-in-insight-generator.md`](engines/check-in-insight-generator.md) |
| `Estus/Utilities/SupplementKnowledgeBase.swift` | [`knowledge-bases/supplement-kb.md`](knowledge-bases/supplement-kb.md) |
| `Estus/Utilities/MedicationKnowledgeBase.swift` | [`knowledge-bases/medication-kb.md`](knowledge-bases/medication-kb.md) |
| `Estus/Services/KnowledgeBaseMapper.swift` | [`knowledge-bases/knowledge-base-mapper.md`](knowledge-bases/knowledge-base-mapper.md) |
| `Estus/Services/SupplementCatalog.swift` | [`knowledge-bases/supplement-catalog.md`](knowledge-bases/supplement-catalog.md) |
| `Estus/Services/LocalStorageService.swift`, `Estus/Services/DataStore.swift` | [`architecture/persistence.md`](architecture/persistence.md) |
| `Estus/App/AppState.swift` | [`architecture/state-management.md`](architecture/state-management.md) |
| `Estus/Models/*.swift` | [`architecture/data-models.md`](architecture/data-models.md) |
| `Estus/Features/Onboarding/*` | [`flows/onboarding.md`](flows/onboarding.md) |
| `Estus/Features/Today/*` (daily check-in lives here) | [`flows/daily-check-in.md`](flows/daily-check-in.md) |
| `Estus/Features/Plan/PlanViewModel.swift` | [`flows/plan-management.md`](flows/plan-management.md) |
| `Estus/Features/Insights/InsightsViewModel.swift` | [`flows/insights-timeline.md`](flows/insights-timeline.md) |
| Adds/changes to drug interaction logic across multiple files | [`cross-cutting/interaction-checking.md`](cross-cutting/interaction-checking.md) |
| Changes to copy templates (engine, KB, insight rules) | [`cross-cutting/text-generation.md`](cross-cutting/text-generation.md) |

The same table lives in `CLAUDE.md` at the repo root, so future Claude sessions will load it automatically.

## What "update" means

You don't need to rewrite the page from scratch. Look for:

1. **Numbers and constants.** Tier thresholds (5/3), magnitude multipliers (1.15/1.25/1.5), tier max (7), supporting cap (1 when high-tier ≥ 5), check-in retention window (90 days), insight freshness window (5), etc. If you changed one, find every reference and update it.
2. **Step ordering in pipelines.** The `RecommendationEngine.generatePlan` walkthrough lists 9 steps. If you reorder or insert one, fix the page.
3. **Lists.** Mineral conflict pairs, PPI medication names, SSRI medication names, exclusion-group memberships, fired-signal types — these are listed verbatim in the wiki.
4. **Cross-references.** If a function moves from one file to another, update both pages that mention it.

## What's *not* worth documenting

- Code conventions → `CLAUDE.md` already covers them.
- Per-supplement metadata (specific dosages, evidence levels) → that's all in `SupplementKnowledgeBase.swift` or Supabase. Don't duplicate the data; link to the source file.
- Test strategies → live in `EstusTests/`, not here.
- Design system / colors / typography → `design.md` and the design HTML playgrounds.

## Pre-existing notes

`recommendation-engine-logic.md` at the repo root is an older personal note. The wiki supersedes it — feel free to delete or merge it the next time you touch the engine.

## Running locally

```bash
cd docs
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mkdocs serve
```

`mkdocs.yml` runs in `strict: true` mode — broken internal links fail the build. If `mkdocs serve` complains, fix the link before merging.
