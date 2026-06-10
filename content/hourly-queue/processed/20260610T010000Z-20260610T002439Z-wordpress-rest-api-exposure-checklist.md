---
title: "WordPress REST API Exposure Checklist"
slug: "wordpress-rest-api-exposure-checklist"
target_keyword: "WordPress REST API exposure checklist"
meta_title: "WordPress REST API Exposure Checklist"
meta_description: "Use this WordPress REST API exposure checklist to review public routes, user data, plugin endpoints, auth, and crawl signals."
template: "operator checklist"
publishing_approval: "approved"
analysis_note: "Source-derived analysis based on the WordPress REST API handbook, REST API reference, discovery, authentication, users endpoint, WordPress roles documentation, and Google crawl/index guidance."
update_policy: "Review every 60 days; recheck WordPress REST API, authentication, users, roles, plugin endpoint, robots, and noindex documentation before updating."
source_urls:
  - "https://developer.wordpress.org/rest-api/"
  - "https://developer.wordpress.org/rest-api/reference/"
  - "https://developer.wordpress.org/rest-api/using-the-rest-api/discovery/"
  - "https://developer.wordpress.org/rest-api/using-the-rest-api/authentication/"
  - "https://developer.wordpress.org/rest-api/reference/users/"
  - "https://wordpress.org/documentation/article/roles-and-capabilities/"
  - "https://developers.google.com/search/docs/crawling-indexing/robots/intro"
  - "https://developers.google.com/search/docs/crawling-indexing/block-indexing"
internal_links:
  - "wordpress-security-checklist-for-blogs"
  - "wordpress-user-role-audit-checklist"
  - "wordpress-site-health-review-checklist"
  - "webhook-intake-workflow"
  - "wordpress-sitemap-noindex-checklist"
---

# WordPress REST API Exposure Checklist

## Quick Answer
A WordPress REST API exposure checklist should identify which public REST routes exist, which plugins add routes, whether user and content endpoints expose only expected public data, which requests require authentication, and whether crawl or indexing controls are being used for the right job. For a small WordPress publisher, the best fit is a lightweight quarterly review of `/wp-json/`, user roles, application password ownership, plugin endpoints, Site Health warnings, and source notes. Do not disable the REST API blindly; the block editor, themes, plugins, and integrations may depend on it.

## REST API Review Matrix
| Review area | What to inspect | Better operator decision |
| --- | --- | --- |
| Route discovery | `/wp-json/` index and namespaces | Identify core, theme, and plugin routes before changing anything |
| Content endpoints | Posts, pages, media, taxonomies, and comments routes | Confirm the public data matches the site publishing model |
| User endpoint | Public author data and role expectations | Pair with a user-role audit before changing author accounts |
| Authentication | Cookie auth, application passwords, and write behavior | Restrict write actions through roles, credentials, and permissions |
| Plugin routes | Vendor plugin namespaces and custom endpoints | Review plugin ownership and whether private actions require auth |
| Crawl controls | robots.txt, noindex, and password protection | Use each control for the correct search or access problem |
| Evidence notes | Checked URLs, owner, date, and decision | Leave enough context for the next operator to repeat the review |

## Who Should Use This Checklist?
Use this checklist when a WordPress publisher, creator business, or small editorial operator wants to understand the REST API surface before adding automations, webhook intake, mobile editing apps, custom blocks, headless front ends, membership plugins, or external publishing tools. It is site-operations content, not a penetration test, legal compliance review, or managed security service.

The WordPress REST API provides endpoints for built-in data types such as posts, pages, taxonomies, and users. It is also a foundation for the block editor and can be extended by themes, plugins, and custom code. That means public JSON routes are not automatically a defect. The real operator question is narrower: does the site expose the routes it needs, and are private or write actions protected by the right WordPress permissions and authentication paths?

A useful review has three limits. First, it documents observed public routes without dumping private payloads into article notes. Second, it separates search visibility from access control; robots.txt and noindex are not substitutes for authentication. Third, it records the decision so a future theme, plugin, or automation change can be reviewed against the same baseline.

## Step 1: Inventory The REST API Surface
Start with route discovery, not a plugin setting. The WordPress REST API discovery documentation describes the API root as a place where a client can discover available routes and authentication information. For an operator checklist, that means the first note should be a route inventory.

- [ ] Record the site URL and the `/wp-json/` root checked.
- [ ] Record the review date and operator.
- [ ] List visible namespaces such as core WordPress routes, theme routes, SEO plugin routes, form plugin routes, commerce routes, or custom namespaces.
- [ ] Mark whether each namespace is core, theme, plugin, or custom code.
- [ ] Mark whether the route appears read-only, write-capable, or unknown from public documentation.
- [ ] Link each plugin route back to the plugin owner or documentation.
- [ ] Record any route that looks unrelated to the current publishing stack.

Do not paste large JSON responses into the public article. A short route table is enough. The goal is to know which systems are adding surfaces, not to publish a complete map of every endpoint and parameter.

