# a11y-audit

An accessibility audit skill for Claude Code (and any agent runtime that reads `SKILL.md` skills). Point it at a live site and it produces a prioritized WCAG 2.2 Level AA findings report: automated scanners for the deterministic checks, model judgment for everything scanners can't decide, and honest labeling for everything neither could check.

**Honesty is the product.** Automated rules cover roughly 20-40% of WCAG success criteria. This skill never claims compliance from a clean scan, never marks an unchecked criterion as a pass, and never invents a contrast ratio it didn't compute. Criteria that weren't exercised are reported as **Undetermined**, not passed.

## What it does

1. **Samples by template, not URL count.** Fetches the sitemap, classifies URLs into template groups (home, product, category, article, form, cart), audits one representative of each. Homepage-only "audits" are the most common real-world failure; the homepage is usually the most accessible page on the site.
2. **Scans with two engines at once.** `scripts/scan.sh` runs pa11y with both axe-core and HTML_CodeSniffer in a single Puppeteer instance, plus optional Lighthouse for the familiar 0-100 score.
3. **Compresses before the model reads anything.** `scripts/merge_findings.py` normalizes both engines' output to WCAG success criteria, dedups cross-engine, caps evidence samples, and splits hard violations from a judgment queue. A 6-page scan produces ~9MB of raw JSON; the model reads ~36KB. Raw scanner JSON never enters context.
4. **Adds the model pass scanners can't do.** Alt text *quality* (not just presence), useless link names, contrast indeterminates over images, readability (Flesch-Kincaid, advisory), semantic HTML, and triage of the high-false-positive HTML_CodeSniffer warning queue.
5. **Grades evidence separately from severity.** Every finding is P0/P1/P2 for impact and Verified/Flagged/Human-required for evidence basis, and takes the lower grade. A screenshot judgment call never masquerades as a machine-verified fact.
6. **Attributes Shopify findings to their owner.** Theme-owned issues vs app-injected DOM (Rebuy, Okendo, Klaviyo, review widgets) get separate report sections, because the store owner can't fix an app's markup in theme code.
7. **Files tracker tasks on request.** Reference flow is ClickUp via MCP (one task per grouped finding, priority-mapped, report attached as a doc); adaptable to any tracker.

Every finding follows one shape:

```
### [P1 · Verified] Link text fails contrast: SC 1.4.3
Observed: 14 instances across 3 pages; e.g. `.footer a` #767676 on #ffffff = 4.1:1 (needs 4.5:1).
Fix: darken to #595959 (7.0:1) or bump size to 24px/bold to qualify as large text.
Citation: WCAG 2.2 SC 1.4.3 (Contrast Minimum, Level AA). Engines: axe+lighthouse.
```

## Install

As a Claude Code plugin:

```
/plugin marketplace add kgelster/a11y-audit-skill
/plugin install a11y-audit@kgelster-a11y
```

Or manually: clone this repo and copy `skills/a11y-audit/` into `~/.claude/skills/`.

Then ask for an audit ("run an accessibility audit on example.com") or invoke `/a11y-audit <url>` directly.

## Requirements

- **Node.js with npx**: the scan script runs `npx --yes pa11y` and `npx --yes lighthouse` (first run downloads packages, ~1 min). No global installs required; `npm i -g pa11y lighthouse` skips the download wait.
- **Chrome/Chromium**: pa11y's Puppeteer downloads its own; Lighthouse uses your installed Chrome headless.
- **Python 3**: for `merge_findings.py` (stdlib only, no pip installs).

## What's inside

```
skills/a11y-audit/
├── SKILL.md                     the pipeline: scope → sample → scan → judge → report → tasks
├── scripts/scan.sh              pa11y (axe + htmlcs, WCAG2AA) + optional Lighthouse per URL
├── scripts/merge_findings.py    normalize, dedup, compress; also a readability subcommand
└── references/manual-checks.md  the manual/model check catalog (what no engine covers)
```

Design notes, for the curious:

- axe is run through pa11y rather than `@axe-core/cli` because the CLI's Selenium/ChromeDriver pairing breaks whenever Chrome updates ahead of ChromeDriver.
- axe is never run with only the `wcag22aa` tag: that tag selects only rules *new* to WCAG 2.2, which silently drops most of the ruleset.
- HTML_CodeSniffer warnings/notices are kept, not discarded: they're a pre-filtered queue of exactly the items worth human/model judgment (text-over-image contrast, unlabeled landmark candidates), at the cost of a high false-positive rate the model triages.
- The skill is an auditor, not a fixer. It recommends fixes with concrete replacement values (computed hex colors, aria-label patterns) but does not edit code or write content without a separate ask.

## License

MIT © Kurt Elster
