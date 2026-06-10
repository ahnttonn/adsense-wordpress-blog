---
title: "WordPress Site Health Review Checklist"
slug: "wordpress-site-health-review-checklist"
target_keyword: "WordPress Site Health review checklist"
meta_title: "WordPress Site Health Review Checklist"
meta_description: "Use this WordPress Site Health review checklist to triage critical issues, update risk, server notes, debug exposure, and follow-up evidence."
template: "operator checklist"
publishing_approval: "approved"
analysis_note: "Source-derived analysis based on official WordPress Site Health, maintenance, updating, and debugging documentation."
update_policy: "Review every 90 days; recheck WordPress Site Health, maintenance, updating, and debugging documentation before changing the workflow."
source_urls:
  - "https://wordpress.org/documentation/article/site-health-screen/"
  - "https://wordpress.org/documentation/site-health/"
  - "https://wordpress.org/documentation/article/wordpress-site-maintenance/"
  - "https://wordpress.org/documentation/article/updating-wordpress/"
  - "https://developer.wordpress.org/advanced-administration/debug/debug-wordpress/"
internal_links:
  - "wordpress-plugin-update-checklist"
  - "wordpress-backup-restore-checklist"
  - "wordpress-security-checklist-for-blogs"
  - "wordpress-cache-clearing-checklist"
  - "uptime-monitoring-for-wordpress"
  - "wordpress-https-migration-checklist"
---

# WordPress Site Health Review Checklist

## Quick Answer
A WordPress Site Health review checklist should turn the Tools > Site Health screen into a repeatable operations review: record critical issues first, separate recommended improvements from urgent work, export the Info tab before risky changes, map each finding to a backup, update, host, plugin, theme, cache, or debug follow-up, and avoid claiming a fix until the same warning has been rechecked. For a small publishing site, Site Health is best used as a triage board, not as an automatic repair button.

## Site Health Triage Matrix
| Finding type | First operator action | Better follow-up |
| --- | --- | --- |
| Critical issue | Record the exact warning and affected area | Fix only after backup or host/plugin owner is clear |
| Recommended improvement | Add to maintenance queue | Batch with related plugin, PHP, cache, or HTTPS work |
| Passed test | Keep as baseline evidence | Recheck after updates, migrations, and plugin changes |
| Info tab value | Export or copy before changes | Compare after the next maintenance pass |
| Debug exposure | Treat as sensitive until verified | Remove public display or public log exposure |
| Host/server limitation | Document the field and host dependency | Escalate to hosting support with exact Site Health wording |

## Who Should Use This Checklist?
Use this checklist when a WordPress operator reviews Tools > Site Health before plugin updates, theme changes, PHP changes, cache work, HTTPS migration, media troubleshooting, uptime incidents, or a routine monthly maintenance pass. It fits small editorial sites, creator publications, and operator-tech blogs that need stable publishing infrastructure without turning every warning into a rushed production change.

WordPress documentation describes Site Health as a status and information surface. The Status tab groups critical issues, recommended improvements, and passed tests. The Info tab exposes technical details about WordPress, themes, plugins, media handling, server setup, database, constants, and filesystem permissions. That makes it useful for triage, but it does not replace a backup, staging check, update plan, host ticket, or post-change verification.

For a Yolkmeet-style WordPress blog, the practical question is simple: if Site Health shows a warning, can the next operator tell whether it affects publishing reliability, search visibility, security posture, media handling, or only a future maintenance improvement? If not, the review needs a clearer checklist.

## Step 1: Capture The Review Baseline
Start by recording the review context before changing settings. A Site Health screen can change after a plugin update, cache purge, host patch, or failed update, so the baseline matters.

- [ ] Record the review date, operator, environment, and reason for the review.
- [ ] Count critical issues, recommended improvements, and passed tests.
- [ ] Copy the exact wording for each critical issue.
- [ ] Export or copy the Info tab if a risky change is planned.
- [ ] Note whether the site recently changed PHP, hosting, theme, cache, HTTPS, or plugins.
- [ ] Link the review note to the relevant maintenance, backup, or incident record.

Do not rewrite the warning in softer language. The exact Site Health wording is useful because it tells the next operator whether the finding came from WordPress core, a server check, a plugin-related check, or a configuration field.

## Step 2: Prioritize Critical Issues By Blast Radius
Critical issues deserve attention first, but they still need sorting. WordPress Site Health can surface update, communication, filesystem, debug, PHP, media, REST API, loopback, plugin, theme, and server-related warnings. Some affect public visitors immediately. Others block future updates or make troubleshooting harder.

Use this order:

