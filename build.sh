#!/usr/bin/env sh

HUGO_BIN="hugo"

# build static pages
${HUGO_BIN}

# ahead of time compression and timestamp fixing
find public/ -type f \( -name '*.html' -o -name '*.js' -o -name '*.css' -o -name '*.xml' -o -name '*.svg' \) -exec gzip -v -k -f --best "{}" \; -exec touch -r "{}" "{}.gz" \;
