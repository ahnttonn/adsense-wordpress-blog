---
title: "WordPress PHP Version Upgrade Checklist"
slug: "wordpress-php-version-upgrade-checklist"
target_keyword: "WordPress PHP version upgrade checklist"
meta_title: "WordPress PHP Version Upgrade Checklist"
meta_description: "Use this WordPress PHP version upgrade checklist to plan compatibility, backups, staging checks, host changes, and post-upgrade evidence."
template: "operator checklist"
publishing_approval: "approved"
analysis_note: "Source-derived analysis based on official WordPress PHP compatibility, hosting environment, Site Health, upgrade, backup, and PHP supported-version documentation."
update_policy: "Review every 60 days; recheck WordPress PHP compatibility, hosting environment, Site Health, upgrade, backup, and PHP supported-version documentation before updating."
source_urls:
  - "https://make.wordpress.org/core/handbook/references/php-compatibility-and-wordpress-versions/"
  - "https://make.wordpress.org/hosting/handbook/server-environment/"
  - "https://wordpress.org/documentation/article/site-health-screen/"
  - "https://developer.wordpress.org/advanced-administration/performance/php/"
  - "https://developer.wordpress.org/advanced-administration/upgrade/upgrading/"
  - "https://developer.wordpress.org/advanced-administration/security/backup/"
  - "https://www.php.net/supported-versions.php"
internal_links:
  - "wordpress-site-health-review-checklist"
  - "wordpress-backup-restore-checklist"
  - "wordpress-plugin-update-checklist"
  - "wordpress-staging-site-checklist"
  - "wordpress-plugin-conflict-troubleshooting-checklist"
---

# WordPress PHP Version Upgrade Checklist

## Quick Answer
A WordPress PHP version upgrade checklist should confirm the current WordPress version, current PHP version, target PHP version, plugin and theme compatibility, backup status, staging parity, host change path, cache plan, and rollback owner before production changes. For a small publisher, the best fit is a staged upgrade: read the WordPress compatibility matrix, choose a currently supported PHP branch, back up files and database, switch PHP in staging first, review Site Health, then repeat the change in production with a short evidence note. Do not treat a PHP upgrade as a one-click content task; it changes the runtime that every theme, plugin, cron event, REST request, and admin screen depends on.

## PHP Upgrade Decision Matrix
| Decision area | What to check | Better operator action |
| --- | --- | --- |
| WordPress core version | Compatibility matrix and release notes | Upgrade WordPress first when the current core version is too old for the target PHP branch |
| PHP support status | PHP active or security-support window | Prefer a branch still supported by PHP and compatible with the site's WordPress version |
| Plugin stack | Active plugins, forms, SEO, cache, editor, and custom code | Update and review plugins before changing production PHP |
| Theme stack | Active theme, child theme, template edits, block patterns | Check front-end layout and editor behavior in staging |
| Backup path | Database, files, uploads, `wp-config.php`, and restore owner | Do not proceed until restore evidence exists |
| Staging parity | Same WordPress version, key plugins, theme, cache layer, and PHP target | Use staging for the runtime switch before production |
| Production window | Low-traffic time, owner, host panel path, and rollback version | Make the change when someone can recheck and revert |
| Evidence note | Before value, target value, warnings, result, and follow-up | Keep a short record for future upgrades |

## Who Should Use This Checklist?
Use this checklist when a WordPress publisher, AdSense-focused blog operator, creator publication, or small editorial team needs to move away from an outdated PHP version without turning the change into a broad hosting migration. It is site-operations content, not managed hosting advice, professional security consulting, or a guarantee that every plugin will behave the same after a runtime change.

PHP is the server-side language WordPress runs on. WordPress performance documentation explains that PHP version and configuration affect whether WordPress runs well, and the official PHP project publishes support windows for active support, security fixes, and end-of-life branches. WordPress also maintains compatibility references because WordPress core, themes, and plugins do not all move at the same speed.

The operator decision is not simply "newer is always better today." The safer question is: which currently supported PHP branch is compatible with this WordPress core version, plugin stack, theme, host, and rollback plan?

## Step 1: Capture The Current Runtime
Start with inventory, not the host control panel switch. The WordPress Site Health screen includes configuration information such as WordPress version, active theme, plugins, server details, database details, HTTPS status, and warnings. Capture enough of that baseline to know what changed if the upgrade causes a problem.

- [ ] Record the WordPress version.
- [ ] Record the current PHP version.
- [ ] Record the target PHP version.
- [ ] Record the active theme and whether a child theme is used.
- [ ] Record active plugins, especially cache, SEO, forms, security, analytics, page builder, editor, and custom-code plugins.
- [ ] Record the host panel path or support request path used to change PHP.
- [ ] Record the owner who can revert the change.
- [ ] Record any existing Site Health warnings before the upgrade.

