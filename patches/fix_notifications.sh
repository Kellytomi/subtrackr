#!/bin/bash

# Find all flutter_local_notifications packages
PACKAGE_PATHS=$(find ~/.pub-cache/hosted/pub.dev -name "flutter_local_notifications-*")

if [ -z "$PACKAGE_PATHS" ]; then
  echo "Could not find any flutter_local_notifications packages"
  exit 1
fi

# Process each package
for PACKAGE_PATH in $PACKAGE_PATHS; do
  echo "Found flutter_local_notifications at: $PACKAGE_PATH"

  # Find the file that contains the bigLargeIcon method
  JAVA_FILE="$PACKAGE_PATH/android/src/main/java/com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java"

  if [ ! -f "$JAVA_FILE" ]; then
    echo "Could not find the Java file in $PACKAGE_PATH"
    continue
  fi

  echo "Found Java file at: $JAVA_FILE"

  # Create a backup of the file
  cp "$JAVA_FILE" "$JAVA_FILE.bak"

  # Comment out the bigLargeIcon line
  sed -i '' 's/bigPictureStyle.bigLargeIcon(null);/\/\/ bigPictureStyle.bigLargeIcon(null);/' "$JAVA_FILE"

  echo "Fixed the bigLargeIcon issue in $PACKAGE_PATH"
done

echo "All packages fixed" 