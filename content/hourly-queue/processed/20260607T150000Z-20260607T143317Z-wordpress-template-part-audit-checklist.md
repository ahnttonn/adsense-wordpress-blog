---
title: "WordPress Template Part Audit Checklist"
slug: "wordpress-template-part-audit-checklist"
target_keyword: "WordPress template part audit"
meta_title: "WordPress Template Part Audit Checklist"
meta_description: "Use this WordPress template part audit checklist before changing block-theme headers, footers, sidebars, and reusable layout areas."
template: "operator checklist"
publishing_approval: "approved"
analysis_note: "Source-derived analysis based on official WordPress Site Editor, Template Editor, Template Part block, Theme Handbook template, theme.json, and Google title-link documentation."
update_policy: "Review every 90 days; recheck WordPress Site Editor, Template Editor, Template Part block, Theme Handbook template, theme.json, and Google title-link guidance."
source_urls:
  - "https://wordpress.org/documentation/article/site-editor/"
  - "https://wordpress.org/documentation/article/template-editor/"
  - "https://wordpress.org/documentation/article/template-part-block/"
  - "https://developer.wordpress.org/themes/templates/introduction-to-templates/"
  - "https://developer.wordpress.org/themes/core-concepts/global-settings-and-styles/"
  - "https://developers.google.com/search/docs/appearance/title-link"
internal_links:
  - "wordpress-theme-update-checklist"
  - "wordpress-navigation-menu-checklist"
  - "wordpress-site-identity-checklist"
  - "wordpress-block-pattern-cleanup-checklist"
  - "wordpress-internal-link-audit-checklist"
  - "core-web-vitals-for-blogs"
---

# WordPress Template Part Audit Checklist

## Quick Answer
A WordPress template part audit checks the global layout areas that repeat across a block-theme site before an operator edits, replaces, or exports the theme. The minimum audit should cover header, footer, sidebar, navigation, archive, single-post, and 404 surfaces; confirm which template parts are active; record whether each part carries site identity, navigation, source-note, ad, or trust elements; and make one reversible change at a time. The best fit for a small publisher is a short change log plus a visual pass across the page types that use the part.

## Audit Matrix
| Template area | What to check first | Better choice |
| --- | --- | --- |
| Header | Site title, logo, navigation, search, mobile menu | Keep brand and primary paths consistent across templates |
| Footer | About text, policy links, source positioning, copyright | Treat footer changes as sitewide trust changes |
| Sidebar | Related links, category navigation, stale widgets | Remove only items that are clearly unused or misleading |
| Single post | Title area, author/date display, article container | Preserve readable article starts and source-note placement |
| Archive | Category headings, excerpts, pagination, internal links | Keep query context visible before decorative elements |
| 404/search | Recovery links, search block, recent posts | Help readers recover without overloading the page |
| Reusable patterns inside parts | Synced status, naming, duplicate variants | Keep one keeper version and document why |

## Who Should Use This Checklist?
Use this checklist when a WordPress operator is changing a block theme, cleaning up a Site Editor layout, moving from one theme to another, or trying to understand why a header, footer, sidebar, or repeated content area changed across many pages at once. It fits small editorial sites, operator-tech blogs, creator publications, and documentation-style sites that rely on consistent navigation and source visibility.

This is not a design review. It is an operating review. WordPress documentation describes the Site Editor and Template Editor as places where operators can browse templates and template parts, while Theme Handbook documentation explains that templates wrap dynamic data and template parts represent reusable sections inside those templates. That means one small part can affect many page types.

For a Yolkmeet-style publishing workflow, template part work should be handled like a site operations change. The article may be original and source-backed, but readers still need the page shell to make sense: a recognizable brand, a clear title, internal paths, policy links, readable article width, and source-note placement that does not disappear after a theme edit.

## Step 1: List The Parts Before Editing
Start in the Site Editor and record the parts that exist before making a change. The useful question is not only "Which part do I want to edit?" It is "Which pages depend on this part?"

- [ ] Open the Site Editor and review the available templates and template parts.
- [ ] Name the header, footer, sidebar, and any custom content-area parts.
- [ ] Record which part appears on front page, single post, page, archive, search, and 404 templates.
- [ ] Mark whether the part is theme-provided, operator-created, or copied from an older theme.
- [ ] Note any part that includes a Navigation block, site title, site logo, search, policy link, source note, or ad-adjacent area.
- [ ] Take a short text note describing the current purpose of each part.

