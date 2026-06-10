---
title: "WordPress Site Identity Checklist for Blogs"
slug: "wordpress-site-identity-checklist"
target_keyword: "WordPress site identity checklist"
meta_title: "WordPress Site Identity Checklist for Blogs"
meta_description: "Use this WordPress site identity checklist to align site title, tagline, logo, icon, homepage naming, and Google Search signals."
template: "operator checklist"
publishing_approval: "approved"
analysis_note: "Source-derived analysis based on official WordPress General settings, Site Editor, Customizer, and Google Search site-name and title-link documentation."
update_policy: "Review every 90 days; recheck WordPress General settings, Site Editor, Customizer, site icon, Google site-name, and title-link guidance."
source_urls:
  - "https://wordpress.org/documentation/article/settings-general-screen/"
  - "https://wordpress.org/documentation/article/site-editor/"
  - "https://wordpress.org/documentation/article/customizer/"
  - "https://developers.google.com/search/docs/appearance/site-names"
  - "https://developers.google.com/search/docs/appearance/title-link"
internal_links:
  - "wordpress-seo-plugin-setup"
  - "wordpress-navigation-menu-checklist"
  - "wordpress-internal-link-audit-checklist"
  - "wordpress-sitemap-noindex-checklist"
  - "wordpress-theme-update-checklist"
  - "content-refresh-workflow"
---

# WordPress Site Identity Checklist for Blogs

## Quick Answer
A WordPress site identity checklist should align the site title, tagline, logo, site icon, homepage wording, navigation label, and search metadata before the blog grows. The best fit for a small publisher is a short quarterly review: confirm the name in WordPress settings, check what the active theme displays, keep the homepage title descriptive, avoid keyword-stuffed taglines, and make the preferred site name consistent with Google Search guidance.

## Identity Map
| Surface | What to check | Better choice |
| --- | --- | --- |
| Site title | The name in WordPress General settings | Use the real publication or brand name |
| Tagline | Short explanation of the site's job | Keep it helpful, not keyword-stuffed |
| Header logo | Logo or text shown by the active theme | Match the name readers see elsewhere |
| Site icon | Browser, app, and tab identity | Use a simple icon that still works small |
| Homepage title | Search and page title signal | Describe the homepage, not just "Home" |
| Site name signals | Homepage, structured data, and title text | Keep the preferred name consistent |
| Navigation | Header and footer links | Make brand, homepage, and key pages easy to find |

## Who Should Use This Checklist?
Use this checklist when a WordPress blog has a generic title, an old tagline, a logo that no longer matches the site name, a missing site icon, or a homepage that says one thing in the header and another thing in search results. It is especially useful before a theme change, SEO plugin setup, homepage rewrite, WordPress launch, rebrand, or AdSense readiness pass.

This is a site-operations workflow, not a branding exercise. The operator goal is to make the publication easy to recognize for readers, crawlers, answer engines, and future editors. A consistent identity also reduces avoidable cleanup later: fewer duplicate homepage names, fewer theme-specific header surprises, and fewer unclear title-link rewrites to investigate.

The practical rule is simple: WordPress controls some identity fields, the active theme controls how many of them appear, and Google Search may use several homepage and page-level signals when generating site names and title links. Do not treat one setting as the whole system.

## Step 1: Record The Current Identity Before Editing
Start with a short inventory. WordPress General settings include the site title and tagline, while block themes may display or style identity elements through the Site Editor. Older or classic-theme workflows may expose logo, title, tagline, and site icon controls through the Customizer.

Record these fields before changing anything:

- Site title in WordPress settings.
- Tagline in WordPress settings.
- Header text or logo shown on the homepage.
- Site icon or favicon.
- Homepage title and H1.
- SEO plugin title template, if one is active.
- `WebSite` structured data name, if a plugin or theme outputs it.
- Header navigation label for the homepage.
- Footer name, copyright name, and social profile names.

The record does not need to be complicated. A small table with the current value, desired value, source checked, and follow-up owner is enough. The important part is seeing identity drift before it becomes a public mismatch.

## Step 2: Decide The One Preferred Site Name
Choose one preferred name before touching taglines, logos, or SEO templates. Google Search site-name guidance favors a unique, concise, non-misleading name, and it also recommends consistency across the home page and site-name signals.

Use this decision table:

