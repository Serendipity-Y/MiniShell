#!/bin/zsh

# 双击此文件即可构建 MiniShell，并安装到“应用程序”。

set -euo pipefail

PROJECT_ROOT="${0:A:h}"
APP_NAME="MiniShell"
BUILD_ROOT="$PROJECT_ROOT/build/local-install"
DERIVED_DATA="$BUILD_ROOT/DerivedData"
BUILT_APP="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"
APPLICATIONS_DIR="/Applications"
DESTINATION_APP="$APPLICATIONS_DIR/$APP_NAME.app"
STAGING_APP="$APPLICATIONS_DIR/.$APP_NAME.installing.$RANDOM.app"
BACKUP_DIR="$BUILD_ROOT/backups"

print "\n正在构建 $APP_NAME…"
xcodebuild build \
  -project "$PROJECT_ROOT/macSCP.xcodeproj" \
  -scheme macSCP \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO

if [[ ! -d "$BUILT_APP" ]]; then
  print -u2 "构建未生成 $APP_NAME.app，安装已取消。"
  exit 1
fi

if [[ ! -w "$APPLICATIONS_DIR" ]]; then
  print -u2 "没有“应用程序”目录的写入权限，安装已取消。"
  exit 1
fi

print "正在准备安装…"
rm -rf -- "$STAGING_APP"
ditto "$BUILT_APP" "$STAGING_APP"

if [[ -d "$DESTINATION_APP" ]]; then
  mkdir -p "$BACKUP_DIR"
  BACKUP_APP="$BACKUP_DIR/$APP_NAME-$(date +%Y%m%d-%H%M%S).app"
  mv "$DESTINATION_APP" "$BACKUP_APP"

  if ! mv "$STAGING_APP" "$DESTINATION_APP"; then
    print -u2 "安装失败，正在恢复旧版本…"
    mv "$BACKUP_APP" "$DESTINATION_APP"
    exit 1
  fi

  print "安装完成。旧版本已备份到：$BACKUP_APP"
else
  mv "$STAGING_APP" "$DESTINATION_APP"
  print "安装完成。"
fi

print "\nMiniShell 已安装到：$DESTINATION_APP"
print "以后双击本文件，即可构建并覆盖安装最新版。"
