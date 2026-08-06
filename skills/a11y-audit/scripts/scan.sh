#!/usr/bin/env bash
# a11y-audit scanner: runs pa11y (axe + htmlcs engines) and optionally Lighthouse
# against each URL, writing raw JSON into an output directory.
#
# Usage:
#   scan.sh OUTDIR URL [URL...]
#   LIGHTHOUSE=1 scan.sh OUTDIR URL [URL...]   # also capture Lighthouse a11y category
#
# Output files per URL (N = 1-based index, slug = sanitized URL):
#   OUTDIR/pa11y-N-<slug>.json      pa11y issues (axe + htmlcs, WCAG2AA)
#   OUTDIR/lh-N-<slug>.json         Lighthouse accessibility category (if LIGHTHOUSE=1)
#   OUTDIR/urls.tsv                 index of N <TAB> URL
#
# Notes:
# - pa11y exits 2 when issues are found; that is success for our purposes.
# - Uses npx --yes with pinned majors (pa11y@9, lighthouse@13) so a scanner major
#   bump can't silently change results; first run downloads packages (~1 min).
set -uo pipefail

OUTDIR="$1"; shift
mkdir -p "$OUTDIR"
: > "$OUTDIR/urls.tsv"

i=0
for url in "$@"; do
  # only http(s) URLs: anything else (including dash-prefixed strings, e.g. from a
  # hostile sitemap) would be parsed as a CLI flag by pa11y/lighthouse
  case "$url" in
    http://*|https://*) ;;
    *) echo "SKIP non-http(s) argument: $url" >&2; continue ;;
  esac
  i=$((i+1))
  slug=$(echo "$url" | sed -E 's~https?://~~; s~[^A-Za-z0-9]+~-~g; s~-+$~~' | cut -c1-60)
  printf '%s\t%s\n' "$i" "$url" >> "$OUTDIR/urls.tsv"

  echo "[$i] pa11y (axe+htmlcs): $url" >&2
  npx --yes pa11y@9 "$url" \
    --runner axe --runner htmlcs \
    --standard WCAG2AA \
    --include-warnings --include-notices \
    --timeout 60000 \
    --reporter json > "$OUTDIR/pa11y-$i-$slug.json" 2>> "$OUTDIR/scan-errors.log"
  rc=$?
  if [ $rc -ne 0 ] && [ $rc -ne 2 ]; then
    echo "  WARN pa11y exit $rc for $url (see scan-errors.log)" >&2
  fi

  if [ "${LIGHTHOUSE:-0}" = "1" ]; then
    echo "[$i] lighthouse: $url" >&2
    npx --yes lighthouse@13 "$url" \
      --only-categories=accessibility \
      --output=json --output-path="$OUTDIR/lh-$i-$slug.json" \
      --chrome-flags="--headless=new" --quiet 2>> "$OUTDIR/scan-errors.log" \
      || echo "  WARN lighthouse failed for $url" >&2
  fi
done

echo "Scan complete: $OUTDIR" >&2
