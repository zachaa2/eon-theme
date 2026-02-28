#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
SCOPE="gtk"  # gtk|all

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --all)     SCOPE="all"; shift ;;
    --gtk)     SCOPE="gtk"; shift ;;
    -h|--help)
      echo "Usage: $0 [--gtk|--all] [--dry-run]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
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
need_cmd find
need_cmd xargs

# NOTE: This replaces only the exact old-palette RGB triplets (with optional alpha preserved).
# Also allows "rgb (" spacing.
PERL_RGB_EXPR='
my %map = (
  "20,18,22"    => [1,40,74],      # #141216 -> #01284A
  "39,35,43"    => [0,64,104],     # #27232b -> #004068
  "216,202,184" => [248,240,225],  # #d8cab8 -> #F8F0E1
  "172,130,233" => [82,179,188],   # #ac82e9 -> #52B3BC
  "143,86,225"  => [61,151,160],   # #8f56e1 -> #3D97A0

  # IMPORTANT: Old palette uses #c4e881 for "Complementary Accent" AND "Green" (same value).
  # Pick ONE mapping:
  "196,232,129" => [82,188,144],   # -> #52BC90 (keep it green)
  # "196,232,129" => [184,6,4],    # -> #B80604 (if you truly want it to become the red complementary accent)

  "252,177,103" => [239,95,49],    # #fcb167 -> #EF5F31
  "252,70,73"   => [215,18,13],    # #fc4649 -> #D7120D
  "243,252,123" => [238,212,172],  # #f3fc7b -> #EED4AC
  "123,145,252" => [3,75,116],     # #7b91fc -> #034B74
  "146,252,250" => [137,213,218],  # #92fcfa -> #89D5DA
  "252,146,252" => [188,82,144],   # #fc92fc -> #BC5290
);

sub to255 {
  my ($v) = @_;
  $v =~ s/^\s+|\s+$//g;
  if ($v =~ /%$/) { $v =~ s/%$//; return int($v * 2.55 + 0.5); }
  return int($v + 0.5);
}

s{
  \b(rgb|rgba)\s*\(
    \s*([0-9.]+%?)\s*(?:,\s*|\s+)
    ([0-9.]+%?)\s*(?:,\s*|\s+)
    ([0-9.]+%?)
    (?:\s*(?:,\s*|\/\s*)\s*([0-9.]+%?))?
  \s*\)
}{
  my ($fn,$r,$g,$b,$a)=($1,$2,$3,$4,$5);
  my ($ri,$gi,$bi) = (to255($r), to255($g), to255($b));
  my $key = "$ri,$gi,$bi";

  if (exists $map{$key}) {
    my ($nr,$ng,$nb)=@{$map{$key}};
    defined $a ? "rgba($nr, $ng, $nb, $a)" : "rgb($nr, $ng, $nb)";
  } else {
    $&
  }
}gex;
'

echo "Scope: $SCOPE"
echo "Stage 2: scanning CSS/SCSS for rgb()/rgba()..."

# 1) find only CSS/SCSS
# 2) filter down to files that actually contain rgb/rgba
# 3) dry-run prints file list; otherwise apply perl in-place
find "${DIRS[@]}" -type f \( -iname '*.css' -o -iname '*.scss' \) \
  ! -path '*/.git/*' \
  ! -name 'wallhaven-*.jpg' \
  ! -name "$(basename "$0")" \
  -print0 \
| xargs -0 rg -0 -l -i -S '\brgba?\s*\(' \
| if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Dry run: files containing rgb()/rgba():"
    tr '\0' '\n'
  else
    echo "Applying rgb()/rgba() replacements..."
    xargs -0 perl -pi -e "$PERL_RGB_EXPR"
  fi

[[ "$DRY_RUN" -eq 1 ]] || echo "Stage 2 done. Review: git diff"