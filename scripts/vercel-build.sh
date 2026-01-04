#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter not found, installing stable SDK..."
  git clone --depth 1 https://github.com/flutter/flutter.git -b stable
  export PATH="$ROOT_DIR/flutter/bin:$PATH"
fi

flutter config --no-enable-analytics >/dev/null 2>&1 || true
flutter --version

cat > .env <<EOF
RTC_PROVIDER=${RTC_PROVIDER:-agora}

AGORA_APP_ID=${AGORA_APP_ID:-}
AGORA_TOKEN=${AGORA_TOKEN:-}
AGORA_CHANNEL=${AGORA_CHANNEL:-classroom-demo}
AGORA_UID=${AGORA_UID:-0}

LIVEKIT_URL=${LIVEKIT_URL:-}
LIVEKIT_TOKEN=${LIVEKIT_TOKEN:-}
LIVEKIT_ROOM=${LIVEKIT_ROOM:-classroom-demo}

DEMO_MODE=${DEMO_MODE:-false}
EOF

flutter pub get
flutter build web --dart-define=FLUTTER_WEB_USE_SKIA=true --dart-define=FLUTTER_WEB_USE_SKWASM=false
