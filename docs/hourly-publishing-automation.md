# Hourly Publishing Automation

Generated: 2026-06-06

## Decision

The hourly system is a guarded queue, not blind public auto-publishing. Every hour the system may prepare one candidate draft, run source/originality/content/SEO/AEO/GEO/policy gates, and write a WordPress draft payload. Public publish remains disabled until at least 100 approved articles have shipped and 8 weekly Search Console reports show stable quality signals.

For the next 20 approved candidates, the operator layer should bias topic selection toward underrepresented non-AI operator-tech breadth. Use this pillar priority order: WordPress/site ops, automation/no-code, analytics/reporting, creator/business tooling, light security/privacy, then AI tools. This is a selection priority only; it does not weaken publishing_approval, source, originality, SEO/AEO/GEO, or no-YMYL gates.

## Required Gates

1. Candidate file exists and is readable.
2. Candidate includes approval metadata: `publishing_approval: "approved"`.
3. `infra/content-quality-gate.sh` passes.
4. `infra/content-originality-check.sh` passes.
5. `tests/seo-aeo-geo-readiness.test.sh <candidate>` passes.
6. Payload status is `draft` while the local gate is building a review artifact.
7. After Codex/operator review gates pass, `infra/publish-hourly-payload.sh` may promote the approved payload to WordPress with `--status publish`.

## Scheduler Contract

The repository scheduler entrypoint is:

```bash
bash infra/hourly-publishing-cron.sh
```

It reads one markdown candidate per run from:

- `content/hourly-queue/ready/`

Codex/operator automation writes candidates first under:

- `content/hourly-queue/staging/`

Only fully reviewed candidates should be atomically moved into `ready/`. This prevents local cron from reading a half-written article.

It moves candidates after each run:

- passing candidates move to `content/hourly-queue/processed/`
- blocked candidates move to `content/hourly-queue/blocked/`

Each candidate still goes through the lower-level gated queue command:

```bash
bash infra/hourly-publishing-queue.sh --dry-run --candidate /path/to/candidate.md --output-dir /path/to/evidence
```

The command writes evidence under `.omo/evidence/hourly-publishing-cron/`:

- `wp-draft-payload.json`
- `hourly-publishing-queue.log`
- `stdout.log`
- `stderr.log`
- `wp-publish.log`
- `wp-publish.err`

The queue must stop if any gate fails. Failed candidates move to `blocked/` and do not create or update a WordPress post.

The local crontab line should run once per hour:

```cron
0 * * * * cd /Users/ihansol/dev/adsense-wordpress-blog && /bin/bash /Users/ihansol/dev/adsense-wordpress-blog/infra/hourly-publishing-cron.sh >> /Users/ihansol/dev/adsense-wordpress-blog/.omo/evidence/hourly-publishing-cron/cron.log 2>&1
```

The local cron uses SSH + WP-CLI, not WordPress account UI. Defaults:

- SSH host: `ubuntu@168.107.11.71`
- WordPress root: `/var/www/yolkmeet.com`
- WP-CLI user: `wpdeploy`
- promoted post status: `publish`

Override with:

```bash
YOLKMEET_WP_POST_STATUS=draft bash infra/hourly-publishing-cron.sh
YOLKMEET_AUTO_WP_PUBLISH=0 bash infra/hourly-publishing-cron.sh
```

Codex runs the operator layer hourly: create one candidate, run the gates, and atomically move the passing candidate into `content/hourly-queue/ready/`. Codex does not run the WordPress publish command. OS cron is the only process that consumes `ready/` and promotes approved candidates to WordPress through WP-CLI.

Operator selection must follow the near-term pillar priority in `docs/content-pillar-map.md` for the next 20 approved candidates. Prefer WordPress/site ops, automation/no-code, analytics/reporting, creator/business tooling, and light security/privacy until those underrepresented non-AI pillars are materially represented; use AI tools only after that breadth requirement is satisfied or when no approved non-AI candidate can pass the gates.

## Source Discovery Fallback

The operator should use existing local plans first: `docs/content-pillar-map.md`, the launch manifest, and any queue items already staged or ready. If those sources are exhausted, duplicated, stale, or cannot produce a candidate that passes gates, the operator may perform bounded source discovery for one new topic.

Allowed discovery sources:

- official product, vendor, and platform documentation
- changelogs, release notes, pricing or feature pages that are public and attributable
- WordPress plugin and documentation pages
- Google, Bing, and search-engine documentation
- public primary sources that can be cited as source URLs

Discovery constraints:

- Do not copy, paraphrase, or rewrite competitor article bodies.
- Do not use scraped copyrighted prose, paid content, or SERP snippets as article substance.
- Respect robots.txt, terms, and rate limits.
- Use crawling to identify source URLs, factual claims to verify, topic gaps, and update triggers only.
- The final article must be original Yolkmeet analysis with `source_urls`, source notes, answer structure, and no unsupported private testing claims.

## Post-Publish Growth Queue

After a candidate is published, automation may queue only policy-safe growth work. It must not generate proxy, VPN, refresh-bot, click-exchange, or manufactured-session traffic for AdSense or ranking manipulation.

Allowed post-publish actions:

- Confirm the published URL is present in `https://www.yolkmeet.com/sitemap.xml`.
- Confirm IndexNow is enabled for future publish/update/delete events.
- Record whether Bing Webmaster Tools and Search Console show discovered, indexed, crawled-not-indexed, or error states.
- Queue title, meta description, introduction, answer-block, FAQ, and table rewrites when impressions rise but CTR or query fit is weak.
- Add or queue internal links from relevant articles, category pages, and related-post blocks.
- Add or queue original templates, checklists, tables, screenshots, source notes, or update logs when a page is too thin.
- Draft human-readable social/community snippets for manual review, without spam posting, fake engagement, repeated self-referrals, or automated account activity.
- Review server logs for suspicious referral bursts before treating any traffic lift as useful growth evidence.

## Approval Metadata

`publishing_approval: "approved"` means the candidate is allowed to enter the automated operator queue. It does not bypass quality gates. Public promotion is allowed only after Codex/operator review, content quality, originality, SEO/AEO/GEO, and WP-CLI publish checks pass.

Missing approval blocks the queue because hourly automation can otherwise turn a research note into production content without review.

## Rollback

Scheduler rollback must be dry-run visible and non-destructive:

```bash
bash infra/hourly-publishing-queue.sh --dry-run --rollback-scheduler --output-dir .omo/evidence/task-11-rollback-dry-run
```

Expected result: the command reports that the hourly scheduler would be disabled, no content would be deleted, and no WordPress post would be modified.

## Stop Conditions

- Missing candidate
- Missing approval metadata
- Copied-body or originality risk
- Missing source notes
- Failed SEO/AEO/GEO gate
- Attempted `publish` status before the publish script promotion step
- Missing output directory
- Any shell error in a gate command

## Quality Threshold

Blind public auto-publish remains disabled at the low-level payload step. Public promotion is handled by the Codex/operator layer after review gates pass, with evidence captured for each run.
