#!/bin/bash
#
# Build, sign, notarize, and release Automata via GitHub Releases with Sparkle.
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCHEME="Automata"
APP_NAME="Automata"
KEYCHAIN_PROFILE="notary"
SPARKLE_VERSION="2.9.0"
GITHUB_REPO="Apparata/Automata"
TEAM_ID="DR5YAK7GKS"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
SPARKLE_TOOLS_DIR="$PROJECT_DIR/Sparkle-tools"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"
INFO_PLIST="$PROJECT_DIR/$APP_NAME/Info.plist"
PROJECT_FILE="$PROJECT_DIR/$APP_NAME.xcodeproj/project.pbxproj"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
error() {
    echo "ERROR: $*" >&2
    exit 1
}

info() {
    echo ""
    echo "==> $*"
}

show_log_tail() {
    local log="$1"
    if [ -f "$log" ]; then
        echo "--- Last 30 lines of $log ---" >&2
        tail -30 "$log" >&2
        echo "--- end ---" >&2
    fi
}

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------
command -v xcodebuild >/dev/null 2>&1 || error "xcodebuild not found"
command -v gh >/dev/null 2>&1 || error "gh (GitHub CLI) not found"
command -v hdiutil >/dev/null 2>&1 || error "hdiutil not found"
command -v curl >/dev/null 2>&1 || error "curl not found"

[ -f "$EXPORT_OPTIONS" ] || error "ExportOptions.plist not found at $EXPORT_OPTIONS"
[ -f "$INFO_PLIST" ] || error "Info.plist not found at $INFO_PLIST"

# ---------------------------------------------------------------------------
# Clean build directory
# ---------------------------------------------------------------------------
info "Preparing build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ---------------------------------------------------------------------------
# Ensure Sparkle tools are available
# ---------------------------------------------------------------------------
if [ ! -x "$SPARKLE_TOOLS_DIR/bin/sign_update" ]; then
    info "Downloading Sparkle $SPARKLE_VERSION tools"
    curl -sL "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz" \
        -o "$BUILD_DIR/Sparkle.tar.xz" || error "Failed to download Sparkle tools"
    mkdir -p "$SPARKLE_TOOLS_DIR"
    tar -xf "$BUILD_DIR/Sparkle.tar.xz" -C "$SPARKLE_TOOLS_DIR" || error "Failed to extract Sparkle tools"
    rm "$BUILD_DIR/Sparkle.tar.xz"
fi

# ---------------------------------------------------------------------------
# Read current version
# ---------------------------------------------------------------------------
info "Reading current version"
CURRENT_VERSION="$(xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep -E "^\s*MARKETING_VERSION\s*=" | head -1 | awk -F'= ' '{print $2}' | xargs || true)"
if [ -z "${CURRENT_VERSION:-}" ]; then
    CURRENT_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || true)"
fi
[ -n "${CURRENT_VERSION:-}" ] || error "Unable to determine current version"
echo "Current project version: $CURRENT_VERSION"

# ---------------------------------------------------------------------------
# Check against latest GitHub release and prompt if necessary
# ---------------------------------------------------------------------------
info "Checking latest GitHub release"
LATEST_RELEASE="$(gh release view --repo "$GITHUB_REPO" --json tagName -q '.tagName' 2>/dev/null || true)"
if [ -n "$LATEST_RELEASE" ]; then
    echo "Latest GitHub release: $LATEST_RELEASE"
else
    echo "No prior GitHub release found"
fi

version_is_greater() {
    # Returns 0 if $1 > $2 (using sort -V).
    local a="$1"
    local b="$2"
    if [ "$a" = "$b" ]; then
        return 1
    fi
    local highest
    highest="$(printf '%s\n%s\n' "$a" "$b" | sort -V | tail -1)"
    [ "$highest" = "$a" ]
}

NEW_VERSION="$CURRENT_VERSION"
VERSION_CHANGED="no"

if [ -n "$LATEST_RELEASE" ] && ! version_is_greater "$CURRENT_VERSION" "$LATEST_RELEASE"; then
    echo "Current version ($CURRENT_VERSION) is not newer than latest release ($LATEST_RELEASE)."
    while true; do
        read -r -p "Enter new version: " NEW_VERSION
        if [ -z "$NEW_VERSION" ]; then
            echo "Version cannot be empty."
            continue
        fi
        if version_is_greater "$NEW_VERSION" "$LATEST_RELEASE"; then
            break
        fi
        echo "Version must be greater than $LATEST_RELEASE."
    done
    VERSION_CHANGED="yes"
fi

# ---------------------------------------------------------------------------
# Update version in project.pbxproj and Info.plist
# ---------------------------------------------------------------------------
if [ "$VERSION_CHANGED" = "yes" ]; then
    info "Updating version to $NEW_VERSION"

    # Update MARKETING_VERSION in project.pbxproj
    sed -i '' -E "s/(MARKETING_VERSION = )[^;]+;/\1$NEW_VERSION;/g" "$PROJECT_FILE"

    # Update CURRENT_PROJECT_VERSION in project.pbxproj (Sparkle needs this bumped)
    sed -i '' -E "s/(CURRENT_PROJECT_VERSION = )[^;]+;/\1$NEW_VERSION;/g" "$PROJECT_FILE"

    # Update Info.plist (CFBundleShortVersionString and CFBundleVersion both set to NEW_VERSION)
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" "$INFO_PLIST"

    # Commit and push
    cd "$PROJECT_DIR"
    git add "$PROJECT_FILE" "$INFO_PLIST"
    git commit -m "Bump version to $NEW_VERSION"
    git push origin HEAD
fi

VERSION="$NEW_VERSION"
TAG="$VERSION"

