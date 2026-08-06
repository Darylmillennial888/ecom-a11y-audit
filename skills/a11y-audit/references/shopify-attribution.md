# Shopify owner attribution: theme vs app

Every finding on a Shopify storefront has an owner, and the owner determines the fix route. Theme-owned issues are fixed in Liquid/CSS by whoever maintains the theme. App-injected issues cannot be fixed in theme code: the DOM belongs to the app, and the route is the app's own settings/custom-CSS field, or a support ticket to the vendor. Reports that ignore this send merchants to edit markup they don't control.

`merge_findings.py` pre-tags nodes with `owner` / `owner_hints` using the fingerprints below. Treat hints as strong but not final: confirm in the judge pass (an app widget rendered inside a theme section can carry both markers; app match wins because apps render inside sections). Instances with no hint need model attribution: look at the selector's ancestors, class prefixes, and which script owns the DOM subtree.

## Fingerprints (selector/markup markers)

- `rebuy` : Rebuy (cart drawer, upsells, bundles). Frequent offenders: `aria-hidden` drawer containing focusables, unlabeled bundle checkboxes, widget CTA contrast, carousel clone slides.
- `okendo`, `oke-` : Okendo reviews. Star-filter rows as sub-24px `role="button"` divs, media-grid contrast over thumbnails.
- `klaviyo`, `kl-private` : Klaviyo forms/popups. Unlabeled email inputs, low-contrast placeholder-as-label, per-device visibility quirks.
- `jdgm` : Judge.me reviews. `loox` : Loox. `yotpo` : Yotpo. `stamped-` : Stamped. Review widgets share a failure family: star ratings conveyed by color/icon only, unlabeled filter controls, tiny tap targets.
- `privy`, `attentive`, `postscript` : popup/SMS capture. Focus not trapped in modal, no Escape close, close button unnamed.
- `recharge` : subscriptions. Radio/checkbox widgets with detached labels.
- `gorgias`, `tidio` : chat. Untitled iframes (`frame-tested` groups usually land here).
- `swym` : Swym wishlist. `smile-ui` : Smile.io loyalty launcher (fixed-position button, contrast + target size).
- `nosto`, `algolia`/`ais-`, `boost-pfs`/`boost-sd`, `snize` (Searchanise), `convermax` : search/merchandising. Facet checkboxes without labels, results announced without live regions.
- `shogun`, `pagefly`/`pf-`, `gempages`/`gp-` : page builders. Whole templates of divs-as-buttons and skipped headings; owner is the page built in the app, fix route is the builder's editor, not the theme.
- `afterpay`, `klarna`, `sezzle`, `paypal`/`zoid` : payment messaging/buttons. Untitled utility iframes; hidden, usually low priority, not actionable by the merchant.
- `arttrk` : ArtTrk ad pixel. 1x1 `<img>` without alt on every page; ask vendor for `alt=""` + `aria-hidden`, or accept as scan noise.
- `shopify-section-*` and no app marker : theme-owned.

Apps not listed here: fingerprint from the page yourself (script `src` domains, class prefixes on the failing subtree) before attributing.

## Fix routes by owner

- **theme** : Liquid/CSS edit in the theme repo or theme editor. Follow the patterns in Shopify's `liquid-theme-a11y` skill (AI toolkit plugin) if installed. Name the file when you can infer it (`layout/theme.liquid` for viewport meta, the section/snippet rendering the failing selector otherwise).
- **app with a settings/CSS surface** (Rebuy, Okendo, Klaviyo, review apps): route to the widget's own settings or custom-CSS field first; escalate to vendor support with the selector + WCAG SC when settings can't reach the markup (e.g. Rebuy's aria-hidden carousel clones are their markup, not configurable).
- **app with no surface** (pixels, payment iframes, chat launchers): vendor ticket or accept-and-document. Never tell the merchant to patch app DOM from theme JS; it breaks on every app update.
- **checkout** : Shopify-hosted and locked on non-Plus plans; report as out of scope/Undetermined, not as passed. Plus stores using checkout extensibility own their customizations only.

## Report shape

App-injected findings get their own report section grouped by app, each with: the finding, instance count, and the route (settings vs support ticket). This is the section a merchant forwards verbatim to each vendor.
