# Ad Monetization Playbook

Generated: 2026-06-06

## Decision

Yolkmeet uses an AdSense-only monetization model. Auto ads are the default and only active ad delivery path in this plan. Affiliate rollout, sponsored content rollout, template product funnels, lead magnet monetization, paid placements, and manual ad-unit optimization are out of scope.

The existing AdSense verification and Auto ads script uses client `ca-pub-1424742974208042` and is emitted through `wp_head`, so it appears inside the document `<head>` on WordPress-rendered pages. The repository must keep that head script available for AdSense review and Auto ads operation while enforcing no live ad units before approval.

## Ownership Boundary

The site owner controls the Google account, AdSense application, identity verification, payment profile, tax details, final submission, dashboard settings, and any account-side consent or Auto ads controls.

Repository work owns:

- readiness checks
- policy-safe theme behavior
- no-live-unit enforcement before approval
- trust page and cookie/privacy copy alignment
- post-approval placement QA guidance
- invalid traffic monitoring workflow
- rollback notes for site-side ad changes

## Pre-Approval Rules

- Keep the AdSense script in the site head.
- Do not add `<ins class="adsbygoogle">`, `adsbygoogle.push`, `data-ad-slot`, or manual ad unit markup before approval.
- Do not show empty `Advertisement` placeholder boxes unless `_yolkmeet_show_ad_placeholders` or `YOLKMEET_SHOW_AD_PLACEHOLDERS` is explicitly enabled for QA.
- Do not use click prompts such as `click the ads`, `support us`, `visit these links`, `Favorite Sites`, or `Today's Top Offers`.
- Keep the quick answer and first useful paragraph visible before any ad-like layout element.

## Auto Ads Only

Auto ads only means Google chooses eligible placements after approval, while Yolkmeet controls the surrounding reading experience. The theme should reserve clean article rhythm, but it should not hard-code live units. After approval, use the AdSense dashboard to review formats and exclusions before adding any theme-side behavior.

Post-approval placement QA must check:

- no ad before the quick answer
- no ad inside a comparison table, code block, source note, or FAQ answer
- no ad adjacent to a product CTA or affiliate-style wording
- no layout overlap on mobile
- no confusing label near navigation, related posts, or source notes
- no CLS-heavy placement that harms Core Web Vitals

## Invalid Traffic

Invalid traffic is a standing AdSense risk. The site must enforce no self-clicking, no click encouragement, no repeated refresh incentives, no paid-to-click visits, no exchange traffic, no bot traffic, and no misleading ad interactions.

Weekly review should flag:

- sudden CTR spikes
- unusual referrer bursts
- repeated visits from a narrow network range
- traffic sources that do not match editorial distribution
- suspicious mobile/desktop imbalance
- ad clicks without corresponding engaged reading behavior

If invalid traffic signals appear, pause traffic pushes, document the anomaly, avoid changing ad density as a reaction, and review logs before interpreting revenue or search data.

## EU User Consent And CMP

If Yolkmeet serves ads to users in the EEA, UK, or Switzerland, the site owner must ensure EU user consent policy handling is in place. Treat consent/CMP configuration as account-gated until the owner confirms the AdSense account-side setup and the live cookie/consent behavior.

Repository checks should keep the Privacy Policy and Cookie Policy aligned with:

- AdSense after approval
- analytics if enabled
- cookies and similar technologies
- reader browser controls
- consent/CMP follow-ups where required

## Approval And Activation Sequence

1. Run content, SEO, AdSense readiness, and trust-page checks.
2. Confirm the head script is present and no manual live ad unit exists.
3. User completes account-owned AdSense application steps.
4. After approval, user confirms Auto ads settings in AdSense.
5. Run post-approval placement QA on desktop and mobile.
6. Record invalid traffic baseline before interpreting revenue.
7. Review Auto ads placement weekly alongside Search Console and Core Web Vitals.

## Rollback

If ads harm UX or policy confidence:

- disable Auto ads or selected formats in the AdSense dashboard
- keep the site-side head script unless AdSense review instructions change
- leave manual ad units disabled
- keep `_yolkmeet_show_ad_placeholders` false
- rerun `SITE_URL=https://www.yolkmeet.com bash infra/adsense-preflight.sh`

## Verification

Run:

```bash
bash tests/theme-baseline.test.sh
rg -n "Auto ads|ca-pub-1424742974208042|no live ad units before approval|post-approval placement QA" docs/ad-monetization-playbook.md
rg -n "<ins class=\"adsbygoogle\"|adsbygoogle\\.push|data-ad-slot" wordpress/themes/yolkmeet-editorial
rg -n "invalid traffic|no self-clicking|no click encouragement|EU user consent|CMP|Auto ads only" docs/ad-monetization-playbook.md
```
