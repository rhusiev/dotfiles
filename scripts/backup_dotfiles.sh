#!/bin/bash
cd /home/rad1an/dotfiles
git add .
git commit -m "Regular backup `date +\"%Y.%m.%d %T\"`"
git push
