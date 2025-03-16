#!/bin/bash

# Get the path to the flutter_local_notifications package
PACKAGE_PATH=$(find ~/.pub-cache/hosted/pub.dev -name "flutter_local_notifications-*" | head -1)

if [ -z "$PACKAGE_PATH" ]; then
  echo "Could not find flutter_local_notifications package path"
  exit 1
fi

echo "Found flutter_local_notifications at: $PACKAGE_PATH"

# Get the absolute path to the patch file
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATCH_FILE="$SCRIPT_DIR/flutter_local_notifications_fix.patch"

# Apply the patch
cd "$PACKAGE_PATH" || exit 1
patch -p1 < "$PATCH_FILE"

echo "Patch applied successfully" 