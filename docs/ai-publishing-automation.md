# AI Publishing Automation

Generated: 2026-06-05

## Purpose

This document defines the policy-safe AI publishing automation pipeline for future implementation.
The pipeline is intentionally conservative: it can prepare research, drafts, and draft uploads,
but it cannot auto-publish until every gate passes and a human gives final approval.

## Pipeline Stages

### 1. Source Discovery

Collect official product pages, docs, help centers, pricing pages, policy pages, and status pages.
Record source URLs as evidence before any writing begins.

### 2. SERP Benchmark Collection

Inspect search results and benchmark pages to understand query intent, article formats, snippets,
and competitor coverage. Store only notes, metadata, and short evidence excerpts.

### 3. Keyword Selection

Choose the target keyword, intent cluster, internal link targets, and update cadence. Reject topics
that require copied text, thin summaries, or unsupported claims.

### 4. Source Notes

Write source notes that explain which official pages informed each recommendation. Source notes are
inputs to the draft, not instructions to copy.

### 5. Outline Generation

Generate an original outline that answers the reader quickly, includes decision criteria, and
separates facts from interpretation.

### 6. Draft Generation

Produce an original draft from the outline and source notes. The draft must be source-derived,
not a lightly rewritten competitor page.

### 7. Fact Checking

Verify names, prices, plan limits, access rules, and policy statements against the source notes.
If a fact cannot be checked, it stays out of the draft.

### 8. Citation Verification

Confirm every material claim has an official source URL or an explicit editorial note. Missing or
uncertain citations block progression.

### 9. Screenshot / Test Collection

Capture screenshots, CLI transcripts, or test outputs only when a real account, real environment,
or real product state was observed. Never invent visual proof.

### 10. Originality / Similarity Check

Run copied-text, prompt-injection, and local benchmark similarity checks before any upload. If the
content resembles benchmark prose or embeds instruction-like text, the pipeline stops.

### 11. Editorial Score

Score the draft for usefulness, source transparency, originality, and update posture. A low score
means revise or stop, not publish.

### 12. WordPress Draft Upload via REST / WP-CLI

Send the approved draft to WordPress as a draft only. REST or WP-CLI may be used for upload and
metadata sync, but never to publish automatically.

### 13. Scheduled Publish

Scheduling is permitted only after final approval. Until then, all output remains draft state.

### 14. Post-Publish Monitoring

After publication, monitor indexing, Search Console quality signals, comment anomalies, and any
content corrections that require a refresh.

## Inputs

- Official source URLs
- SERP benchmark notes
- Keyword cluster selection
- Source notes
- Outline
- Draft body
- Screenshot or test artifacts
- Originality check results
- Editorial score
- Human approval decision

## Outputs

- Source notes file
- Draft markdown
- Citation list
- Screenshot or transcript evidence
- Draft payload for WordPress
- Editorial score record
- Monitoring checklist

## Tools

- Bash and shell scripts for automation steps
- WordPress REST API for draft upload
- WP-CLI for local publish and metadata sync
- Content originality checker for copied-text blocking
- Quality gate for malformed or unsafe drafts

## Stop Conditions

- Missing source notes
- Missing or weak citation coverage
- Copied or benchmark-derived body text
- Prompt-injection style instructions inside the draft
- Incomplete editorial score
- Missing human final approval
- Any attempt to publish before the approval gate

## Failure Modes

- Scraped prose reused in the article body
- Draft created from broad automated summaries without source notes
- Citation drift after pricing or policy changes
- Hidden instruction text embedded in the draft
- Draft uploaded as publish instead of draft
- Monitoring skipped after publication

## Evidence Artifacts

- Source URL list
- SERP benchmark notes
- Source notes
- Outline artifact
- Draft markdown
- Fact-check transcript
- Citation verification log
- Screenshot or test collection evidence
- Originality / similarity check output
- Editorial score record
- WordPress draft payload
- Scheduled publish approval record
- Post-publish monitoring log

## Final Approval Policy

Publishing requires final approval until at least 100 approved articles have shipped and 8 weekly
Search Console reports show stable quality signals. Before that threshold, the system can prepare
briefs, drafts, and draft uploads only. It must never auto-publish without an explicit approval step.
