# Content Pillar Map

Generated: 2026-06-06

## Decision

Keep the existing 30 markdown articles in `content/launch-batch/` as the AdSense launch batch. Treat the manifest as a mixed state: matched launch rows stay in scope, manifest-only rows become the next content queue, and slug-drift rows require redirect-aware cleanup before publication changes.

This preserves the current publish-ready corpus, avoids unnecessary URL churn, and keeps expansion tied to the quality gates in `docs/editorial-system.md` and the Wave 1 content-depth work.

## Monetization Fit

The launch batch should support an operator-tech publication rather than an AI-only blog. AI remains the largest pillar, but adjacent operations topics are required for durable AdSense coverage, repeat visits, and lower template repetition.

## 90-Day Pillar Split

- `35% AI tools`
- `25% automation/no-code`
- `15% WordPress/site ops`
- `10% analytics/reporting`
- `10% creator/business tooling`
- `5% light security/privacy`

These targets apply to the combined launch batch, queued backlog, and next refresh cycle. New YMYL categories such as medical, legal, or financial advice stay out of scope.

## Inventory Reconciliation

Current state:

- `30` markdown files in `content/launch-batch/`
- `36` rows in `content/launch-batch/articles.tsv`
- Net mismatch: `6` more manifest rows than live markdown files

### Launch-Only Markdown

These files exist as drafts and should remain in the launch batch unless later removed as documented duplicates:

- `ai-prompt-template-for-blog-post`
- `best-ai-tools-b2b-marketing-2026`
- `chatgpt-not-working`
- `chatgpt-pricing`
- `claude-api-error`
- `cursor-not-indexing-repo`

### Manifest-Only Queue

These rows stay in `articles.tsv` as the `manifest-only queue`. They should only become markdown articles after the new depth, originality, and voice gates pass:

- `ai-prompt-template-for-product-comparisons`
- `best-ai-code-editors`
- `how-to-benchmark-ai-tools`
- `how-to-use-ai-for-competitor-research`
- `how-to-use-ai-for-customer-support`
- `how-to-use-ai-for-internal-knowledge-base`
- `how-to-use-ai-for-reporting`
- `how-to-use-ai-for-seo-tasks`
- `how-to-use-ai-for-spreadsheet-analysis`
- `workflow-for-ai-approval-gates`
- `workflow-for-original-content-verification`

### Slug Drift Pairs

These are not new topic gaps. They are naming mismatches that need one canonical slug plus redirect notes before any live URL change:

- Markdown `best-ai-tools-b2b-marketing-2026` vs manifest `best-ai-tools-for-b2b-marketing-2026`
- Markdown `how-to-build-ai-content-workflow` vs manifest `how-to-build-an-ai-content-workflow`

Default rule: keep the existing markdown slug as the launch artifact unless there is a deliberate redirect plan and the WordPress import map is updated.

## Publication Priority

1. Keep all matched and launch-only markdown drafts available for Wave 2 rewrites.
2. Expand the manifest-only queue in pillar order, starting with automation/no-code and WordPress/site ops gaps before adding more AI lookalike listicles.
3. Use analytics/reporting, creator/business tooling, and light security/privacy to reduce topical repetition and build more durable return traffic.

## Queue Rules

- Do not remove existing content unless it is a confirmed duplicate and the removal is documented.
- Do not rename published URLs without redirect notes.
- Do not add new queue items from YMYL categories.
- Do not promote manifest-only rows into the launch batch until they pass the content quality gates and fit the pillar targets above.

## 90-Day Queued Briefs

### Brief: Zapier vs Make vs n8n for Small-Team Automation

- Pillar: automation/no-code
- Target keyword: `Zapier vs Make vs n8n`
- Intent: compare automation builders for teams choosing one workflow layer.
- Official source URLs:
  - https://zapier.com/app/home
  - https://www.make.com/en
  - https://n8n.io/