| Site state | Best name choice | Avoid |
| --- | --- | --- |
| Personal blog becoming a publication | The publication name readers will remember | A long descriptive keyword phrase |
| Product-led content site | Product or publication brand name | Different names in header and title tags |
| Rebrand in progress | New preferred name plus update notes | Mixing old and new names indefinitely |
| Local project or test site | Launch-ready name only when public | Leaving "Just another WordPress site" live |
| Multi-topic operator-tech blog | Broad publication name | A name that locks the site into one tool category |

For a YOLKMEET-style operator blog, the preferred site name should be stable enough to appear in the header, homepage, source notes, internal documentation, and search metadata. It should not change every time a new content pillar is added.

## Step 3: Clean Up The WordPress General Settings
The WordPress Settings General screen is the first place to check because it stores the basic site title and tagline fields. Update these fields deliberately:

- [ ] Replace placeholder site titles.
- [ ] Remove stale campaign wording from the tagline.
- [ ] Keep the tagline short enough to scan in a header or search context.
- [ ] Avoid stuffing the tagline with every target keyword.
- [ ] Confirm the site address and WordPress address are not being edited accidentally.
- [ ] Record the date of the identity change.
- [ ] Recheck the public homepage after saving.

For a content site, the tagline should explain the operating promise of the publication. It should not be a second title tag. If the active theme does not display the tagline, it can still help editors remember the site positioning, but it should not be treated as the only public explanation.

## Step 4: Check The Active Theme Surface
The same identity can appear differently depending on the theme. WordPress Site Editor documentation describes a block-theme surface for templates, patterns, styles, and blocks such as Site Title. The Customizer documentation describes classic-theme controls that may include logo, site title and tagline display, and site icon options.

Review the public surfaces that readers actually see:

- Header on desktop.
- Header on mobile.
- Footer.
- Homepage hero or intro section.
- Single post template.
- Category or archive template.
- Search results template.
- Browser tab or app icon.

Do not assume that changing the WordPress setting updates every visible place. A header may use a logo image, a Site Title block, a custom template part, or theme-specific settings. If a logo image includes the old name, the text field alone will not fix the public identity.

## Step 5: Align Homepage Wording With Search Signals
Google's title-link documentation says title links are generated automatically but can be influenced by high-quality title text. Its site-name documentation says site names are also generated automatically and can consider homepage content, structured data, title text, heading elements, and other homepage text.

For an operator, that creates a source-aware review path:

- [ ] The homepage has a clear title, not only "Home."
- [ ] The homepage H1 matches the publication direction.
- [ ] The header name, footer name, and title text do not conflict.
- [ ] The SEO plugin title template does not repeat the site name unnecessarily.
- [ ] The preferred site name is not a generic keyword phrase.
- [ ] The homepage explains what the publication covers.
- [ ] The structured data output, if present, uses the same preferred site name.

This does not guarantee how Google will display the site name or title link. It gives the automated systems cleaner, more consistent signals to evaluate. That is the right level of claim for a source-derived checklist.

## Step 6: Keep The Tagline Useful For Humans
A tagline should help a reader decide whether they are in the right place. It should not try to rank for every topic the site might cover.

Use this quick filter:

| Tagline pattern | Use this when | Rewrite when |
| --- | --- | --- |
| "Operator workflows for small publishers" | The site covers publishing operations | It no longer matches the content mix |
| "WordPress, automation, and reporting guides" | The site needs clear topical scope | It becomes a long keyword list |
| "Practical site operations for creators" | The audience is creator-operator focused | It sounds like a service promise |
| Empty tagline | The theme design does not need one | The homepage lacks any positioning |
| Old launch slogan | It is still accurate and visible | The site has moved beyond the launch angle |

The best fit is usually a concise explanation of audience and job. If the site title already carries the brand, the tagline can explain what the publication helps operators do.

## Step 7: Review Logo And Site Icon Separately
The logo and site icon are related but not the same job. The logo usually appears in the page layout. The site icon is a small identity marker in browser tabs, bookmarks, apps, and theme interfaces.

Review them separately:

- [ ] Does the logo match the preferred site name?
- [ ] Does the logo remain readable in the header size the theme actually uses?
- [ ] Does the site icon work at a very small size?
- [ ] Does the icon avoid tiny text that becomes unreadable?
- [ ] Does the icon still represent the publication after a rebrand?
- [ ] Are image files named clearly in the Media Library?
- [ ] Is the old logo still embedded in reusable patterns, headers, or template parts?

If the identity update includes a logo change, pair it with the media library cleanup checklist. If the active theme is changing at the same time, pair it with the theme update checklist and recheck templates before assuming the header is finished.

