#!/bin/bash
# Android SDK 初期セットアップ（ライセンス同意・system image取得・AVD作成）
set -uo pipefail

ANDROID_SDK_DIR="/opt/android-sdk"
SDKMANAGER="$ANDROID_SDK_DIR/cmdline-tools/latest/bin/sdkmanager"
AVDMANAGER="$ANDROID_SDK_DIR/cmdline-tools/latest/bin/avdmanager"

if [ ! -d "$ANDROID_SDK_DIR" ]; then
  echo "!! $ANDROID_SDK_DIR が存在しません。android-sdk-* パッケージ導入後に再実行してください" >&2
  exit 0
fi

sudo chown -R "$USER":"$USER" "$ANDROID_SDK_DIR" 2>/dev/null || true

if [ -x "$SDKMANAGER" ]; then
  echo "==> Android SDK: ライセンスに同意中"
  yes | "$SDKMANAGER" --sdk_root="$ANDROID_SDK_DIR" --licenses >/dev/null 2>&1 || true
  echo "==> Android SDK: platform / system-image を取得中"
  "$SDKMANAGER" --sdk_root="$ANDROID_SDK_DIR" \
    "platforms;android-36" \
    "system-images;android-36;google_apis_playstore;x86_64" >/dev/null 2>&1 || true
fi

if [ -x "$AVDMANAGER" ] && [ ! -d "$HOME/.android/avd/flutter_emulator.avd" ]; then
  echo "==> Android SDK: flutter_emulator AVD を作成中"
  echo no | "$AVDMANAGER" create avd \
    --path "$HOME/.android/avd/flutter_emulator.avd" \
    -n flutter_emulator \
    -k "system-images;android-36;google_apis_playstore;x86_64" >/dev/null 2>&1 || true

  # avdmanagerの既定はGPU無効(ソフトウェア描画)で極端に遅いため有効化する
  AVD_CONFIG="$HOME/.android/avd/flutter_emulator.avd/config.ini"
  if [ -f "$AVD_CONFIG" ]; then
    sed -i 's/^hw\.gpu\.enabled=.*/hw.gpu.enabled=yes/' "$AVD_CONFIG"
    sed -i 's/^hw\.gpu\.mode=.*/hw.gpu.mode=host/' "$AVD_CONFIG"
    grep -q '^hw\.gpu\.enabled=' "$AVD_CONFIG" || echo 'hw.gpu.enabled=yes' >> "$AVD_CONFIG"
    grep -q '^hw\.gpu\.mode='    "$AVD_CONFIG" || echo 'hw.gpu.mode=host'    >> "$AVD_CONFIG"
  fi
fi
