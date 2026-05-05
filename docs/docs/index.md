# Estus Internal Wiki

This is a private reference for how the Estus app's logic actually works — the engines, knowledge bases, scoring rules, and data flow. It exists because reading the code top-to-bottom takes too long when I just need to remember "where does the tier score come from?" or "what fires the PPI boost?"

The wiki is not user-facing, never deployed, and only as accurate as the most recent commit that touched it. The maintenance contract is in [Contributing](contributing.md) — and mirrored in the project root `CLAUDE.md` so it gets enforced session-to-session.

## How it's organized

- **[Architecture](architecture/overview.md)** — high-level data flow, app state, persistence, and the data models that everything else operates on.
- **[Engines](engines/recommendation-engine.md)** — the deterministic logic modules: recommendation, personalization scoring, safety rules, name matching, insight generation.
- **[Knowledge Bases](knowledge-bases/supplement-kb.md)** — the static and Supabase-backed reference data: supplements, medications, the mapper that bridges them, and the in-memory catalog.
- **[Flows](flows/onboarding.md)** — feature-level UX flows: onboarding, daily check-in, plan management, insights timeline.
- **[Cross-Cutting](cross-cutting/scoring-pipeline.md)** — logic that spans multiple files. The scoring pipeline, interaction checking, and text generation each live in 3+ places; these pages stitch them together.

## What's *not* in here

- Code conventions and design decisions → those live in `CLAUDE.md` at the repo root.
- The brand/design system → see `design.md` and the various design HTML playgrounds at the repo root.
- API contracts with Supabase tables → those are derivable from `Estus/Models/Supabase*.swift` and `KnowledgeBaseMapper.swift`.
- "Why does this commit exist?" → that's `git log`'s job.

## Reading order if you're new (or me, six months from now)

1. [Architecture: Overview](architecture/overview.md) — the data flow diagram.
2. [Engines: Recommendation Engine](engines/recommendation-engine.md) — the meat.
3. [Cross-Cutting: Scoring Pipeline](cross-cutting/scoring-pipeline.md) — how the pieces connect.
4. From there, dive into whatever you're touching.