## Step 2: Separate Public Content From Private Actions
WordPress REST API reference pages document endpoints for public content objects, including posts, pages, media, comments, categories, tags, and users. Some routes are expected because a normal WordPress site publishes public content. The risky review pattern is treating every route as a private leak.

Use this decision table:

| Route type | Usually expected on a public site | Review question |
| --- | --- | --- |
| Posts and pages | Yes | Does the JSON expose published content that already appears on the site? |
| Media | Often | Are attachment titles, captions, and file URLs intentional? |
| Categories and tags | Often | Do taxonomy names match the public editorial structure? |
| Users | Sometimes | Does public author data align with author-bio and role decisions? |
| Comments | Depends on comment settings | Are moderation and comment-spam policies still current? |
| Plugin routes | Depends on plugin purpose | Does the route serve a visible feature or private workflow? |
| Write actions | No, not for anonymous users | Does the route require authentication and the right capability? |

This framing keeps the checklist practical. A public article endpoint is normal for many WordPress sites. An unauthenticated route that changes content, exposes private operational data, or belongs to a disabled workflow deserves follow-up.

## Step 3: Review User Data With Roles In Mind
The WordPress users endpoint documents a route for retrieving users, and WordPress roles documentation explains that roles map users to capabilities. For publishers, the practical review is not only whether a user route exists. It is whether public author identity, display names, bios, slugs, and roles match the editorial model.

Use this user review checklist:

- [ ] Confirm which accounts are meant to be public authors.
- [ ] Confirm display names do not reveal private login naming conventions.
- [ ] Pair public author pages, author bios, and REST user data in one review.
- [ ] Check whether administrator accounts are also public authors.
- [ ] Review stale contributors, former contractors, and shared editorial accounts.
- [ ] Confirm role assignments against the `wordpress-user-role-audit-checklist`.
- [ ] Record whether a change belongs in profile cleanup, role cleanup, or theme output.

Avoid overclaiming. A public author name is not automatically a security issue when the author appears on posts. The better choice is consistency: public author information should be intentional, current, and aligned with the site's editorial trust signals.

## Step 4: Check Authentication And Application Password Ownership
The REST API authentication documentation describes cookie authentication for dashboard sessions and application passwords for authenticated API requests over HTTPS. For a small publisher, application passwords are useful only when ownership and purpose are visible.

Review these fields:

- [ ] Which user owns each application password.
- [ ] Which integration needs it.
- [ ] Whether the user role is broader than the integration requires.
- [ ] Whether the integration still exists.
- [ ] Whether the credential has a dated owner note.
- [ ] Whether the workflow can be replaced with a lower-risk route, manual step, or narrower user role.

This is an operations review, not a secret-handling tutorial. Do not publish password values, tokens, Basic Auth headers, screenshots containing credentials, or private request logs. Public content should say that authenticated write behavior needs role and credential review; the private runbook should hold the actual credential inventory.

## Step 5: Connect Plugin Routes To Plugin Ownership
Plugins can add REST routes for blocks, forms, SEO features, commerce features, membership features, analytics, and custom dashboards. A plugin route is not automatically bad, but an orphaned plugin route is an operator smell.

Use this plugin route checklist:

- [ ] Match each non-core namespace to an active plugin, theme, or custom package.
- [ ] Record whether the feature is still used on the public site.
- [ ] Check whether the plugin is maintained, updated, and owned by a current operator.
- [ ] Review whether private actions require authentication and a permissions callback.
- [ ] Confirm the route does not duplicate a disabled workflow.
- [ ] Check Site Health after plugin updates, especially if the editor, loopback, or REST API warnings appear.
- [ ] Add a follow-up ticket instead of changing production routes during the inventory.

For custom routes, developers should rely on explicit permission checks for private behavior. For non-developer operators, the safe action is to identify ownership and route the review to the maintainer rather than editing code from a public checklist.

## Step 6: Do Not Confuse Crawl Controls With Access Controls
Google's robots.txt documentation says robots.txt controls crawler access and is not a mechanism for keeping a page out of Google. Google's noindex documentation says a noindex rule must be visible to crawlers, and blocked pages may prevent crawlers from seeing that rule. For REST API review, this distinction matters.

| Goal | Better control | Why |
| --- | --- | --- |
| Reduce crawler load on an API path | robots.txt can be considered | It tells compliant crawlers where they may crawl |
| Keep a URL out of search results | noindex or removal workflow | robots.txt alone is not an indexing guarantee |
| Keep private data private | Authentication, permissions, or no public route | Search controls do not protect private data |
| Hide a staging or private environment | Password protection or access restriction | The issue is access, not search presentation |
| Consolidate duplicate public URLs | Canonical and internal-link cleanup | robots.txt is not a canonicalization tool |

If a REST route exposes data that should not be public, fix access or data exposure. Do not rely on robots.txt to make private information safe. If a route is public but creates crawl noise, document the crawl decision separately from the security decision.

## Step 7: Keep The Evidence Small And Repeatable
A good REST API exposure review should leave a short, repeatable record. It should not become a public dump of endpoint output.

Use this evidence format:

| Field | Example note |
| --- | --- |
| Review date | `2026-06-10` |
| Surface | `/wp-json/` route index |
| Namespaces | `wp/v2`, theme namespace, SEO plugin namespace |
| User review | Public author display names aligned with author bio policy |
| Authentication review | Application passwords reviewed in private runbook |
| Crawl review | No robots or noindex change made from public checklist |
| Follow-up | Plugin owner to review unused namespace |

Store private route output, credentials, screenshots, and logs outside the public article. The article can explain the method. The operator evidence should stay in the internal runbook or ticket system.

## What Should A WordPress REST API Exposure Review Include?
A WordPress REST API exposure review should include the API root checked, visible route namespaces, public content endpoints, user data expectations, plugin route ownership, write-route authentication, application password ownership, role alignment, crawl-control decisions, evidence date, and follow-up owner. The practical order is: inventory `/wp-json/`, separate public content from private actions, review users and roles, check authentication ownership, map plugin routes, separate crawl controls from access controls, then record a small evidence note.

For most publishers, the better choice is not to disable the REST API. The better choice is to understand which public data is intentional, which private actions require authenticated capability checks, and which plugin or automation owner should review any unexpected route.

## Common Questions

### Is the WordPress REST API a security problem by itself?
No. The REST API is a normal part of modern WordPress and supports core features, the block editor, plugins, themes, and integrations. The review should focus on unexpected data exposure, unauthenticated write actions, stale plugin routes, and poorly owned credentials.

### Should I block `/wp-json/` in robots.txt?
Not as a default security fix. Robots.txt can manage crawler access, but it is not access control and is not a reliable way to keep private information out of search. Fix permissions or data exposure when the data should be private.

### Why does the users endpoint matter for publishers?
Author identity is part of editorial trust. Public user data should match intentional author bios, display names, and role assignments. If administrator accounts appear as public authors only because of old posts or shared accounts, route the fix through profile and role cleanup.

### Do application passwords mean every REST API request is risky?
No. Application passwords are an authentication method for API requests over HTTPS. The operator risk is unmanaged ownership: credentials tied to stale users, broad roles, unknown integrations, or missing review notes.

### How often should a publisher review REST API exposure?
Review every 60 days, after installing or removing a plugin, after adding a form, membership, SEO, analytics, or automation plugin, after user-role changes, after Site Health reports REST API issues, and before launching a headless or external publishing workflow.

## Source Notes
- https://developer.wordpress.org/rest-api/ checked 2026-06-10; used for source-derived analysis of the REST API purpose, JSON data model, core data types, block editor relationship, and integration surface.
- https://developer.wordpress.org/rest-api/reference/ checked 2026-06-10; used for source-derived analysis of endpoint reference coverage, parameters, response data, and built-in REST route families.
- https://developer.wordpress.org/rest-api/using-the-rest-api/discovery/ checked 2026-06-10; used for source-derived analysis of API discovery, route indexing, and authentication information exposed through the API root.
- https://developer.wordpress.org/rest-api/using-the-rest-api/authentication/ checked 2026-06-10; used for source-derived analysis of cookie authentication, dashboard sessions, HTTPS application passwords, and authenticated request ownership.
- https://developer.wordpress.org/rest-api/reference/users/ checked 2026-06-10; used for source-derived analysis of the users endpoint, user collection retrieval, request shape, and public author review concerns.
- https://wordpress.org/documentation/article/roles-and-capabilities/ checked 2026-06-10; used for source-derived analysis of WordPress roles, capabilities, administrators, editors, authors, contributors, subscribers, and role-based decisions.
- https://developers.google.com/search/docs/crawling-indexing/robots/intro checked 2026-06-10; used for source-derived analysis of robots.txt as a crawler access control, not a mechanism for keeping pages out of Google.
- https://developers.google.com/search/docs/crawling-indexing/block-indexing checked 2026-06-10; used for source-derived analysis of noindex behavior, crawler visibility, and why blocked crawling can prevent noindex from being seen.

No private WordPress dashboard, REST API response dump, application password, access token, server log, plugin configuration, Search Console property, security scanner, crawl log, or production account was inspected for this article. If a future operator adds screenshots, route exports, HTTP traces, user inventories, plugin audits, or Site Health captures, attach those artifacts in the internal runbook and narrow public claims to match the evidence.

## Internal Link Notes
Link to `wordpress-security-checklist-for-blogs` when the review produces broader access or maintenance follow-up. Link to `wordpress-user-role-audit-checklist` when public user data does not match role ownership. Link to `wordpress-site-health-review-checklist` when REST API warnings appear in Site Health. Link to `webhook-intake-workflow` when custom routes receive external events. Link to `wordpress-sitemap-noindex-checklist` when the issue is search visibility rather than access control.

## Update Note
Review this checklist every 60 days. Recheck official WordPress REST API, discovery, authentication, users, roles, plugin route, Google robots.txt, and Google noindex documentation before changing the workflow. Refresh earlier after a WordPress core update, plugin install, plugin removal, custom endpoint launch, application password change, user-role change, Site Health REST API warning, crawler spike, or headless publishing integration.
