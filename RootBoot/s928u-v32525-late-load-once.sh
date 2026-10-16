#!/system/bin/sh

LOADER=/data/local/tmp/ksud-s25u-kdp-v32525
EXPECTED=0404476629471d26233721f0a65a90f6fa57f4105416079dd91597027338e3fb

echo "===== VERIFY ROOT ====="
[ "$(id -u)" = "0" ] || {
    echo "STOP: Bootstrap root unavailable"
    exit 1
}

echo "===== VERIFY LOADER ====="
ACTUAL=$(sha256sum "$LOADER" | cut -d' ' -f1)
[ "$ACTUAL" = "$EXPECTED" ] || {
    echo "STOP: Loader hash mismatch"
    exit 1
}

if grep -qi kernelsu /proc/modules; then
    echo "STOP: KernelSU already loaded"
    exit 1
fi

echo "===== PREPARE LOADER ====="
cp "$LOADER" /data/local/tmp/.ksud-stage || exit 1
chmod 755 /data/local/tmp/.ksud-stage

echo "===== BIND LOADER ====="
mount -o bind "$LOADER" /system/bin/logcat || exit 1
trap 'umount /system/bin/logcat 2>/dev/null || true' 0

echo "===== LOAD KERNELSU ====="
RUST_LOG=info /system/bin/logcat late-load --allow-shell
RESULT=$?

echo "===== LOADER EXIT CODE: $RESULT ====="
exit "$RESULT"
