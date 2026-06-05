---
title: "Missing Approval Hourly Draft"
slug: "missing-approval-hourly-draft"
target_keyword: "missing approval hourly draft"
meta_title: "Missing Approval Hourly Draft"
meta_description: "An hourly fixture with good structure but no publishing approval metadata, so queueing must stop."
template: "workflow tutorial"
analysis_note: "Source-derived analysis for missing approval queue validation."
update_policy: "Review every 30 days."
source_urls:
  - "https://developers.google.com/search/docs/fundamentals/creating-helpful-content"
  - "https://developers.google.com/search/docs/essentials/spam-policies"
internal_links:
  - "workflow-for-original-content-verification"
  - "workflow-for-ai-approval-gates"
depth_exception: "Fixture is intentionally short to isolate approval metadata blocking."
---

# Missing Approval Hourly Draft

## Quick Answer
Use this fixture to prove the queue blocks a WordPress candidate that has sources and structure but lacks approval metadata. Choose a blocked state over a draft payload when Google AdSense review status is unclear.

## Checklist
| Gate | Expected result |
| --- | --- |
| Approval | Block before payload |

## Decision Criteria
Google Search and Google AdSense quality depend on reviewable publishing. The better choice is to stop the queue when approval state is missing.

## FAQ
### Why does this fail?
It lacks `publishing_approval: "approved"` in front matter.

## Source Notes
- https://developers.google.com/search/docs/fundamentals/creating-helpful-content checked 2026-06-06.
- https://developers.google.com/search/docs/essentials/spam-policies checked 2026-06-06.

## Review Notes
Update note: keep this fixture aligned with queue approval rules.
