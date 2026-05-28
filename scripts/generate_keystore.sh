#!/bin/bash

# Generate Android signing keystore
# Run this once to create the keystore file

KEYSTORE_PATH="mobile/android/app/photosync.keystore"
ALIAS="photosync"
STORE_PASSWORD="your_store_password_here"
KEY_PASSWORD="your_key_password_here"

keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "$STORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "CN=PhotoSync, OU=Threel, O=Threel, L=Beijing, ST=Beijing, C=CN"

echo "Keystore generated at: $KEYSTORE_PATH"
echo ""
echo "Add these secrets to your GitHub repository:"
echo "KEYSTORE_BASE64: $(base64 -w 0 "$KEYSTORE_PATH")"
echo "KEYSTORE_PASSWORD: $STORE_PASSWORD"
echo "KEY_PASSWORD: $KEY_PASSWORD"
echo "KEY_ALIAS: $ALIAS"