# ---------------------------------------------------------------------------
# Archive
# ---------------------------------------------------------------------------
info "Archiving $APP_NAME"
set +e
xcodebuild archive \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    -arch arm64 \
    ENABLE_HARDENED_RUNTIME=YES \
    2>&1 | tee "$BUILD_DIR/archive.log" | tail -5
ARCHIVE_STATUS=${PIPESTATUS[0]}
set -e
if [ "$ARCHIVE_STATUS" -ne 0 ] || [ ! -d "$ARCHIVE_PATH" ]; then
    show_log_tail "$BUILD_DIR/archive.log"
    error "xcodebuild archive failed"
fi

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------
info "Exporting archive"
set +e
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    2>&1 | tee "$BUILD_DIR/export.log" | tail -5
EXPORT_STATUS=${PIPESTATUS[0]}
set -e

APP_PATH="$EXPORT_DIR/$APP_NAME.app"
if [ "$EXPORT_STATUS" -ne 0 ] || [ ! -d "$APP_PATH" ]; then
    show_log_tail "$BUILD_DIR/export.log"
    error "xcodebuild exportArchive failed"
fi

# Sanity-check version from the exported app
EXPORTED_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")"
EXPORTED_BUILD="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Contents/Info.plist")"
echo "Exported app version: $EXPORTED_VERSION (build $EXPORTED_BUILD)"
[ "$EXPORTED_VERSION" = "$VERSION" ] || error "Exported app version ($EXPORTED_VERSION) does not match expected ($VERSION)"

# ---------------------------------------------------------------------------
# Verify codesign
# ---------------------------------------------------------------------------
info "Verifying codesign"
codesign --verify --deep --strict --verbose=2 "$APP_PATH" || error "Codesign verification failed"

# ---------------------------------------------------------------------------
# Create DMG
# ---------------------------------------------------------------------------
info "Creating DMG"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"
DMG_STAGING="$BUILD_DIR/dmg-staging"

rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -a "$APP_PATH" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" || error "hdiutil create failed"

rm -rf "$DMG_STAGING"
[ -f "$DMG_PATH" ] || error "DMG was not created"

# ---------------------------------------------------------------------------
# Notarize
# ---------------------------------------------------------------------------
info "Submitting DMG for notarization (this may take several minutes)"
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait \
    --timeout 30m \
    2>&1 | tee "$BUILD_DIR/notarize.log" || {
    show_log_tail "$BUILD_DIR/notarize.log"
    error "Notarization failed"
}

if ! grep -q "status: Accepted" "$BUILD_DIR/notarize.log"; then
    show_log_tail "$BUILD_DIR/notarize.log"
    error "Notarization did not return Accepted status"
fi

info "Stapling notarization ticket"
xcrun stapler staple "$DMG_PATH" || error "stapler staple failed"

# ---------------------------------------------------------------------------
# Sparkle signature
# ---------------------------------------------------------------------------
info "Signing DMG with Sparkle EdDSA key"
SPARKLE_SIG_OUTPUT="$("$SPARKLE_TOOLS_DIR/bin/sign_update" "$DMG_PATH")"
echo "$SPARKLE_SIG_OUTPUT"

# ---------------------------------------------------------------------------
# Create GitHub release
# ---------------------------------------------------------------------------
info "Preparing GitHub release $TAG"
read -r -p "Release title (leave blank to use tag): " RELEASE_TITLE
read -r -p "Release subtitle/description (leave blank for none): " RELEASE_SUBTITLE

RELEASE_TITLE="${RELEASE_TITLE:-$TAG}"

cd "$PROJECT_DIR"

# Tag the commit and push
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Tag $TAG already exists locally"
else
    git tag "$TAG"
fi
git push origin "$TAG"

NOTES_FILE="$BUILD_DIR/release-notes.md"
: > "$NOTES_FILE"
if [ -n "$RELEASE_SUBTITLE" ]; then
    printf '%s\n\n' "$RELEASE_SUBTITLE" >> "$NOTES_FILE"
fi

if [ -s "$NOTES_FILE" ]; then
    gh release create "$TAG" \
        --repo "$GITHUB_REPO" \
        --title "$RELEASE_TITLE" \
        --notes-file "$NOTES_FILE" \
        --generate-notes \
        "$DMG_PATH" || error "gh release create failed"
else
    gh release create "$TAG" \
        --repo "$GITHUB_REPO" \
        --title "$RELEASE_TITLE" \
        --generate-notes \
        "$DMG_PATH" || error "gh release create failed"
fi

# ---------------------------------------------------------------------------
# Generate appcast (only include the new DMG, append to existing appcast)
# ---------------------------------------------------------------------------
info "Generating appcast"
APPCAST_DIR="$BUILD_DIR/appcast-assets"
rm -rf "$APPCAST_DIR"
mkdir -p "$APPCAST_DIR"

if [ -f "$PROJECT_DIR/appcast.xml" ]; then
    cp "$PROJECT_DIR/appcast.xml" "$APPCAST_DIR/"
fi

cp "$DMG_PATH" "$APPCAST_DIR/"

"$SPARKLE_TOOLS_DIR/bin/generate_appcast" \
    --download-url-prefix "https://github.com/$GITHUB_REPO/releases/download/$TAG/" \
    -o "$APPCAST_DIR/appcast.xml" \
    "$APPCAST_DIR" || error "generate_appcast failed"

cp "$APPCAST_DIR/appcast.xml" "$PROJECT_DIR/appcast.xml"

cd "$PROJECT_DIR"
git add appcast.xml
if git diff --cached --quiet; then
    echo "No appcast changes to commit"
else
    git commit -m "Update appcast for $VERSION"
    git push origin HEAD
fi

info "Release $TAG complete"
echo "DMG:      $DMG_PATH"
echo "Appcast:  $PROJECT_DIR/appcast.xml"
