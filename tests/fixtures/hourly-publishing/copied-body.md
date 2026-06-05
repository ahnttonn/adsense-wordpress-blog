---
title: "Copied Hourly Publishing Draft"
slug: "copied-hourly-publishing-draft"
target_keyword: "copied hourly publishing draft"
meta_title: "Copied Hourly Publishing Draft"
meta_description: "A copied-body hourly fixture that should fail before creating a WordPress draft payload."
template: "workflow tutorial"
publishing_approval: "approved"
analysis_note: "Source-derived analysis for copied hourly publishing queue validation."
update_policy: "Review every 30 days."
source_urls:
  - "https://developers.google.com/search/docs/fundamentals/creating-helpful-content"
  - "https://developers.google.com/search/docs/essentials/spam-policies"
internal_links:
  - "workflow-for-original-content-verification"
  - "workflow-for-ai-approval-gates"
depth_exception: "Fixture is intentionally short to isolate copied-body blocking."
---

# Copied Hourly Publishing Draft

## Quick Answer
This fixture should fail because it contains copied benchmark prose even though approval metadata is present.

## Checklist
| Gate | Expected result |
| --- | --- |
| Originality | Block copied body |

## Decision Criteria
Workflow automation articles should explain the job to be done before recommending tools, describe the source notes that informed each decision, and give readers a verification step they can repeat before publishing or buying software.

## FAQ
### Should this create a payload?
No. A copied-body fixture must stop before payload generation.

## Source Notes
- https://developers.google.com/search/docs/fundamentals/creating-helpful-content checked 2026-06-06.
- https://developers.google.com/search/docs/essentials/spam-policies checked 2026-06-06.

## Review Notes
Update note: keep this fixture aligned with copied-source detection.