The goal is reversibility. If the operator cannot say which templates use the part, the first edit should be a documentation pass, not a visual redesign.

## Step 2: Classify The Risk Of Each Part
Not every template part carries the same risk. A footer text tweak is different from replacing the global header or deleting a synced navigation pattern.

| Risk level | Part example | Audit posture |
| --- | --- | --- |
| Low | Decorative separator or optional callout | Edit after confirming it is not repeated in critical templates |
| Medium | Sidebar, related links, archive intro | Check internal links and mobile layout before saving |
| High | Header, Navigation block, footer policy links | Review sitewide paths, brand signals, and recovery options |
| Publish-adjacent | Source notes, update log, ad container, trust area | Keep visible and do not move without article QA |
| Migration-sensitive | Parts provided by an old theme | Export or record before replacing the theme |

Choose the slowest path for high-impact parts. A header change can remove search, collapse mobile navigation, or make Google and readers see inconsistent prominent text. A footer change can hide About, contact, privacy, or editorial-policy paths. A sidebar change can break the internal-link pattern that helps readers move from one article to the next.

## Step 3: Check The Header As A Routing Surface
The header should answer three practical questions quickly: what site is this, where can the reader go next, and does the mobile version preserve those paths?

- [ ] Site title or logo is visible and links to the home page.
- [ ] Primary navigation points to durable topic areas, not only recent posts.
- [ ] Mobile menu opens, closes, and keeps labels readable.
- [ ] Search is present if the publication depends on evergreen reference content.
- [ ] The header does not push the article title too far down on mobile.
- [ ] The header does not duplicate a different site name from a previous theme.
- [ ] Large visual text does not contradict the page title or category context.

Google title-link documentation notes that prominent text can be one of the signals considered when generating title links. That does not mean operators should design headers for title-link manipulation. It means the page shell should not confuse the page topic with repeated brand or navigation text.

## Step 4: Check The Footer As A Trust Surface
The footer is easy to treat as background decoration, but on a small publisher site it often carries the paths readers and review systems need.

- [ ] About, contact, privacy, and editorial-policy links are still present.
- [ ] Footer wording matches the current site positioning.
- [ ] No old domain, old brand, placeholder text, or theme demo link remains.
- [ ] Source-aware or update-aware positioning is not hidden behind vague marketing copy.
- [ ] Copyright text and year handling are correct enough for the site.
- [ ] Footer links work on archive, post, search, and 404 templates.
- [ ] The footer does not contain affiliate, sponsored, or ad-click language.

The best fit is a plain footer that helps readers understand who runs the site, what the site covers, and how to find policy pages. Do not use the footer to stuff keywords or repeat every category.

## Step 5: Review Single-Post And Archive Templates Together
Template parts often look acceptable on one page type and awkward on another. Review single-post and archive templates as a pair because they serve different reader jobs.

For single posts:

- [ ] Article title appears before secondary clutter.
- [ ] Author, date, update note, or source note is present when the editorial system expects it.
- [ ] The article body width remains readable.
- [ ] Related links do not interrupt the first answer block.
- [ ] Any ad-adjacent area stays out of the headline and source-note flow.

For archives:

- [ ] Category or archive title explains the page context.
- [ ] Excerpts, pagination, or post lists are scannable.
- [ ] Empty or thin archives do not look like broken pages.
- [ ] Internal links help readers move into relevant guides.
- [ ] The archive does not duplicate the exact same intro across unrelated topics.

This is where the WordPress template model matters. A part that works as a footer on a single post may be too heavy on archive pages. A sidebar that helps a category page may distract from the top of a how-to article. Use the template dependency list from Step 1 before deciding where the part belongs.

## Step 6: Watch For Pattern And Part Confusion
Block-theme operators can end up with duplicated patterns, synced patterns, template parts, and edited theme defaults that look similar in the interface. Before deleting anything, identify what the item is doing.

- [ ] Template part: repeated global structure such as header, footer, or sidebar.
- [ ] Template: full page structure for a page type such as single post or archive.
- [ ] Pattern: reusable block arrangement that may appear inside content or templates.
- [ ] Synced pattern: reusable block arrangement where one edit can affect every instance.
- [ ] Theme file: code or block markup shipped by the active theme.

When in doubt, rename the keeper clearly and leave a short note in the change log. A cleanup pass should reduce confusion, not create a mystery about which part controls the public page.

