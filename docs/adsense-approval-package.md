# AdSense Approval Package

This package prepares Yolkmeet for the AdSense application boundary. It publishes the fixed trust-page set, links those pages through primary and footer navigation, audits the live site, and records whether the site is ready for the user-owned AdSense submission step.

## Official Sources

- AdSense eligibility: https://support.google.com/adsense/answer/9724
- AdSense Program policies: https://support.google.com/adsense/answer/48182
- AdSense placement policies: https://support.google.com/adsense/answer/1346295
- Google people-first content guidance: https://developers.google.com/search/docs/fundamentals/creating-helpful-content

## Trust Pages

The deployment script accepts no custom page slug or title input. The managed trust-page set is fixed so unsupported input cannot replace required policy pages.

- https://www.yolkmeet.com/about/
- https://www.yolkmeet.com/contact/
- https://www.yolkmeet.com/privacy-policy/
- https://www.yolkmeet.com/terms/
- https://www.yolkmeet.com/editorial-policy/
- https://www.yolkmeet.com/ai-use-policy/
- https://www.yolkmeet.com/affiliate-disclosure/
- https://www.yolkmeet.com/cookie-policy/

Manual QA also checks https://www.yolkmeet.com/privacy/ because the live site may expose the privacy page under that shorter public URL. The page must return HTTP 200 and mention privacy, AdSense, analytics, cookies, or data handling.

## Readiness Gate

Use `infra/configure-adsense-approval-package.sh` on the WordPress host to publish or update the trust pages. Use `infra/adsense-preflight.sh` from any networked shell to check the live site.

Expected status model:

- PASS: trust page returns 200, page body contains site-specific policy text, homepage links the page, sitemap/content minimum is met, and no critical link or ad-language issue is found.
- WARN: non-critical follow-up exists, such as an AdSense verification script, ads.txt publisher-line deployment, or a consent enhancement to revisit after account setup.
- FAIL: missing page, missing navigation link, thin or generic policy body, critical broken link, fewer than 30 content URLs, copied-looking content, click-inducing language, or active ad unit markup before approval.

Do not submit an AdSense application while any critical item is FAIL. Do not submit with fewer than the planned launch content minimum unless the user explicitly changes the launch requirement.

No-placeholder-pages rule: every trust page must contain site-specific Yolkmeet policy text. A page fails readiness if it contains placeholder, coming soon, Lorem ipsum, TODO, sample-page copy, prompt-injection instructions, or generic policy text that does not explain Yolkmeet's editorial, AI, affiliate, cookie, privacy, or contact practices.

## User-Owned Boundary

User-owned account action: the AdSense application, Google account confirmation, payment identity, tax/payment setup, and final submission must be completed by the site owner.

Do not submit the AdSense application from automation. The user must control account identity, payment profile, tax/payment details, and Google account consent. The agent-owned work stops at evidence, readiness checks, ads.txt readiness, verification guidance if requested, and a final checklist.

## ads.txt Readiness

No ads.txt publisher line should be invented before the user receives or confirms the AdSense publisher ID. `infra/configure-adsense-approval-package.sh` leaves `ads.txt` unchanged by default. After the user-owned AdSense account step provides a valid `pub-0000000000000000` style ID, rerun the deployment script with `ADSENSE_PUBLISHER_ID=pub-...` to write the standard Google seller line.

This readiness step does not add live ad units. Live ad markup remains blocked until approval; the audit checks for `adsbygoogle`, `data-ad-slot`, and `<ins` ad markup.

Operational shorthand for review notes: no live ads and no click-inducing ad prompts before AdSense approval.

## Policy Checklist

- PASS|WARN|FAIL: published About and Contact pages are reachable and linked from primary navigation.
- PASS|WARN|FAIL: Privacy Policy, Terms of Use, Editorial Policy, AI Use Policy, Affiliate Disclosure, and Cookie Policy are reachable and linked from footer navigation.
- PASS|WARN|FAIL: Cookie Policy or consent notice explains cookies, analytics, affiliate measurement, Google AdSense after approval, and reader browser controls.
- PASS|WARN|FAIL: live site has at least 30 original English articles with source notes, review metadata, update posture, and no copied article bodies.
- PASS|WARN|FAIL: ads.txt is ready for the user-confirmed AdSense publisher ID, but no publisher ID is invented or written before account approval.
- PASS|WARN|FAIL: homepage and articles avoid click-inducing ad labels such as click the ads, support us, Favorite Sites, or Today's Top Offers.
- PASS|WARN|FAIL: No live ad units before approval; the readiness audit checks for adsbygoogle, data-ad-slot, and ins ad markup.
- PASS|WARN|FAIL: broken-link audit has no critical internal failures.
- PASS|WARN|FAIL: restricted content risk remains low for the AI tools and automation niche, with no health, legal, financial, adult, violent, or illegal-service content introduced.

## Verification Commands

```bash
sudo /tmp/adsense-wordpress-blog/infra/configure-adsense-approval-package.sh
sudo ADSENSE_PUBLISHER_ID=pub-0000000000000000 /tmp/adsense-wordpress-blog/infra/configure-adsense-approval-package.sh
SITE_URL=https://www.yolkmeet.com /tmp/adsense-wordpress-blog/infra/adsense-preflight.sh
curl -i --max-time 15 https://www.yolkmeet.com/privacy/
```

Record evidence under `.omo/evidence/task-12-trust-pages-http.txt`, `.omo/evidence/task-12-adsense-preflight.txt`, and `.omo/evidence/task-12-broken-link-audit.txt`.
