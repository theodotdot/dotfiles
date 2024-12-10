#!/bin/bash

# Folder to save the downloads
DOWNLOAD_FOLDER="$HOME/.config/zellij/plugins"
mkdir -p "$DOWNLOAD_FOLDER"

# List of GitHub repositories in the format "owner/repo"
REPOS=(
    "karimould/zellij-forgot"
    "dj95/zjstatus"
)

for REPO in "${REPOS[@]}"; do
    echo "Fetching latest release for $REPO..."
    API_URL="https://api.github.com/repos/$REPO/releases/latest"
    
    RESPONSE=$(curl -s "$API_URL")
    
    # Extract all .wasm download URLs
    DOWNLOAD_URLS=$(echo "$RESPONSE" | grep "browser_download_url" | grep ".wasm" | cut -d '"' -f 4)
    
    if [ -n "$DOWNLOAD_URLS" ]; then
        echo "Found the following .wasm files for $REPO:"
        echo "$DOWNLOAD_URLS"
        
        for URL in $DOWNLOAD_URLS; do
            FILENAME=$(basename "$URL")
            echo "Downloading $FILENAME..."
            curl -L "$URL" -o "$DOWNLOAD_FOLDER/$FILENAME"
        done
    else
        echo "No .wasm files found for $REPO."
    fi
done

echo "All downloads complete. Files saved to $DOWNLOAD_FOLDER."
