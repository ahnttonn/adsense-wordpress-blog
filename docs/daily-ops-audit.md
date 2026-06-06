# Daily Ops Audit

Generated: 2026-06-06

## Decision

The daily ops audit is read-only by default. It checks whether YOLKMEET is healthy enough to keep publishing and monetization work moving, then records evidence. It should create an ULW plan only if a concrete issue or bounded backlog item is found.

## Entry Point

```bash
bash infra/daily-ops-audit.sh
```

Evidence is written under:

```text
.omo/evidence/daily-ops/
```

## Daily Checks

- Tail the hourly cron log.
- Count `content/hourly-queue/ready`, `processed`, and `blocked`.
- Count `content/distribution-queue/ready`, `processed`, and `blocked`.
- Check homepage, sitemap, robots.txt, and one representative post with HTTP.
- Check trust pages when HTTP is enabled.
- Review invalid-traffic and artificial-traffic policy terms in docs.
- Verify no manual ad slots or visible ad placeholders were introduced.
- List growth briefs awaiting manual review in `content/distribution-queue/ready`.

## Escalation Rules

- If no actionable issue is found, leave the repo unchanged and record evidence only.
- If a bounded repair is needed, create a small `.omo/plans/daily-ops-YYYY-MM-DD.md` plan first.
- Use `omo:start-work` only after the bounded plan exists and the repair touches at most three product files plus tests/docs.
- If the issue is broad, account-gated, monetization-strategy-changing, or requires Google/Bing/AdSense account actions, create the ULW plan only and do not execute repair work.

## Stop Conditions

- The audit must not mutate WordPress.
- The audit must not publish content.
- The audit must not submit URLs to IndexNow.
- The audit must not change cron schedules.
- The audit must not add manual ad slots.
- The audit must not generate proxy, VPN, bot, paid-to-click, click-exchange, or manufactured-session traffic.

## Manual Review Queues

- `content/hourly-queue/ready/`: approved candidates waiting for cron consumption.
- `content/hourly-queue/blocked/`: candidates needing editorial or technical repair.
- `content/distribution-queue/ready/`: manual-review growth briefs.
- `content/distribution-queue/blocked/`: rejected growth briefs with policy, freshness, or fit concerns.
