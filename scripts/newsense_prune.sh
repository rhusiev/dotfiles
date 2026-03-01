#!/bin/bash

REPO_PREFIX="ghcr.io/rhusiev/newsense-"

# 1. Get IDs of images tagged as 'latest' for the specific prefix
LATEST_IDS=$(docker image list --format "{{.Repository}} {{.Tag}} {{.ID}}" | \
    awk -v prefix="$REPO_PREFIX" '$1 ~ "^"prefix && $2 == "latest" {print $3}' | \
    sort -u)

# 2. Get all unique IDs for images in the namespace
ALL_IDS=$(docker image list --format "{{.Repository}} {{.ID}}" | \
    awk -v prefix="$REPO_PREFIX" '$1 ~ "^"prefix {print $2}' | \
    sort -u)

# 3. Determine which IDs to delete
# comm -23 returns lines unique to the first file (ALL_IDS) when both are sorted.
# This gives us IDs that exist but are NOT tagged as 'latest'.
TO_DELETE=$(comm -23 <(echo "$ALL_IDS") <(echo "$LATEST_IDS"))

if [ -z "$TO_DELETE" ]; then
    echo "No old images to delete."
else
    echo "The following image IDs will be deleted:"
    echo "$TO_DELETE"
    echo "----------------------------------------"
    # Delete the images. 
    echo "$TO_DELETE" | xargs docker rmi -f
fi