Do not clean up every warning during this step. A baseline is useful because it preserves the before state. If the site already has a loopback, REST API, cron, file permission, or debug warning, note it before changing PHP so it does not get blamed on the upgrade without evidence.

## Step 2: Choose A Compatible Target Version
The WordPress PHP compatibility table maps WordPress versions to PHP branches. The WordPress hosting handbook also summarizes current production recommendations and notes where old PHP branches are supported only for backward compatibility. The PHP supported-versions page separates active support, security-only support, and end-of-life branches.

Use this decision table:

| Situation | Better choice |
| --- | --- |
| Current WordPress is old | Plan a WordPress core update path before jumping to a new PHP branch |
| Current PHP is end-of-life | Schedule an upgrade, but still stage it first |
| Target PHP is new and compatible with current core | Check plugin, theme, and host support before production |
| Host offers multiple PHP branches | Pick the newest branch that the site stack can support confidently |
| Host only offers one supported branch | Treat the change like a host-controlled maintenance item and capture rollback details |

For a small WordPress publisher, a practical target is the newest PHP branch that is supported by the PHP project, compatible with the installed WordPress version, offered by the host, and accepted by key plugins and the active theme. Avoid choosing a branch only because it appears at the top of a dropdown.

## Step 3: Update The Site Before The Runtime Switch
Many PHP problems surface through plugins and themes. A site can pass a basic WordPress compatibility check and still break because an old plugin, custom template, or abandoned theme calls PHP behavior that changed. Pair the PHP upgrade with normal maintenance, but keep the order controlled.

- [ ] Review pending WordPress core updates.
- [ ] Review pending plugin updates.
- [ ] Review pending theme updates.
- [ ] Read plugin changelogs when the plugin handles forms, cache, SEO, membership, payments, analytics, or custom fields.
- [ ] Remove inactive plugins only if that cleanup is already approved and reversible.
- [ ] Confirm the active theme is maintained.
- [ ] Check whether the host has PHP extension requirements for the target branch.
- [ ] Avoid changing PHP, theme, plugins, permalink structure, and cache rules all in the same undocumented pass.

This is where internal links matter. Use the `wordpress-plugin-update-checklist` before changing production plugins, the `wordpress-staging-site-checklist` before runtime changes, and the `wordpress-plugin-conflict-troubleshooting-checklist` if a plugin breaks after the switch.

## Step 4: Back Up Files And Database
Official WordPress upgrade guidance recommends backing up before upgrade work, and backup documentation separates database and files. A PHP change is not the same as replacing WordPress core, but it can still make the admin, theme, or plugin stack fail. The restore path should be visible before the runtime changes.

Minimum backup evidence:

| Backup item | Why it matters |
| --- | --- |
| Database export | Posts, pages, options, users, plugin settings, and menus may live in the database |
| `wp-content` files | Themes, plugins, uploads, and custom code live outside the database |
| `wp-config.php` reference | PHP, database, debugging, and environment constants may affect recovery |
| Restore owner | Someone must know how the backup becomes a working site again |
| Backup timestamp | Confirms the backup is recent enough for the upgrade window |

Do not publish private backup locations, database names, credentials, server paths, or file listings in a public article. The article can describe the evidence fields. The actual restore artifact belongs in the operator runbook.

## Step 5: Switch PHP In Staging First
If a staging environment exists, change PHP there before production. WordPress PHP performance documentation recommends compatibility checks before upgrading and notes that staging and production should be configurable separately when multiple environments exist. For operators, staging is where the breakage list becomes concrete.

Staging review checklist:

- [ ] Admin dashboard loads.
- [ ] Block editor opens and saves a draft.
- [ ] Home page loads.
- [ ] A recent post loads.
- [ ] Search results load.
- [ ] Category or tag archive loads.
- [ ] Contact or form page loads if the site has forms.
- [ ] Sitemap URL loads.
- [ ] RSS feed loads if feeds are part of the workflow.
- [ ] REST API root loads if integrations depend on it.
- [ ] Scheduled-post or cron-sensitive workflow is reviewed if the site uses scheduled publishing.
- [ ] Site Health is rechecked after the PHP switch.
- [ ] Error display is not visible to visitors.

Keep the staging note small. A table with URL, expected behavior, observed behavior, and follow-up is better than a long screenshot dump. If the result exposes credentials, private user data, or server paths, keep it out of public content.

## Step 6: Make The Production Change With A Rollback Window
Once staging is acceptable, schedule production during a quiet period. The better production plan has one owner, one target PHP value, one rollback value, and a short list of public checks. Do not leave the change half-owned between the editor, host, developer, and plugin vendor.

Production sequence:

1. Confirm backups are recent.
2. Confirm staging result is recorded.
3. Confirm target PHP branch and rollback branch.
4. Pause unrelated plugin, theme, and content changes during the window.
5. Switch PHP in the host panel or approved host workflow.
6. Clear only the cache layers needed to see the current site.
7. Recheck public pages, admin, editor, sitemap, feed, and critical forms.
8. Recheck Site Health.
9. Record warnings, rollback decision, and follow-up owner.

