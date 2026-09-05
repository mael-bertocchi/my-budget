#!/usr/bin/env bash

set -euo pipefail

BUNDLE_ID="fr.mael-bertocchi.my-budget"
SCHEME="MyBudget"
CONFIGURATION="${MY_BUDGET_CONFIGURATION:-Release}"

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
FRONTEND_DIR="$(dirname "$(dirname "$SCRIPT_PATH")")"
PROJECT="$FRONTEND_DIR/MyBudget.xcodeproj"
BUILD_DIR="$FRONTEND_DIR/build/device"
PROFILE_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"

DEVICE="${MY_BUDGET_DEVICE:-}"
LAUNCH=1
STATUS_ONLY=0

log() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*"; }
fail() { log "error: $*" >&2; exit 1; }

usage() {
    cat <<'USAGE'
Reinstalls My Budget on the paired iPhone, over the network.

  refresh-device-install.sh              rebuild, install, launch
  refresh-device-install.sh --status     days left on the profile
  refresh-device-install.sh --no-launch  leave the app closed
  refresh-device-install.sh --device ID  target a specific device
USAGE
    exit "${1:-0}"
}

profile_days_left() {
    python3 - "$PROFILE_DIR" "$BUNDLE_ID" <<'PY'
import datetime, glob, os, plistlib, subprocess, sys

directory, bundle_id = sys.argv[1], sys.argv[2]
latest = None

for path in glob.glob(os.path.join(directory, "*.mobileprovision")):
    try:
        raw = subprocess.run(
            ["security", "cms", "-D", "-i", path],
            capture_output=True, check=True,
        ).stdout
        profile = plistlib.loads(raw)
    except (subprocess.CalledProcessError, plistlib.InvalidFileException):
        continue

    app_id = profile.get("Entitlements", {}).get("application-identifier", "")
    if not app_id.endswith("." + bundle_id):
        continue

    expiry = profile.get("ExpirationDate")
    if expiry and (latest is None or expiry > latest):
        latest = expiry

if latest is None:
    print("none")
else:
    remaining = latest.replace(tzinfo=datetime.timezone.utc) - datetime.datetime.now(datetime.timezone.utc)
    print(f"{remaining.total_seconds() / 86400:.1f}")
PY
}

resolve_device() {
    local json
    json="$(mktemp)"
    trap 'rm -f "$json"' RETURN

    xcrun devicectl list devices --json-output "$json" >/dev/null 2>&1 || fail "could not list devices — is Xcode installed?"

    python3 - "$json" <<'PY'
import json, sys

with open(sys.argv[1]) as handle:
    devices = json.load(handle)["result"]["devices"]

candidates = [
    device for device in devices
    if device["hardwareProperties"]["deviceType"] == "iPhone"
    and device["connectionProperties"].get("pairingState") == "paired"
]
candidates.sort(key=lambda d: d["connectionProperties"].get("tunnelState") == "connected", reverse=True)

print(candidates[0]["identifier"] if candidates else "")
PY
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --status) STATUS_ONLY=1 ;;
        --no-launch) LAUNCH=0 ;;
        --device) DEVICE="${2:-}"; shift ;;
        -h|--help) usage 0 ;;
        *) log "error: unknown option $1" >&2; usage 1 ;;
    esac
    shift
done

if [[ $STATUS_ONLY -eq 1 ]]; then
    days="$(profile_days_left)"
    if [[ "$days" == "none" ]]; then
        log "no profile for $BUNDLE_ID — the app has never been signed on this Mac"
    else
        log "profile for $BUNDLE_ID has $days days left"
    fi
    exit 0
fi

if [[ -z "$DEVICE" ]]; then
    DEVICE="$(resolve_device)"
    [[ -n "$DEVICE" ]] || fail "no paired iPhone found — pair one in Xcode (Window > Devices and Simulators)"
fi

log "building $SCHEME ($CONFIGURATION)"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" -destination "id=$DEVICE" -derivedDataPath "$BUILD_DIR" -allowProvisioningUpdates build >/dev/null || fail "build failed — run the same command by hand to see why"

log "installing onto the device"
xcrun devicectl device install app --device "$DEVICE" "$BUILD_DIR/Build/Products/$CONFIGURATION-iphoneos/$SCHEME.app" >/dev/null || fail "install failed — is the iPhone unlocked and on the same network?"

if [[ $LAUNCH -eq 1 ]]; then
    xcrun devicectl device process launch --device "$DEVICE" --terminate-existing "$BUNDLE_ID" >/dev/null || fail "launch refused — trust the developer under Settings > General > VPN & Device Management, then rerun"
fi

log "done — good for another $(profile_days_left) days"
