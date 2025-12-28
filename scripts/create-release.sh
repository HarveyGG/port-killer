#!/bin/bash

# Script to create a release and prepare for Homebrew Cask
set -e

VERSION="${1:-3.0.0}"
APP_NAME="PortKiller"
BUILD_DIR=".build/release"
ZIP_NAME="${APP_NAME}-v${VERSION}.zip"

echo "🔨 Building app..."
bash scripts/build-app.sh

echo ""
echo "📦 Creating zip archive..."
cd $BUILD_DIR
zip -r "$ZIP_NAME" "${APP_NAME}.app"
cd ../..

echo ""
echo "📊 Calculating SHA256..."
SHA256=$(shasum -a 256 "$BUILD_DIR/$ZIP_NAME" | awk '{print $1}')
echo "SHA256: $SHA256"

echo ""
echo "📝 Release file created: $BUILD_DIR/$ZIP_NAME"
echo ""
echo "Next steps:"
echo "1. Create a GitHub Release:"
echo "   - Tag: v${VERSION}"
echo "   - Title: v${VERSION}"
echo "   - Upload: $BUILD_DIR/$ZIP_NAME"
echo ""
echo "2. Update Homebrew Cask:"
echo "   - Update version: $VERSION"
echo "   - Update sha256: $SHA256"
echo "   - Update URL if needed"
echo ""
echo "3. Test installation:"
echo "   brew tap HarveyGG/tap"
echo "   brew install --cask harveygg-port-killer"