The best fit is a short maintenance window with active review, not a background change that nobody checks until the next publishing incident.

## What Should A WordPress PHP Upgrade Checklist Include?
A WordPress PHP upgrade checklist should include current WordPress version, current PHP version, target PHP version, PHP support status, WordPress compatibility status, host change path, plugin and theme review, backup evidence, staging result, production window, cache note, public-page checks, Site Health recheck, rollback value, owner, and update log. The practical order is: capture the current runtime, choose a compatible target, update the site stack, back up files and database, switch staging first, switch production during a watched window, then record evidence.

For most publishers, the better choice is to upgrade deliberately rather than delay until the host forces a PHP change. A planned PHP upgrade gives the operator time to test plugins, preserve a restore path, and separate runtime problems from ordinary WordPress maintenance noise.

## Common Questions

### Is a PHP upgrade the same as a WordPress core upgrade?
No. A WordPress core upgrade changes WordPress files and database behavior. A PHP upgrade changes the server runtime that runs WordPress core, themes, plugins, cron events, REST requests, and admin screens. They are related, but they need separate evidence.

### Should a small WordPress site always use the newest PHP branch?
Not automatically. Choose the newest supported PHP branch that is compatible with the installed WordPress version, supported by the host, and acceptable for the active plugin and theme stack. Very old PHP is risky, but a rushed jump without staging can also create avoidable downtime.

### What if Site Health says PHP is outdated?
Treat it as an upgrade trigger, not as permission to switch blindly. Capture the current runtime, check compatibility, update plugins and themes, back up the site, use staging when possible, then recheck Site Health after the change.

### What if the host is retiring the current PHP version?
Ask for the target branch, deadline, rollback options, and staging path. Then run the same checklist on the host's timeline. If rollback is not available, the backup and staging evidence become more important.

### What should be checked after the production PHP switch?
Check the home page, a recent post, admin dashboard, block editor, sitemap, feed, important forms, Site Health, cache behavior, and any scheduled publishing or automation workflow. Record warnings even when the site appears usable.

## Source Notes
- https://make.wordpress.org/core/handbook/references/php-compatibility-and-wordpress-versions/ checked 2026-06-10; used for source-derived analysis of WordPress/PHP compatibility tables, recent label changes, and version support relationships.
- https://make.wordpress.org/hosting/handbook/server-environment/ checked 2026-06-10; used for source-derived analysis of hosting environment recommendations, PHP branch notes, end-of-life context, and host/developer cautions.
- https://wordpress.org/documentation/article/site-health-screen/ checked 2026-06-10; used for source-derived analysis of Site Health status, Info fields, outdated PHP warnings, server details, debug warnings, loopback warnings, and configuration visibility.
- https://developer.wordpress.org/advanced-administration/performance/php/ checked 2026-06-10; used for source-derived analysis of PHP's role in WordPress, version/configuration impact, staging-first upgrade cautions, and compatibility checks.
- https://developer.wordpress.org/advanced-administration/upgrade/upgrading/ checked 2026-06-10; used for source-derived analysis of WordPress upgrade backup expectations, one-click update context, manual upgrade caution, and file areas that should not be deleted.
- https://developer.wordpress.org/advanced-administration/security/backup/ checked 2026-06-10; used for source-derived analysis of database-plus-files backup scope before operational changes.
- https://www.php.net/supported-versions.php checked 2026-06-10; used for source-derived analysis of PHP active support, security support, end-of-life status, and why support windows should be reviewed before choosing a target branch.

No private WordPress dashboard, host control panel, Site Health export, PHP switch, staging run, server log, backup restore, Search Console property, AdSense account, or production URL test is claimed here. If a future operator adds screenshots, host tickets, Site Health exports, curl traces, error logs, or before/after runtime evidence, attach those artifacts in the internal runbook and narrow public claims to match the evidence.

## Internal Link Notes
Link to `wordpress-site-health-review-checklist` when the upgrade starts from a Site Health warning. Link to `wordpress-backup-restore-checklist` before any production runtime change. Link to `wordpress-plugin-update-checklist` when plugin maintenance must happen before the PHP switch. Link to `wordpress-staging-site-checklist` when staging parity is the blocking question. Link to `wordpress-plugin-conflict-troubleshooting-checklist` if a plugin or admin screen fails after the runtime change.

## Update Note
Review this checklist every 60 days. Recheck official WordPress PHP compatibility, WordPress hosting environment, WordPress Site Health, WordPress PHP performance, WordPress upgrade, WordPress backup, and PHP supported-version documentation before changing the checklist. Refresh earlier after a WordPress core release, PHP branch support change, host PHP retirement notice, plugin-stack change, theme change, staging-environment change, or production incident after a runtime switch.
