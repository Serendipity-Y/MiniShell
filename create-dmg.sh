#!/bin/bash

# MiniShell DMG Creator Script
# Usage: VERSION=1.0.0 ./create-dmg.sh

set -euo pipefail

APP_NAME="MiniShell"
VERSION="${VERSION:?请通过 VERSION=1.0.0 指定发布版本}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d)}"
RELEASE_BUILD_ROOT="${RELEASE_BUILD_ROOT:-build/release}"
DERIVED_DATA_PATH="${RELEASE_BUILD_ROOT}/DerivedData"
PRODUCT_APP="${DERIVED_DATA_PATH}/Build/Products/Release/${APP_NAME}.app"
FINAL_DMG="${RELEASE_BUILD_ROOT}/${APP_NAME}-${VERSION}.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/minishell-dmg.XXXXXX")"

cleanup() {
    rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

echo "正在构建 ${APP_NAME} ${VERSION}…"
xcodebuild build \
    -project macSCP.xcodeproj \
    -scheme macSCP \
    -configuration Release \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    CODE_SIGNING_ALLOWED=NO \
    MARKETING_VERSION="${VERSION}" \
    CURRENT_PROJECT_VERSION="${BUILD_NUMBER}"

if [ ! -d "${PRODUCT_APP}" ]; then
    echo "未找到构建产物：${PRODUCT_APP}" >&2
    exit 1
fi

actual_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${PRODUCT_APP}/Contents/Info.plist")
if [ "${actual_version}" != "${VERSION}" ]; then
    echo "应用版本不匹配：期望 ${VERSION}，实际 ${actual_version}" >&2
    exit 1
fi

mkdir -p "${RELEASE_BUILD_ROOT}"
cp -R "${PRODUCT_APP}" "${STAGING_DIR}/${APP_NAME}.app"
ln -s /Applications "${STAGING_DIR}/Applications"
rm -f "${FINAL_DMG}"

echo "正在创建 DMG…"
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${FINAL_DMG}"

echo "DMG 已创建：${FINAL_DMG}"
echo "大小：$(du -h "${FINAL_DMG}" | cut -f1)"
echo "安装方式：双击后将 ${APP_NAME} 拖入 Applications 文件夹。"
