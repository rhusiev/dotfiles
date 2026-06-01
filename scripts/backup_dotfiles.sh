#!/bin/bash
cd /home/rad1an/dotfiles
./scripts/sync_flatpak_dotfiles.sh
git add .
git commit -m "Regular backup `date +\"%Y.%m.%d %T\"`"
git push
