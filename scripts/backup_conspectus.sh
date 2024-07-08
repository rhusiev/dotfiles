#!/bin/bash
cd /home/rad1an/Drive/conspectus/Conspectus
git pull
git add .
git commit -m "Regular backup `date +\"%Y.%m.%d %T\"`"
git fetch
git merge --no-edit
git add .
git commit -m "automerge"
git push
echo "Sync is finished"
