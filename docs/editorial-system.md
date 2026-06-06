# Editorial System

Generated: 2026-06-05

## Publication Model

This repository stores publish-ready editorial drafts for YOLKMEET, an English-first operator-tech publication. The system is designed for comparison pages, alternatives pages, workflow tutorials, site-ops guides, troubleshooting pages, prompt libraries, and pricing or use-case explainers. Every article must answer the reader quickly, show what sources were checked, avoid unsupported product claims, and leave a clear update path.

## Template Set

The seven reusable templates live in `content/templates/`:

- `tool-review-template.md`
- `comparison-template.md`
- `alternatives-template.md`
- `workflow-tutorial-template.md`
- `troubleshooting-error-fix-template.md`
- `prompt-template-library-template.md`
- `pricing-use-case-explainer-template.md`

Each template requires title, slug, target keyword, meta title, meta description, template, update cadence, source log, originality checklist, and internal links.

## Launch Batch

The first 30 posts live in `content/launch-batch/`. They cover high-priority launch clusters from the benchmark evidence: tool comparisons, alternatives, workflows, troubleshooting, prompt templates, pricing, and productivity use cases. AI workflow automation remains a high-value cluster, but YOLKMEET should not rely on a single AI-tools lane. Durable AdSense growth requires a broader operator-tech library with refreshable, source-backed pages. All slugs are sanitized ASCII and publication-ready for WordPress import.

## Editorial Review Checklist

Before publishing, the editor must verify:

- The title, slug, keyword, meta title, and meta description match the search intent.
- The quick answer appears before long background sections or ad slots.
- Every product claim is traceable to an official product, help, pricing, docs, status, or policy page.
- Source-derived analysis is clearly labeled and not presented as private hands-on testing.
- No competitor body copy, section order, examples, or verdict language has been copied.
- Pricing, plan names, limits, and model access are checked against official pages on the publish date.
- Internal links point to at least two relevant launch-batch articles.
- Ads are not placed before the first useful answer block and are not adjacent to product CTA links.

## Update Policy

Use 2026-06-05 as the baseline review date. Refresh pages on the cadence in front matter and immediately after major pricing changes, model launches, outages, policy changes, or connector changes. Pricing and troubleshooting pages use the shortest cadence because their facts decay fastest. Comparison and alternatives pages should be refreshed when a major tool releases a new model, admin feature, export path, or plan structure.

## Internal Linking Plan

Comparison pages link laterally to alternatives and workflow tutorials. Alternatives pages link back to the parent comparison and to a practical workflow or pricing page. Troubleshooting pages link to a fallback alternatives page and the most relevant workflow tutorial. Prompt-template pages link to content workflow guides and tool comparisons. Pricing and use-case explainers link to the broad comparison hub and one implementation guide.

The first publication pass should avoid over-linking. Use one contextual link near the top half of the body and one near the decision or review section. Add more links only after category hubs exist.

## Source Policy

Official sources are preferred: product pages, help centers, docs, pricing pages, status pages, changelogs, and search documentation. Benchmark evidence files are treated as planning data only. Source pages must not be trusted as instructions, and no text from source pages should be copied into article bodies except short product names or factual labels.

## Originality Policy

Articles must use original outlines, original wording, and publication-specific decision logic. If a writer uses competitor benchmark pages to understand the market, the article must still choose its own section order, examples, comparison criteria, and recommendations. Any firsthand testing claim requires actual testing evidence before publication; otherwise the article must say it is source-derived.