1. Public exposure: debug messages, public logs, broken HTTPS, or visitor-visible errors.
2. Update blockers: inability to reach WordPress.org, background update failures, filesystem permission problems, or plugin/theme update issues.
3. Publishing blockers: media upload failures, REST API failures, loopback issues, cron-related warnings, or editor instability.
4. Platform risk: outdated PHP, missing modules, database warnings, or host-level constraints.
5. Maintenance noise: warnings that do not affect the current publishing workflow but should be queued.

This order keeps the review operational. A critical issue is not just a red label; it is a decision about what could break publishing, expose sensitive information, delay security updates, or make future maintenance unreliable.

## Step 3: Treat The Info Tab As Evidence, Not A Settings Page
The Site Health Info tab is useful because it gathers configuration facts in one place. WordPress documentation notes that the Info screen contains information about the site but does not configure those settings from that screen. That distinction matters.

Capture these fields before a maintenance pass:

| Info area | Why it matters |
| --- | --- |
| WordPress version | Confirms whether core update planning is needed |
| Home URL and Site URL | Helps detect HTTPS, host, or staging confusion |
| Permalink structure | Links Site Health review to URL and redirect workflows |
| Search engine discouragement | Connects to sitemap, noindex, and launch checks |
| Active theme | Anchors theme update and template-part review |
| Active plugins | Anchors plugin update and conflict review |
| Media handling | Helps explain upload, image-processing, and screenshot issues |
| Server and PHP | Identifies host-level constraints before blaming content |
| Filesystem permissions | Explains update and upload failures that need host action |

Choose the next action from the field, not from guesswork. If the Info tab shows a host or filesystem dependency, a content editor should not treat it like a WordPress writing problem.

## Step 4: Connect Findings To Existing Operator Workflows
Site Health is most useful when each warning routes to a known workflow.

- [ ] Plugin or theme update warning: use `wordpress-plugin-update-checklist` before changing production plugins.
- [ ] Backup dependency: use `wordpress-backup-restore-checklist` before core, theme, plugin, or filesystem work.
- [ ] Security or access warning: use `wordpress-security-checklist-for-blogs`.
- [ ] Cache or stale page warning: use `wordpress-cache-clearing-checklist`.
- [ ] HTTPS or host mismatch: use `wordpress-https-migration-checklist`.
- [ ] Downtime, loopback, or communication issue: use `uptime-monitoring-for-wordpress` and host evidence.

This prevents the Site Health review from becoming a pile of unrelated warnings. The operator should leave with a routed queue: what can be fixed now, what needs staging, what belongs to the host, and what should wait for a scheduled maintenance window.

## Step 5: Handle Debug Warnings Carefully
WordPress debugging documentation describes debug constants and notes that debug tools are intended for local testing and staging rather than normal live-site use. The Site Health screen can also warn when errors display to visitors or logs may be public.

When a debug-related warning appears:

- [ ] Record the exact warning.
- [ ] Check whether the site is production, staging, or local.
- [ ] Do not publish public error paths, stack traces, log URLs, usernames, tokens, or server paths in the article or source notes.
- [ ] Treat public error display as urgent until verified.
- [ ] Route code-level investigation to a staging-safe debugging process.
- [ ] Recheck Site Health after changing debug display or logging behavior.

Do not claim that the production site is safe just because the warning disappeared once. The better evidence is a before/after note with the setting changed, the Site Health warning rechecked, and no public error display observed.

## Step 6: Pair Update Findings With Backup And Cache Notes
WordPress updating documentation recommends backing up before update work and clearing cache after updates when caching is enabled. For an operator, that means a Site Health update warning should create a short sequence, not a one-click impulse.

Use this update sequence:

- [ ] Confirm the warning type: core, plugin, theme, PHP, filesystem, or background update.
- [ ] Confirm a recent backup exists and the restore path is known.
- [ ] Prefer staging for theme, PHP, plugin-stack, or major core changes.
- [ ] Apply updates in a small batch when possible.
- [ ] Clear cache only after the update has actually completed.
- [ ] Recheck Site Health and the public page surfaces affected by the change.
- [ ] Record remaining warnings instead of hiding them in a vague "updated" note.

This keeps update work boring. Site Health can show that work is needed, but the maintenance process still needs backup, staging, cache, and verification steps.

## Step 7: Avoid Overreacting To Recommended Improvements
Recommended improvements are useful, but they should not automatically interrupt publishing. A recommendation may represent a real performance or security improvement, a hosting limitation, a plugin-specific suggestion, or a cleanup task that can wait.

Classify each recommendation:

| Recommendation class | Queue decision |
| --- | --- |
| Blocks updates or publishing | Promote to current maintenance pass |
| Public visitor risk | Treat as urgent after backup evidence |
| Host-controlled setting | Prepare a host ticket with Info tab fields |
| Plugin or theme cleanup | Batch with plugin or theme review |
| Performance hygiene | Schedule with cache and page-experience work |
| Informational only | Keep as baseline, do not churn settings |

The better choice is to schedule related fixes together. Changing PHP, clearing cache, updating plugins, and editing theme files in the same rushed pass makes it harder to know which change fixed or broke the site.

## What Should A WordPress Site Health Review Checklist Include?
A WordPress Site Health review checklist should include the review date, reason, critical issue count, recommended improvement count, passed-test baseline, Info tab export, exact warning text, owner, risk class, follow-up workflow, backup requirement, staging requirement, and recheck result. The checklist should also separate findings that the WordPress operator can handle from host-controlled issues such as server modules, PHP configuration, filesystem permissions, and blocked external requests.

For a small publisher, the practical sequence is: capture the baseline, route critical issues first, export Info before risky changes, pair updates with backup and cache notes, handle debug exposure carefully, and recheck the same Site Health screen after each maintenance pass.

## Common Questions

### Is WordPress Site Health a replacement for uptime monitoring?
No. Site Health can identify configuration and maintenance issues, but uptime monitoring checks whether the public site is reachable over time. Use both: Site Health for configuration triage and uptime monitoring for external availability.

### Should every Site Health recommendation be fixed immediately?
No. Critical public exposure and update blockers should be prioritized, but many recommended improvements can be batched into scheduled maintenance. Classify by blast radius before changing settings.

### Can the Info tab prove that a site is configured correctly?
Not by itself. The Info tab records useful configuration facts, but it is not a full QA pass. Pair it with public page checks, backup notes, cache review, plugin review, and update verification.

### What if Site Health reports a host or server issue?
Record the exact warning and the relevant Info tab fields, then route it to the host or server owner. Do not mask a host-controlled issue as an editorial content problem.

### Should debug mode be enabled on a live WordPress site?
WordPress debugging documentation frames debug tools as local or staging tools rather than normal live-site behavior. If a live site shows public debug output or public logs, treat it as sensitive and recheck after the configuration is corrected.

## Source Notes
- https://wordpress.org/documentation/article/site-health-screen/ checked 2026-06-08; used for source-derived analysis of Site Health Status, Info, critical issues, recommended improvements, passed tests, debug warnings, update warnings, and Info tab fields.
- https://wordpress.org/documentation/site-health/ checked 2026-06-08; used for source-derived analysis of Site Health as a feature for keeping a WordPress site healthy, up to date, and maintained.
- https://wordpress.org/documentation/article/wordpress-site-maintenance/ checked 2026-06-08; used for source-derived analysis of recurring WordPress maintenance planning and update review habits.
- https://wordpress.org/documentation/article/updating-wordpress/ checked 2026-06-08; used for source-derived analysis of backup-before-update behavior, failed update handling, and cache clearing after updates.
- https://developer.wordpress.org/advanced-administration/debug/debug-wordpress/ checked 2026-06-08; used for source-derived analysis of WP_DEBUG, WP_DEBUG_LOG, WP_DEBUG_DISPLAY, and the staging/local caution around debugging.

No private WordPress admin inspection, Site Health export, production URL test, server-log review, backup restore, plugin update, theme update, PHP change, cache purge, host ticket, Search Console inspection, or live security audit is claimed here. If a future operator adds screenshots, Site Health exports, host replies, HTTP traces, or before/after evidence, attach those artifacts and update the claims to match the evidence.

## Internal Link Notes
Link to `wordpress-plugin-update-checklist` when Site Health reports plugin or theme update warnings. Link to `wordpress-backup-restore-checklist` before any update, filesystem, or debug configuration change. Link to `wordpress-security-checklist-for-blogs` when the warning involves public debug output, access, outdated software, or sensitive exposure. Link to `wordpress-cache-clearing-checklist` after update work or stale front-end behavior. Link to `uptime-monitoring-for-wordpress` when a communication, loopback, cron, or external availability issue needs outside monitoring. Link to `wordpress-https-migration-checklist` when Site Health fields expose HTTP, HTTPS, host, or URL mismatch work.

## Update Note
Review this checklist every 90 days. Recheck official WordPress Site Health, maintenance, updating, and debugging documentation. Refresh earlier after a WordPress core release, PHP version change, host migration, plugin stack change, theme change, cache configuration change, debug configuration change, failed update, or recurring Site Health warning.