- Internal links: `zapier-alternatives`, `make-alternatives`, `n8n-alternatives`
- Update cadence: Review every 30 days; recheck pricing, AI features, and self-hosting claims.
- AdSense fit: high informational/comparison intent without requiring purchase claims.
- AEO/GEO answer target: one extractable matrix explaining which tool fits simple SaaS triggers, visual workflows, and developer-hosted automation.

### Brief: WordPress SEO Plugin Setup for Lightweight Editorial Sites

- Pillar: WordPress/site ops
- Target keyword: `WordPress SEO plugin setup`
- Intent: help small publishers configure one lightweight SEO plugin without duplicate metadata.
- Official source URLs:
  - https://wordpress.org/plugins/autodescription/
  - https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- Internal links: `workflow-for-original-content-verification`, `how-to-use-ai-for-seo-tasks`
- Update cadence: Review every 60 days; recheck plugin settings, sitemap behavior, and schema output.
- AdSense fit: evergreen site-ops content that supports crawler trust and page experience.
- AEO/GEO answer target: a concise checklist for title, canonical, sitemap, robots, and schema verification.

### Brief: Google Search Console Setup Checklist for New Blogs

- Pillar: analytics/reporting
- Target keyword: `Google Search Console setup checklist`
- Intent: guide publishers through property verification, sitemap submission, and indexing checks.
- Official source URLs:
  - https://support.google.com/webmasters/answer/9128668
  - https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap
- Internal links: `workflow-for-original-content-verification`, `how-to-use-ai-for-reporting`
- Update cadence: Review every 90 days; recheck Search Console UI changes and sitemap guidance.
- AdSense fit: supports organic traffic quality, which is the only active monetization path.
- AEO/GEO answer target: a step list that answer engines can cite for verification, sitemap, and index coverage.

### Brief: Core Web Vitals Basics for AdSense Blogs

- Pillar: WordPress/site ops
- Target keyword: `Core Web Vitals for blogs`
- Intent: explain which page experience checks matter before adding ads.
- Official source URLs:
  - https://web.dev/vitals/
  - https://developers.google.com/search/docs/appearance/page-experience
- Internal links: `best-ai-productivity-tools-2026`, `workflow-for-original-content-verification`
- Update cadence: Review every 90 days; recheck web.dev thresholds and Search guidance.
- AdSense fit: ad layout and performance directly affect durable search and ad experience.
- AEO/GEO answer target: a short table mapping LCP, INP, and CLS to publisher actions.

### Brief: Uptime Monitoring Stack for Solo WordPress Publishers

- Pillar: WordPress/site ops
- Target keyword: `uptime monitoring for WordPress`
- Intent: help site owners choose simple monitoring and incident logging.
- Official source URLs:
  - https://developers.cloudflare.com/health-checks/
  - https://uptimerobot.com/
- Internal links: `how-to-use-ai-for-reporting`, `workflow-for-ai-approval-gates`
- Update cadence: Review every 90 days; recheck free-plan limits and alerting options.
- AdSense fit: protects crawlability and avoids revenue loss from silent downtime.
- AEO/GEO answer target: answer block naming the minimum stack: uptime check, alert channel, incident log, and weekly review.

### Brief: Privacy-Friendly Analytics Options for Content Sites

- Pillar: analytics/reporting
- Target keyword: `privacy friendly analytics for blogs`
- Intent: compare analytics options without overstating compliance.
- Official source URLs:
  - https://support.google.com/analytics/answer/10089681
  - https://plausible.io/docs
- Internal links: `how-to-use-ai-for-reporting`, `workflow-for-original-content-verification`
- Update cadence: Review every 90 days; recheck product documentation and privacy settings.
- AdSense fit: analytics helps decide refresh/prune actions while privacy clarity supports trust.
- AEO/GEO answer target: a decision table for GA4, privacy-focused analytics, and server logs.

### Brief: Content Refresh Workflow for Fast-Changing SaaS Pages

- Pillar: creator/business tooling
- Target keyword: `content refresh workflow`
- Intent: define a repeatable refresh workflow for pricing, alternatives, and troubleshooting pages.
- Official source URLs:
  - https://developers.google.com/search/docs/fundamentals/creating-helpful-content
  - https://developers.google.com/search/docs/fundamentals/using-gen-ai-content
