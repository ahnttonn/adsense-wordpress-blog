# Deployment and Rollback Guide

Generated: 2026-06-06

## Scope

This guide covers deployment and rollback for content imports, theme ad behavior, SEO/AEO/GEO checks, AdSense Auto ads site-side readiness, and hourly publishing automation. User-owned Google account actions remain outside repository automation.

## Pre-Deployment Checks

```bash
bash tests/content-contract.test.sh
bash tests/content-originality-fixture.test.sh
bash tests/seo-aeo-geo-readiness.test.sh
bash tests/theme-baseline.test.sh
bash tests/adsense-approval-package.test.sh
SITE_URL=https://www.yolkmeet.com bash infra/adsense-preflight.sh
```

## Content Import Deployment

Use `infra/publish-launch-batch.sh` only after the launch content passes quality gates. Record the manifest checksum, changed slugs, and WordPress post IDs before import.

Rollback content import:

```bash
echo "rollback content import: restore previous WordPress backup or re-run prior manifest mapping"
```

The rollback action must not delete posts blindly. It should restore from a known backup or update affected posts back to the previous body and metadata.

## Theme Deployment

Before deploying theme changes:

```bash
bash tests/theme-baseline.test.sh
```

Restore previous theme:

```bash
echo "restore previous theme: deploy the prior yolkmeet-editorial theme artifact and flush cache"
```

The previous theme artifact or git revision must be named in the deployment notes before the change is applied.

## Auto Ads Rollback

Auto ads rollback is primarily account-side:

1. Disable Auto ads or selected formats in the AdSense dashboard.
2. Keep manual live units disabled in the theme.
3. Keep `_yolkmeet_show_ad_placeholders` false unless QA intentionally enables placeholders.
4. Re-run:

```bash
SITE_URL=https://www.yolkmeet.com bash infra/adsense-preflight.sh
```

Site-side Auto ads rollback should not remove the head script unless AdSense review instructions change.

## Hourly Automation Deployment

The hourly queue must run in dry-run mode until the site owner explicitly changes the policy:

```bash
bash infra/hourly-publishing-queue.sh --dry-run --candidate tests/fixtures/hourly-publishing/valid-draft.md --output-dir .omo/evidence/hourly-deploy-smoke
```

Disable hourly scheduler:

```bash
bash infra/hourly-publishing-queue.sh --dry-run --rollback-scheduler --output-dir .omo/evidence/task-11-rollback-dry-run
```

Expected rollback receipt: the command reports that it would disable hourly scheduler, would not delete content, and would not modify WordPress posts.

## Live QA

After deployment, capture:

- homepage HTTP status
- robots and sitemap status
- one article URL status
- AdSense preflight output
- desktop and mobile screenshots where browser tooling is available
- evidence that the quick answer appears before any visible ad-like element
- evidence that no table, source note, FAQ answer, or CTA is overlapped by Auto ads

## Failure Handling

- If content gate fails: stop import and return the candidate to draft review.
- If SEO/AEO/GEO gate fails: do not schedule the page.
- If AdSense preflight has a critical FAIL: do not submit or expand ads.
- If invalid traffic appears: pause traffic pushes and document the anomaly.
- If scheduler rollback is needed: run the dry-run rollback command first, then disable the real cron/systemd unit outside this repo with an operator note.
