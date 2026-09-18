#!/usr/bin/env bash
# Install the bundled Dexory brand fonts (Inter + IBM Plex Mono) into the
# environment so LibreOffice-based QA renders decks/docs with the REAL fonts
# instead of substituting them. Run this ONCE per session before rendering
# slides/pages to images for visual QA.
#
# Why the aliases: the Inter static TTFs register under the family name
# "Inter 28pt", but a Google-Slides-ready deck asks for plain "Inter". Without
# an alias LibreOffice would substitute a default face and your overflow checks
# would be wrong. The alias maps "Inter" -> "Inter 28pt" (and the Light/SemiBold
# optical variants) so QA matches what Google Slides will show.
#
# Usage:  bash scripts/install_fonts.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/../assets/fonts"
DEST="${HOME}/.fonts"
mkdir -p "$DEST"
cp -f "$SRC"/*.ttf "$DEST"/

CONF_DIR="${HOME}/.config/fontconfig/conf.d"
mkdir -p "$CONF_DIR"
cat > "$CONF_DIR/49-dexory.conf" <<'XML'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias><family>Inter</family><prefer><family>Inter 28pt</family></prefer></alias>
  <alias><family>Inter Light</family><prefer><family>Inter 28pt Light</family></prefer></alias>
  <alias><family>Inter SemiBold</family><prefer><family>Inter 28pt SemiBold</family></prefer></alias>
</fontconfig>
XML

fc-cache -f >/dev/null 2>&1 || true
echo "Installed Dexory fonts + aliases. Resolving check:"
for fam in "Inter" "Inter Light" "Inter SemiBold" "IBM Plex Mono" "IBM Plex Mono SemiBold"; do
  printf '  %-24s -> ' "$fam"
  fc-match "$fam" 2>/dev/null || echo "(fc-match unavailable)"
done
