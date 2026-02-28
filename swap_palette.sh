#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
SCOPE="gtk"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --all) SCOPE="all"; shift ;;
    --gtk) SCOPE="gtk"; shift ;;
    -h|--help)
      echo "Usage: $0 [--gtk|--all] [--dry-run]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

GTK_DIRS=(gtk-2.0 gtk-3.0 gtk-3.20 gtk-4.0)
EXTRA_DIRS=(assets cinnamon metacity-1 openbox-3 unity xfwm4)

if [[ "$SCOPE" == "all" ]]; then
  DIRS=("${GTK_DIRS[@]}" "${EXTRA_DIRS[@]}")
else
  DIRS=("${GTK_DIRS[@]}")
fi

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need_cmd rg
need_cmd perl
need_cmd xargs

PATTERNS=( "#141216" "#27232b" "#d8cab8" "#ac82e9" "#8f56e1" "#c4e881" "#fcb167" "#fc4649" "#f3fc7b" "#7b91fc" "#92fcfa" "#fc92fc" )

# Old -> New mapping, preserves optional alpha (#RRGGBBAA)
PERL_EXPR='
  s/#141216([0-9a-fA-F]{2})?/#001427$1/ig;
  s/#27232b([0-9a-fA-F]{2})?/#004068$1/ig;
  s/#d8cab8([0-9a-fA-F]{2})?/#F8F0E1$1/ig;
  s/#ac82e9([0-9a-fA-F]{2})?/#52B3BC$1/ig;
  s/#8f56e1([0-9a-fA-F]{2})?/#3D97A0$1/ig;
  s/#c4e881([0-9a-fA-F]{2})?/#52BC90$1/ig;
  s/#fcb167([0-9a-fA-F]{2})?/#EF5F31$1/ig;
  s/#fc4649([0-9a-fA-F]{2})?/#D7120D$1/ig;
  s/#f3fc7b([0-9a-fA-F]{2})?/#EED4AC$1/ig;
  s/#7b91fc([0-9a-fA-F]{2})?/#2E7FB0$1/ig;
  s/#92fcfa([0-9a-fA-F]{2})?/#89D5DA$1/ig;
  s/#fc92fc([0-9a-fA-F]{2})?/#BC5290$1/ig;
'

echo "Scope: $SCOPE"
echo "Dirs:  ${DIRS[*]}"

report_hits() {
  local pat="$1"
  local total
  total=$((rg -i --fixed-strings -o "$pat" "${DIRS[@]}" 2>/dev/null || true) | wc -l | tr -d ' ')
  echo "  $pat -> $total hits"
}

echo "Pre-scan (case-insensitive):"
for p in "${PATTERNS[@]}"; do
  report_hits "$p"
done

# One pass to list all files containing ANY old color (NUL-separated for safety)
RG_ARGS=( -i -l --null --fixed-strings )
for p in "${PATTERNS[@]}"; do
  RG_ARGS+=( -e "$p" )
done

# Optional: exclude the wallpaper or other big binaries by glob if you want (rg skips binaries anyway)
RG_ARGS+=( --glob '!wallhaven-*.jpg' --glob '!.git/*' )

FILES_NUL="$(rg "${RG_ARGS[@]}" "${DIRS[@]}" 2>/dev/null || true)"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo
  echo "Dry run: unique files containing ANY old palette color:"
  if [[ -n "$FILES_NUL" ]]; then
    printf "%s" "$FILES_NUL" | tr '\0' '\n'
  else
    echo "  (none)"
  fi
  exit 0
fi

if [[ -z "$FILES_NUL" ]]; then
  echo
  echo "No files matched the old palette. Nothing to do."
  exit 0
fi

echo
echo "Applying replacements to matching files..."
printf "%s" "$FILES_NUL" | xargs -0 perl -pi -e "$PERL_EXPR"

echo "Done."

echo
echo "Post-scan (old palette codes should be 0):"
for p in "${PATTERNS[@]}"; do
  report_hits "$p"
done

echo
echo "Review: git diff"