- Internal links: `chatgpt-pricing`, `n8n-alternatives`, `workflow-for-original-content-verification`
- Update cadence: Review every 30 days; this article becomes a meta-process page.
- AdSense fit: keeps organic traffic durable without adding risky monetization paths.
- AEO/GEO answer target: a reusable source-check, diff, update-log, and republish checklist.

### Brief: No-Code Database Options for Editorial Operations

- Pillar: automation/no-code
- Target keyword: `no-code database for content calendar`
- Intent: help publishers choose a simple editorial database for briefs, sources, and refresh dates.
- Official source URLs:
  - https://support.airtable.com/docs
  - https://www.notion.com/help/guides/category/databases
- Internal links: `ai-prompt-template-for-content-briefs`, `how-to-build-ai-content-workflow`
- Update cadence: Review every 60 days; recheck database feature changes and export paths.
- AdSense fit: improves editorial consistency rather than adding separate monetization.
- AEO/GEO answer target: a table comparing source logs, status fields, refresh dates, and export options.

### Brief: Browser Automation Safety Checklist for Research Workflows

- Pillar: automation/no-code
- Target keyword: `browser automation safety checklist`
- Intent: explain safe boundaries for using browser automation in research and publishing.
- Official source URLs:
  - https://playwright.dev/docs/intro
  - https://developers.google.com/search/docs/essentials/spam-policies
- Internal links: `best-ai-browser-agents`, `workflow-for-original-content-verification`
- Update cadence: Review every 60 days; recheck automation tooling and search spam guidance.
- AdSense fit: reduces risk from automated scraping or low-value scaled pages.
- AEO/GEO answer target: a checklist for rate limits, source logging, copied-text avoidance, and human approval.

### Brief: Basic Security Checklist for WordPress Content Sites

- Pillar: light security/privacy
- Target keyword: `WordPress security checklist for blogs`
- Intent: cover basic operational hardening without offering professional security advice.
- Official source URLs:
  - https://wordpress.org/documentation/article/hardening-wordpress/
  - https://developers.cloudflare.com/waf/
- Internal links: `workflow-for-ai-approval-gates`, `how-to-use-ai-for-internal-knowledge-base`
- Update cadence: Review every 90 days; recheck WordPress and hosting guidance.
- AdSense fit: stable, crawlable, trustworthy sites support AdSense readiness and ongoing ad serving.
- AEO/GEO answer target: a non-YMYL checklist covering updates, backups, access, WAF, and monitoring.

### Brief: Spreadsheet Reporting Workflow for Blog Operators

- Pillar: analytics/reporting
- Target keyword: `blog reporting spreadsheet`
- Intent: show how to track pages, queries, refresh decisions, and AdSense readiness fields.
- Official source URLs:
  - https://support.google.com/docs/topic/9054603
  - https://support.google.com/webmasters/answer/7576553
- Internal links: `how-to-use-ai-for-spreadsheet-analysis`, `how-to-use-ai-for-reporting`
- Update cadence: Review every 60 days; recheck Search Console export behavior.
- AdSense fit: helps decide when to refresh, expand, prune, or pause ad rollout.
- AEO/GEO answer target: field list for page URL, target query, clicks, impressions, CTR, refresh status, and invalid-traffic notes.

### Brief: Creator Tool Stack for Source-Aware Publishing

- Pillar: creator/business tooling
- Target keyword: `creator tool stack for publishing`
- Intent: describe a practical stack for capture, source notes, drafting, review, and publishing.
- Official source URLs:
  - https://www.notion.com/help
  - https://zapier.com/help
- Internal links: `ai-prompt-template-for-blog-post`, `how-to-build-ai-content-workflow`
- Update cadence: Review every 60 days; recheck tool docs and integration behavior.
- AdSense fit: supports consistent publishing quality without introducing non-AdSense monetization.
- AEO/GEO answer target: a layer-by-layer stack summary for capture, database, automation, writing, and review.
