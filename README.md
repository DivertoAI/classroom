# Classroom Studio (Flutter Web + Agora/LiveKit)

A custom classroom UI demo built in Flutter Web with RTC video, a whiteboard surface, resources list, and live chat layout. This is meant as a polished Upwork-ready demo that shows a designed classroom experience instead of a default video call UI.

## Setup

1. Copy `.env.example` to `.env`.
2. Choose the provider:
   - `RTC_PROVIDER=agora` (default)
   - `RTC_PROVIDER=livekit`

### Agora config

- `AGORA_APP_ID` (required)
- `AGORA_TOKEN` (optional if your Agora project has App Certificate disabled)
- `AGORA_CHANNEL` (optional)
- `AGORA_UID` (optional, must match the UID used when generating the token)

### LiveKit config

- `LIVEKIT_URL` (required)
- `LIVEKIT_TOKEN` (required)
- `LIVEKIT_ROOM` (optional)

## Run (web)

```bash
flutter pub get
flutter run -d chrome
```

If you are on a recent Flutter version where `--web-renderer` is removed, force
CanvasKit (needed for Agora platform views):

```bash
flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true --dart-define=FLUTTER_WEB_USE_SKWASM=false
```

## Build for hosting

```bash
flutter build web
```

Then deploy `build/web` to Netlify, Vercel, Firebase Hosting, or any static host.

## Vercel (GitHub)

This repo includes `vercel.json` and `scripts/vercel-build.sh` so Vercel can
build Flutter on CI. In your Vercel project settings, add these environment
variables:

- `AGORA_APP_ID`
- `AGORA_TOKEN` (temp token; expires)
- `AGORA_CHANNEL` (default `classroom-demo`)
- `AGORA_UID` (default `0`)

Vercel will run the build and publish `build/web`.

## Notes

- The Agora web runtime depends on the Iris Web SDK loaded in `web/index.html`.
- Make sure your token matches the channel name and UID you join with.
- LiveKit tokens should be generated server-side (using your LiveKit API key/secret). Only the token goes into `.env`.
- `.env` stays local and is ignored by git; keep tokens there per the request.