## Step 7: Make One Reversible Change At A Time
The operator-safe workflow is simple: document, change, review, then continue.

- [ ] Write the intended change in one sentence.
- [ ] Save or export the current theme or note the rollback path.
- [ ] Edit one template part, not multiple global areas at once.
- [ ] Review front page, one post, one page, one archive, search, and 404.
- [ ] Check desktop and mobile widths.
- [ ] Confirm policy links, navigation, source notes, and article titles still appear.
- [ ] Record the final state and the source pages checked.

This avoids the common failure mode where an operator updates a theme, repairs the header, notices a footer problem, changes a sidebar, and then cannot tell which edit created the actual regression.

## What Should The First Audit Include?
The first audit should include a part inventory, a dependency map, and a short before-and-after note for the parts that affect the most pages.

- [ ] Header: brand, navigation, mobile menu, search.
- [ ] Footer: About, contact, privacy, editorial policy, site positioning.
- [ ] Single post: title area, metadata, source-note placement, article body.
- [ ] Archive: title, excerpt, pagination, internal paths.
- [ ] Search and 404: recovery path and useful links.
- [ ] Synced patterns inside parts: name, purpose, affected pages.
- [ ] Theme update note: what changed, what was checked, when to review again.

That is enough for a small operator-tech site. Larger teams can add screenshots, theme export artifacts, visual regression checks, or staging-site review, but those should be evidence fields rather than unsupported claims in the article.

## Common Questions

### What is the difference between a template and a template part?
A template controls the structure for a page type such as a single post, page, archive, search result, or 404 page. A template part is a reusable section inside templates, such as a header, footer, sidebar, or repeated layout area. Audit template parts carefully because one edit can appear across many templates.

### Should every block theme use the same template parts?
No. Choose the parts that match the site. A small publication usually needs a stable header, footer, single-post layout, archive layout, and recovery pages. More complex layouts are useful only when they make navigation, reading, or maintenance clearer.

### When should a template part be removed?
Remove a part only when it is unused, duplicated, misleading, or clearly replaced by a better keeper. Before deletion, confirm which templates reference it and record the replacement. If the part controls navigation, footer policy links, source notes, or article layout, treat removal as a sitewide change.

### How often should template parts be reviewed?
Review them after a theme update, brand change, navigation change, policy-page update, new ad layout, or visible page-template change. For a stable small publisher, a 90-day review is enough unless a WordPress update or theme migration changes the Site Editor behavior.

## Source Notes
- https://wordpress.org/documentation/article/site-editor/ checked 2026-06-07; used for source-derived analysis of browsing templates and template parts through the Site Editor and understanding how global editing affects site layout.
- https://wordpress.org/documentation/article/template-editor/ checked 2026-06-07; used for source-derived analysis of navigating, previewing, adding, and editing templates for different page types.
- https://wordpress.org/documentation/article/template-part-block/ checked 2026-06-07; used for source-derived analysis of the Template Part block as an advanced block for block themes and template editing.
- https://developer.wordpress.org/themes/templates/introduction-to-templates/ checked 2026-06-07; used for source-derived analysis of templates, reusable parts, and the relationship between top-level templates and partial layout sections.
- https://developer.wordpress.org/themes/core-concepts/global-settings-and-styles/ checked 2026-06-07; used for source-derived analysis of theme.json, global settings, and template-part registration in theme operations.
- https://developers.google.com/search/docs/appearance/title-link checked 2026-06-07; used for source-derived analysis of why prominent page text should stay consistent with page identity and title context.

## Internal Link Plan
Link to `wordpress-theme-update-checklist` when the audit is part of a theme change. Link to `wordpress-navigation-menu-checklist` when the header or Navigation block changes. Link to `wordpress-site-identity-checklist` when brand, logo, or site-title signals are involved. Link to `wordpress-block-pattern-cleanup-checklist` when synced patterns or reusable blocks appear inside template parts. Link to `wordpress-internal-link-audit-checklist` when archive, sidebar, or footer links change. Link to `core-web-vitals-for-blogs` when layout changes affect the article start, page weight, or ad-adjacent space.

## Update Note
Review this checklist every 90 days. Recheck official WordPress Site Editor, Template Editor, Template Part block, Theme Handbook template, and theme.json documentation. Refresh earlier if WordPress changes block-theme editing, template-part management, template creation, synced-pattern behavior, theme export flow, or if a site theme update changes how global parts render across page types.
