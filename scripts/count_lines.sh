#!/usr/bin/env bash

# Usage:
#   ./count_lines.sh
#   ./count_lines.sh rs py js ts

extensions=("$@")

if [ ${#extensions[@]} -eq 0 ]; then
  extensions=(rs py js ts jsx tsx html css)
fi

git ls-files --cached --others --exclude-standard \
  | awk -v exts="${extensions[*]}" '
      BEGIN {
        n = split(exts, a, " ")
        for (i = 1; i <= n; i++) allowed[a[i]] = 1
      }
      {
        ext = $0
        sub(/^.*\./, "", ext)
        if (allowed[ext]) print
      }
    ' \
  | xargs -r wc -l \
  | tail -n 1 \
  | awk '{print $1}'