## Step 8: Add A Source-Aware Update Note
Identity changes should leave a note because future editors need to know whether a title, tagline, or logo mismatch is intentional. Keep the note short:

| Field | Example note |
| --- | --- |
| Change date | `2026-06-07` |
| Previous site name | Old public name or placeholder |
| Preferred site name | Current publication name |
| Reason | Rebrand, launch cleanup, theme change, or search consistency |
| Sources checked | WordPress settings, Site Editor, Google Search docs |
| Public surfaces reviewed | Homepage, header, footer, article template, mobile |
| Follow-up | Request recrawl, update logo, update structured data, or no action |

This is also where the operator should avoid private testing claims. If no live Search Console inspection, browser screenshots, or theme export was performed, do not imply it. Say what was checked from source documentation and what should be verified on the actual site.

## What Should The First Pass Include?
The first pass should include the site title, tagline, header identity, site icon, homepage title, and one search metadata review. Do not combine it with a full redesign. For a small WordPress blog, the useful first pass is:

- [ ] Choose one preferred site name.
- [ ] Update WordPress General settings.
- [ ] Check the active theme header and footer.
- [ ] Confirm the site icon.
- [ ] Review the homepage title and H1.
- [ ] Check SEO plugin title templates.
- [ ] Confirm the name is consistent in visible homepage copy.
- [ ] Record the source notes and update date.

This keeps the workflow small enough to finish and specific enough to support future search, theme, and content-refresh work.

## Common Questions

### Is the WordPress site title the same as the Google site name?
No. The WordPress site title is a site setting. Google Search site names are generated automatically and can consider several signals, including homepage content, structured data, title text, headings, and other homepage text. A consistent WordPress title helps, but it is not a manual override.

### Should the tagline contain target keywords?
Only if the wording still helps readers. A tagline that lists keywords can make the site look generic and may conflict with the preferred site name. Use the tagline to explain the publication's job, audience, or topic scope.

### Should a blog hide the site title when it has a logo?
It can, depending on the theme and design, but the operator should still keep the WordPress site title accurate. If the public header uses only a logo, verify that the homepage, footer, title text, and structured data still communicate the preferred name.

### When should this checklist run again?
Run it every 90 days, and run it sooner after a rebrand, theme update, homepage rewrite, SEO plugin change, structured data change, Search Console site-name issue, or public report that the site appears under the wrong name.

## Source Notes
- https://wordpress.org/documentation/article/settings-general-screen/ checked 2026-06-07; used for source-derived analysis of the WordPress General settings screen, site title, tagline, site URL fields, administration email, language, and why identity edits should not drift into unrelated site settings.
- https://wordpress.org/documentation/article/site-editor/ checked 2026-06-07; used for source-derived analysis of block-theme identity surfaces, Site Editor access to templates, patterns, styles, pages, and blocks such as Site Title that can affect how the public site presents its name.
- https://wordpress.org/documentation/article/customizer/ checked 2026-06-07; used for source-derived analysis of classic-theme identity controls, including logo, display of site title and tagline, and site icon behavior in themes that still use the Customizer.
- https://developers.google.com/search/docs/appearance/site-names checked 2026-06-07; used for source-derived analysis of Google site-name generation, preferred site-name signals, homepage consistency, structured data, concise naming, and troubleshooting limits.
- https://developers.google.com/search/docs/appearance/title-link checked 2026-06-07; used for source-derived analysis of title-link generation, descriptive title text, concise title guidance, and why homepage title wording should be checked alongside the site name.

## Internal Link Plan
Link to `wordpress-seo-plugin-setup` when the identity review reaches title templates, canonical settings, schema output, or sitemap behavior. Link to `wordpress-navigation-menu-checklist` when the header, footer, homepage label, or menu structure changes. Link to `wordpress-internal-link-audit-checklist` when a rebrand changes homepage, about page, or footer link anchors. Link to `wordpress-sitemap-noindex-checklist` if the homepage or identity review uncovers indexing or noindex confusion. Link to `wordpress-theme-update-checklist` before a theme switch changes logo, title, tagline, or Site Editor behavior. Link to `content-refresh-workflow` when identity changes require updating source notes across existing articles.

## Update Note
Review this checklist every 90 days. Recheck official WordPress General settings, Site Editor, Customizer, Google Search site-name, and title-link documentation. Refresh earlier after a rebrand, active theme change, SEO plugin change, homepage rewrite, structured data update, Search Console issue, logo update, or public report that the site appears under an outdated name.
