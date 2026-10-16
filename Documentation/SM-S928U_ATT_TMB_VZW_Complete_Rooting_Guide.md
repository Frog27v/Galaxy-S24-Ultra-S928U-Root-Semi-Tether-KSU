# Rooting the US Samsung Galaxy S24 Ultra (SM-S928U): AT&T, T-Mobile, and Verizon

**From a stock, unrooted phone on a newer firmware to working KernelSU v3.2.5 with a locked bootloader**  
**Guide date:** 16 October 2026  
**Actually completed on hardware:** AT&T SM-S928U; stock `S928USQS6DZF2`; Android 16; KernelSU manager/driver `32525/32525`; SELinux Enforcing.  
**Other-carrier examples:** T-Mobile (`TMB`) and Verizon (`VZW`) firmware listings are confirmed, but the entire exploit/late-load sequence was **not independently hardware-tested** on either carrier.

## First: the exact supported target

This is an **exact-build procedure**, not a generic S24 Ultra root technique.

| Required item | Value |
|---|---|
| Phone's actual model | `SM-S928U` (US carrier version, not `SM-S928U1`, `SM-S928B`, or `SM-S9280`) |
| Hardware family | Galaxy S24 Ultra / Qualcomm Snapdragon / `e3q` |
| Target AP/PDA build | **`S928USQS6DZF2`** |
| Android version | **16** |
| One UI branch listed for firmware | **8.5** |
| Android security patch | **2026-06-05** |
| **Exact required kernel release** | **`6.1.145-android14-11-33419968-abS928USQS6DZF2`** |
| Samsung bootloader binary/bit | **6** |
| Bootloader state | Locked; no unlocking required in the completed AT&T experiment |
| Root method | CVE-2026-43499 temporary bootstrap + custom Samsung KDP/RKP/DEFEX-compatible KernelSU late-load |
| KernelSU | v3.2.5, manager **32525**, driver **32525** |
| Persistence | **Temporary root; must be reapplied after every reboot** |

The operator's original pre-flash build was **not recorded**. An example of a later, unrooted 2026 firmware is `S928USQS6DZI1` (September 2026 security patch, bootloader bit 6). That is **an example**, not a claim that it was the exact original firmware of the tested phone. Another example is `S928USQU6EZIF` (Android 17 listed for T-Mobile, also bit 6); a matching bootloader bit is necessary but does not independently guarantee every cross-version flash will work.

**What is and isn't supplied:** The repository organizes the supporting materials in `Documentation/` and `RootBoot/`. The rooting procedure needs **four exact, locally built artifacts**, listed in Phase 4. In this repository, the tested binaries are included in `RootBoot/`; **the document itself does not contain the binaries**. This guide is documentation and does not embed the binaries. The modified KernelSU and exploit source checkouts are provided separately under `Source/`, with upstream revisions, patches, and provenance; they are not embedded inside this Markdown file. The public upstream KernelSU loader is **not** byte-equivalent to the tested custom loader. To follow the **working-binary route** below, use the four checksum-verified artifacts in `RootBoot/`. Section 9 explains rebuilding the exploit and why the custom driver requires the modified source. Do not substitute similarly named S25, generic KernelSU, or SM-S928U1 binaries.

---

## Phase 1 — Identify your exact phone and firmware *before* flashing

On the unrooted phone go to **Settings → About phone**. Confirm **model `SM-S928U`**, not merely the retail name “Galaxy S24 Ultra.” Then open **Software information** and record the complete build number, baseband, security patch, and service provider software version (CSC). If USB debugging is already available, the Linux/ADB alternative is:

```bash
adb devices
adb shell 'getprop ro.product.model; getprop ro.build.version.incremental; getprop ro.build.version.release; getprop ro.build.version.security_patch; getprop ro.boot.bootloader; uname -r'
```

If you have not set up ADB yet, the Settings information is enough for the Windows firmware stage. Later, enable developer options by tapping **Build number** seven times under Software information, then enable **USB debugging** in Developer options and approve the computer's ADB prompt.

### Can your current firmware be changed to DZF2?

`S928USQS6DZF2` carries **bootloader binary revision 6**. Samsung's rollback protection disallows flashing a firmware with a bootloader revision below the minimum allowed by the device.

- **Current binary 6:** same-revision DZF2 is the relevant candidate (the tested AT&T phone successfully ended on DZF2).
- **Current binary 5 or below:** moving to bit 6 is possible in principle, but raises the minimum version for later updates/downgrades.
- **Current binary 7 or above:** **this bit-6 DZF2 route is blocked by rollback protection**. Do not proceed with this guide's Odin flash.

`SW REV CHECK FAIL` in Download Mode/Odin indicates a revision check rejection; changing Odin settings does not bypass it. Other anti-rollback or firmware restrictions can also prevent a flash even if the binary number appears compatible.

---

## Phase 2 — Choose the correct carrier firmware on Windows 11

The key distinction between **AT&T, T-Mobile, and Verizon** is the **CSC/firmware download**. All three have a documented **`SM-S928U` / `S928USQS6DZF2`** stock firmware release, but they are not three separately proven KernelSU hardware tests.

| Your original carrier variant | CSC code | Exact DZF2 download page | Example starting build (not required) |
|---|---|---|---|
| **AT&T** | `ATT` | https://samfw.com/firmware/SM-S928U/ATT/S928USQS6DZF2 | `S928USQS6DZI1` → `S928USQS6DZF2` |
| **T-Mobile** | `TMB` | https://samfw.com/firmware/SM-S928U/TMB/S928USQS6DZF2 | `S928USQS6DZI1` → `S928USQS6DZF2` |
| **Verizon** | `VZW` | https://samfw.com/firmware/SM-S928U/VZW/S928USQS6DZF2 | `S928USQS6DZI1` → `S928USQS6DZF2` |

Each linked listing confirms Android 16, One UI 8.5, security patch June 5, 2026, binary 6 and AP `S928USQS6DZF2`, with CSC package `S928UOYN6DZF2`. **Do not use the SM-S928U1, SM-S928B or SM-S9280 download page.** Select the CSC matching the carrier variant and active firmware rather than guessing from the SIM card; a carrier-unlocked phone and a factory-unlocked U1 are different things.

### Windows 11 requirements

1. A Windows 11 PC with Samsung's Android USB driver installed if needed: https://developer.samsung.com/android-usb-driver
2. Samsung **Odin** Windows flashing utility (SamFw links to it from its firmware pages; the exact version used in the AT&T experiment was not captured).
3. 7-Zip or another extractor that can handle large firmware ZIP packages and nested `*.tar.md5.zip` files.
4. A USB-C data cable, the complete firmware package for **`SM-S928U`** and the chosen CSC, and sufficient disk space for its roughly 14 GB download plus extracted files.

### Download and extract the firmware

Download the full **`S928USQS6DZF2`** firmware for your CSC. The AT&T package used in the successful experiment was named:

```text
SAMFW.COM_SM-S928U_ATT_S928USQS6DZF2_fac.zip
```

The files retained in that AT&T firmware collection included:

```text
AP_S928USQS6DZF2_S928USQS6DZF2_MQB110702580_REV00_user_low_ship_MULTI_CERT_meta_OS16.tar.md5.zip
BL_S928USQS6DZF2_S928USQS6DZF2_MQB110702580_REV00_user_low_ship_MULTI_CERT.tar.md5.zip
CP_S928USQS6DZF2_CP34806429_MQB110702580_REV00_user_low_ship_MULTI_CERT.tar.md5.zip
CSC_OYN_S928UOYN6DZF2_MQB110702580_REV00_user_low_ship_MULTI_CERT.tar.md5.zip
HOME_CSC_OYN_S928UOYN6DZF2_MQB110702580_REV00_user_low_ship_MULTI_CERT.tar.md5.zip
```

**Those names end in `.zip`. Extract each of those ZIP wrappers again to obtain the corresponding `.tar.md5` file that Odin accepts.** On the carrier's download page you may also see a `USERDATA_<carrier>_...tar.md5.zip` item. The user's actual Odin USERDATA selection was not recorded, so this guide does not require or silently presume one.

### Boot the S24 Ultra into Samsung Download Mode

1. On Windows, open Odin as administrator if required by the installation.
2. Power the S24 Ultra **off**.
3. Connect the USB-C cable to the PC. Hold **Volume Up + Volume Down together** on the powered-off phone while connecting the cable to the phone.
4. At Samsung's download warning screen, follow the displayed instruction to **press Volume Up to continue** into Download Mode.
5. Odin should show a detected port in **ID:COM**, generally a highlighted/blue connection field. If there is no ID:COM connection, resolve the cable/driver/USB connection before attempting to flash.

### Odin file selection — same steps for ATT, TMB and VZW

| Odin slot | Select this file from the **same carrier firmware package** |
|---|---|
| **BL** | `BL_S928USQS6DZF2_....tar.md5` |
| **AP** | `AP_S928USQS6DZF2_....tar.md5` — this is the very large file; Odin may take time to verify it |
| **CP** | `CP_S928USQS6DZF2_....tar.md5` |
| **CSC** | Either `CSC_OYN_S928UOYN6DZF2_....tar.md5` **or** `HOME_CSC_OYN_S928UOYN6DZF2_....tar.md5`, not both |

`CSC` normally performs a clean reset / data wipe. `HOME_CSC` is the data-preservation variant. The tested phone reached DZF2, but its actual choice between these two files was **not preserved**; either choice is a normal Odin option, not a documented requirement unique to this exploit. The `USERDATA` slot is **not part of this reproduced minimal four-slot sequence**. Leave **Re-Partition unchecked** and do not load a PIT file.

Click **Start**, allow Odin to complete its firmware transfer/validation and wait for **PASS**. The phone should reboot into Samsung's setup or lock screen. The first boot may take longer than normal.

**Examples:**

- **AT&T SM-S928U:** `ATT` DZF2 package → Odin BL/AP/CP + ATT-matching OYN CSC/HOME_CSC → stock Android 16 DZF2.
- **T-Mobile SM-S928U:** `TMB` DZF2 package → Odin BL/AP/CP + TMB-matching OYN CSC/HOME_CSC → stock Android 16 DZF2.
- **Verizon SM-S928U:** `VZW` DZF2 package → Odin BL/AP/CP + VZW-matching OYN CSC/HOME_CSC → stock Android 16 DZF2.

Do not cross-mix the BL/AP/CP/CSC files from differently dated firmware packages. **The original experiment actually flashed AT&T stock firmware on Windows 11; T-Mobile and Verizon are direct, source-confirmed firmware alternatives, not completed field trials.**

---

## Phase 3 — Confirm that Odin produced the exact exploitable target

On the booted phone, enable USB debugging as described in Phase 1. Connect to the Linux Mint computer and authorize the USB debugging confirmation.

Install or locate Android Platform Tools (the successful development computer used **ADB 1.0.41 / Platform Tools 37.0.0**). Run:

```bash
adb devices
adb shell 'getprop ro.product.model; getprop ro.build.version.incremental; getprop ro.build.version.release; getprop ro.build.version.security_patch; uname -r'
```

The **required** results are:

```text
SM-S928U
...S928USQS6DZF2...
16
2026-06-05
6.1.145-android14-11-33419968-abS928USQS6DZF2
```

The build property may contain other characters; it must identify the precise AP build. If **any** identity or kernel-release check fails, the following target-specific exploit and kernel module should not be used.

For additional comparison, the successful AT&T firmware's extracted **`boot.img.lz4`** had SHA-256:

```text
bf212e8c0e3b39743f76f5e0802fde8ba6ca07a048135017c079207708cbbc88
```

That hash matched the published U1 DZF2 kernel boot image used during port selection. A T-Mobile or Verizon reader can independently extract their AP's `boot.img.lz4` and compare it; this **comparison has not been reported for every carrier**. The exact runtime `uname -r` remains the mandatory check in this guide.

---

## Phase 4 — Prepare Linux Mint and the four known-good rooting files

The successful build workstation was **Linux Mint 22.3 Zena x86_64**, although the execution stage only needs a Linux computer with a working `adb` command and the four exact working ARM64 artifacts.

### Minimum Linux tools

```bash
sudo apt update
sudo apt install adb git python3 coreutils
adb version
adb devices
```

If your distribution does not provide a recent enough `adb`, use Google's current official Platform Tools instead: https://developer.android.com/tools/releases/platform-tools. Confirm that `adb devices` reports a device in the `device` state, not `unauthorized` or an empty list.

### Required tested artifacts

Get the project from your own download or clone its repository, then work inside the `RootBoot/` directory:

```bash
git clone https://github.com/Frog27v/Galaxy-S24-Ultra-S928U-Root-Semi-Tether-KSU.git
cd Galaxy-S24-Ultra-S928U-Root-Semi-Tether-KSU/RootBoot
```

If you downloaded the repository as a ZIP instead, extract it and open its `RootBoot/` directory in a terminal. **All four tested artifacts must be present in that directory**, whether distributed there or obtained from a release. Do not substitute unrelated binaries.

Verify the exact hashes:

| File | Purpose | SHA-256 |
|---|---|---|
| `cve43499-root` | Kernel exploit runner and bootstrap-root helper | `54894e9bfa80fc36cfa03bd4ec4279e1d56eccc9719c9ee395b64ffd6792866b` |
| `cve43499-stable.so` | Patched stable ARM64 exploit for E3Q DZF2 | `750a82852f3598f74d96037f73f22748302ab8860d1b6af54fddc276b7c3d3bc` |
| `ksud-s25u-kdp-v32525` | **Custom S928U** KernelSU v32525 loader embedding no-patch-text module | `0404476629471d26233721f0a65a90f6fa57f4105416079dd91597027338e3fb` |
| `s928u-v32525-late-load-once.sh` | Loader script used on Android | `e8dfbf44d3a94a6768d222bd60b80002b89cc1066e04608e9acf0f9e095e0ff0` |

The misleading `s25u` fragment in the **third filename** is a retained filename convention, **not its target model**. Its checksum and embedded kernel module identify the working S24 Ultra build.

Create `EXPECTED_SHA256SUMS.txt` in the directory:

```bash
cat > EXPECTED_SHA256SUMS.txt <<'EOF_HASHES'
54894e9bfa80fc36cfa03bd4ec4279e1d56eccc9719c9ee395b64ffd6792866b  cve43499-root
750a82852f3598f74d96037f73f22748302ab8860d1b6af54fddc276b7c3d3bc  cve43499-stable.so
0404476629471d26233721f0a65a90f6fa57f4105416079dd91597027338e3fb  ksud-s25u-kdp-v32525
e8dfbf44d3a94a6768d222bd60b80002b89cc1066e04608e9acf0f9e095e0ff0  s928u-v32525-late-load-once.sh
EOF_HASHES
sha256sum -c EXPECTED_SHA256SUMS.txt
```

All four must print `OK`. **These binaries were locally built during the October 2026 test; a bare clone of their source repositories does not provide the identical four-file set.** If you cannot obtain the original tested files, use the research/build notes in Phase 9 and wait until a full custom build is available rather than proceeding with unrelated upstream binaries.

### Copy the four artifacts to your phone

From the repository's `RootBoot/` directory (where the hash check above passed):

```bash
adb push cve43499-root /data/local/tmp/cve43499-root
adb push cve43499-stable.so /data/local/tmp/cve43499-stable.so
adb push ksud-s25u-kdp-v32525 /data/local/tmp/ksud-s25u-kdp-v32525
adb push s928u-v32525-late-load-once.sh /data/local/tmp/s928u-v32525-late-load-once.sh
adb shell 'chmod 755 /data/local/tmp/cve43499-root /data/local/tmp/ksud-s25u-kdp-v32525'
```

Confirm the **current phone identity again** directly before executing anything privileged:

```bash
adb shell 'test "$(getprop ro.product.model)" = "SM-S928U" && test "$(uname -r)" = "6.1.145-android14-11-33419968-abS928USQS6DZF2" && echo "PASS: exact target"'
```

Only proceed on `PASS: exact target`.

---

## Phase 5 — Obtain temporary bootstrap root with CVE-2026-43499

Run this in a terminal on Linux Mint, exactly as shown:

```bash
adb shell 'EXPLOIT_ATTEMPTS=1 P0_ATTEMPT_TIMEOUT_SEC=45 EXPLOIT_ATTEMPT_TIMEOUT_SEC=120 /data/local/tmp/cve43499-root --run-payload /data/local/tmp/cve43499-stable.so /data/local/tmp/cve43499-root /data/local/tmp/cve43499-reroot.log'
```

This is a **single exploit attempt** with explicit timeouts. The exploit can reboot or crash a phone if it encounters a different kernel layout or loses the required memory window; this is especially relevant for the T-Mobile and Verizon variants that have not been separately tested in the present record. A finished process is not sufficient evidence of root.

The successful corrected-payload test produced diagnostic markers like:

```text
app fops slide attempt=1/1 triggered=1 verified=1
pipe-physrw-summary ... done=1 root=1
pipe physrw ... uid=2000->0
root umh result wake=1 complete=1 retval=0 socket=1
```

Verify that the bootstrap-root helper works:

```bash
adb shell '/data/local/tmp/cve43499-root -c "id; getenforce"'
```

In the observed successful intermediate state the command reported `uid=0(root)`, context `u:r:kernel:s0`, and `Permissive`. **This is the temporary exploit/bootstrap state**, not the final SELinux status. If root is absent, stop; do not blindly invoke the KernelSU loader or repeat the exploit on a potentially damaged memory state.

---

## Phase 6 — Late-load the custom KernelSU driver

With verified bootstrap root, run:

```bash
adb shell '/data/local/tmp/cve43499-root -c "sh /data/local/tmp/s928u-v32525-late-load-once.sh"'
```

The actual tested script did these operations:

1. Verify the process is UID 0.
2. Verify that `/data/local/tmp/ksud-s25u-kdp-v32525` has the exact expected SHA-256.
3. Verify KernelSU is not already in `/proc/modules`.
4. Copy the loader to `/data/local/tmp/.ksud-stage`.
5. Temporarily bind-mount the loader executable at `/system/bin/logcat`.
6. Execute `RUST_LOG=info /system/bin/logcat late-load --allow-shell` to load the **embedded** custom no-patch-text `kernelsu.ko`.

The displayed output in the successful test reached:

```text
===== VERIFY ROOT =====
===== VERIFY LOADER =====
===== PREPARE LOADER =====
===== BIND LOADER =====
===== LOAD KERNELSU =====
```

The terminal stayed occupied at the last line even though the kernel module had already loaded. **Do not interpret that by itself as a failure or run a second late-load.** Use a **second terminal** to verify.

### Verify KernelSU is actually running

```bash
adb shell 'grep -i kernelsu /proc/modules'
adb shell 'su -c id'
adb shell getenforce
```

Successful output on the AT&T phone was:

```text
kernelsu 217088 0 - Live 0x0000000000000000 (O)
uid=0(root) gid=0(root) groups=0(root) context=u:r:ksu:s0
Enforcing
```

The final `Enforcing` status is important: the intermediate bootstrap stage had been Permissive; final KernelSU operation returned the phone to Enforcing.

### Restore the Android system logcat executable

If KernelSU is running, check for the temporary bind mount:

```bash
adb shell 'su -c "grep -F /system/bin/logcat /proc/self/mountinfo || true"'
```

If a line shows `/data/local/tmp/ksud-s25u-kdp-v32525` mounted at `/system/bin/logcat`, remove **only that temporary bind mount**:

```bash
adb shell 'su -c "umount /system/bin/logcat"'
```

Verify its disappearance and that the original `logcat` works:

```bash
adb shell 'grep -F /system/bin/logcat /proc/self/mountinfo || echo "PASS: Mount removed"'
adb logcat -d -t 2
adb shell 'su -c id'
adb shell getenforce
```

Un-mounting the temporary bind mount does **not** unload KernelSU. In the completed test, `logcat` resumed normal functionality while the module stayed loaded and SELinux remained Enforcing.

---

## Phase 7 — Install and verify the KernelSU Android manager

The tested installation used **KernelSU Manager v3.2.5**, APK version code **32525**. Obtain the corresponding genuine release from the KernelSU releases page:

https://github.com/tiann/KernelSU/releases/tag/v3.2.5

If the APK is on the computer, install it with:

```bash
adb install -r KernelSU_v3.2.5_32525-release.apk
```

Open **KernelSU Manager** on the phone. The completed AT&T experiment ended with:

- Manager: **32525**.
- Kernel driver: **32525**.
- No version-mismatch/too-old-driver warnings.
- `su -c id`: root in `u:r:ksu:s0`.
- SELinux: **Enforcing**.
- Original Android `logcat`: working.

The tested APK hash recorded during the experiment was:

```text
1417081413bf7ab1de8e440ecbcb62685037c8f28f048f0f8b79e305b31ab916
```

**Result:** a locked-bootloader SM-S928U with functioning **temporary** KernelSU root. No unsigned firmware, Magisk-patched `boot.img`, recovery image, or bootloader unlock was flashed.

---

## Phase 8 — After a reboot: the shorter repeat procedure

Root does **not** persist after reboot, but the firmware itself stays on `S928USQS6DZF2` unless the phone is updated or reflashed. Provided the phone is still on the **exact same kernel**, repeat Phases 4–6: connect ADB; verify identity; push/verify the same four files if needed; run the one-shot bootstrap; verify root; run the one-time custom KernelSU late loader; verify `su` and SELinux; remove the temporary `logcat` bind mount if it remains. You do **not** need Odin or Windows every boot.

If an OTA later changes the kernel, the exact-build checks in this guide will fail and the old exploit/module are no longer validated. Installing KernelSU Manager alone does not grant root on an unrooted boot.

### Optional automated `RootBoot` helper (not independently end-to-end verified)

The repository also contains `RootBoot/rootboot.sh`, which is intended to stage the same verified components and perform a single bootstrap/late-load attempt. **Unlike the manual steps in Phases 4–6, the combined helper has not been independently confirmed end-to-end** in the preserved hardware record. Treat it as experimental; it is not a replacement for the verified manual method.

From the **repository root**, with all four verified files present in `RootBoot/`:

```bash
adb shell mkdir -p /sdcard/RootBoot
adb push RootBoot/. /sdcard/RootBoot/
adb shell sh /sdcard/RootBoot/rootboot.sh
```

On Android, `/sdcard/RootBoot/` and `/storage/emulated/0/RootBoot/` are the same shared-storage location. The helper must run via **ADB shell**, not directly as an ordinary Termux app shell. If it fails or times out, check its output and `RootBoot/rootboot-late-load.log` (if written) before attempting anything else. In particular, inspect whether the loader left a temporary `/system/bin/logcat` bind mount in place; see Phase 6 for how to check and remove it once KernelSU root is functioning. The helper does not retry the exploit automatically.

---

## Phase 9 — Development/build recipe and the exact discoveries behind the working files

These notes explain how the tested binaries were produced. They are intended for developers who want to publish a reproducible release, not as a claim that all custom patches are already present in upstream.

### 9.1 Compiling the patched exploit on Linux Mint

Toolchain used: Git 2.43.0, Python 3.12.3, GNU Make 4.3, Android NDK r29 (`29.0.14206865`, LLVM/Clang 21). The payload was based on this pinned repository revision:

```text
https://github.com/BuSung-dev/Root-My-Galaxy-Payloads
commit 6e3223e689688540060ddd97a0927e927bfed207
profile e3q-S928USQS6DZF2
```

Build prerequisite:

```bash
sudo apt install git make python3 build-essential
# Obtain Android NDK r29 in the Android SDK, e.g. with Android sdkmanager:
# sdkmanager --install 'ndk;29.0.14206865'
export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/29.0.14206865"

git clone https://github.com/BuSung-dev/Root-My-Galaxy-Payloads.git
cd Root-My-Galaxy-Payloads
git checkout 6e3223e689688540060ddd97a0927e927bfed207
```

The decisive local source fix was **two** readiness checks in `src/slide_app.c`: change **only the two appropriate stable app-stack-write gates** from `atomic_load(&slide_pselect_write_window)` to `atomic_load(&slide_stack_write_window)`. Do not globally replace unrelated references; in the tested local checkout exactly two locations were changed. Then:

```bash
make TARGET=e3q-S928USQS6DZF2 ANDROID_NDK_HOME="$ANDROID_NDK_HOME" stable
make TARGET=e3q-S928USQS6DZF2 ANDROID_NDK_HOME="$ANDROID_NDK_HOME" all
```

The produced files were then renamed for use as `cve43499-stable.so` and `cve43499-root`. Match them to the hashes above before claiming that they reproduce the proven exploit; merely compiling is not a substitute for a hardware test. The original Root My Galaxy app recognized its public DZF2 target for `SM-S928U1` but **did not automatically accept this AT&T `SM-S928U`**, even though the AT&T boot image matched the U1 target's boot image hash.

The exploit's successful trace included verified fake-fops/stack window transitions, kernel memory physical read/write tests, a privileged usermode-helper launch, `uid 2000 → 0`, and a stability-keeper stage that retained memory pages. The public payload's initial run did not achieve root on the tested AT&T variant; correcting those two gate checks and using one explicitly bounded attempt did.

### 9.2 Building the Samsung-compatible KernelSU module and embedded loader

**A plain KernelSU v3.2.5 build is not the tested solution.** The upstream/published Samsung E3Q late-load module initially coincided with a kernel panic at `try_module_get` and, on another run, a watchdog after a syscall live-patch trace. This led to a **Samsung-specific no-patch-text build**.

Source baseline:

```text
https://github.com/tiann/KernelSU
v3.2.5 commit b0bc817b4e966aa6aa830834eaf6ef765d821d40
```

Samsung compatibility patch from payload repository:

```text
Root-My-Galaxy-Payloads/kernelsu/patches/KernelSU-v3.2.5-samsung-kdp-rkp-defex.patch
```

The completed local checkout also had additional no-patch-text implementation changes in `kernel/Kbuild`, kernel hooking files, compatibility files and the Rust userspace loader. **The final modified sources and local diffs are provided in `Source/KernelSU-v3.2.5/` and `Source/Root-My-Galaxy-Payloads/`.** The KernelSU snapshot includes the Samsung compatibility files, hook changes, and `ksud` Rust modifications. Refer to `THIRD_PARTY_NOTICES.md` for provenance and limitations. A source snapshot does not guarantee a byte-identical rebuild without the original toolchain and dependencies.

Build flags required by the successful variant:

```text
CONFIG_KSU=m
CONFIG_KSU_SAMSUNG_KDP=y
CONFIG_KSU_SAMSUNG_RKP=y
CONFIG_KSU_SAMSUNG_DEFEX=y
CONFIG_KSU_SAMSUNG_NO_PATCH_TEXT=y
```

Android DDK container, used through Podman:

```text
ghcr.io/ylarod/ddk-min:android14-6.1-20260313
sha256:1dd6ac340b627a90a4031d6d0df6b129d8cc949b139fb56032c898f023d3d5d3
```

The DDK's generated kernel version strings were changed **inside the container** to:

```text
6.1.145-android14-11-33419968-abS928USQS6DZF2
```

The actual build command inside the mounted `/workspace/kernel` directory was:

```bash
CONFIG_KSU=m CONFIG_KSU_SAMSUNG_KDP=y CONFIG_KSU_SAMSUNG_RKP=y \
CONFIG_KSU_SAMSUNG_DEFEX=y CONFIG_KSU_SAMSUNG_NO_PATCH_TEXT=y \
CC=clang make -j4
```

Final `.ko` output in the operator's archived source checkout:

```text
KernelSU-v3.2.5/kernel/kernelsu.ko
SHA-256 003a4ee7506545a918cf11a8fd37d7eea2bc0a1d421ed8262092a0eb3ec1ff6e
vermagic 6.1.145-android14-11-33419968-abS928USQS6DZF2 SMP preempt mod_unload modversions aarch64
```

Inspection showed **no undefined `stop_machine` import**. The module used KernelSU's target-specific manual-relocation path and was **not** treated as a conventional generic `insmod` module. The stripped `.ko` was placed into the KernelSU source asset path:

```text
userspace/ksud/bin/aarch64/android14-6.1_kernelsu.ko
```

Then the custom Android ARM64 `ksud` was built with Rust/Cargo and Android NDK r29, API 35:

```bash
source "$HOME/.cargo/env"
export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/29.0.14206865"
# From a properly patched KernelSU checkout:
source .github/scripts/setup-rust-build.sh aarch64-linux-android 35
cargo clean -p ksud
cargo build --locked --release --target aarch64-linux-android -p ksud
```

The build also needed a project-specific Git redirect for an unavailable historical `Kernel-SU/adb_client` Rust dependency. The result was the ARM64 ELF `ksud-s25u-kdp-v32525` with the custom `.ko` **embedded**. The proprietary filename convention does not turn this file into an S25 driver.

**Important version trap that was discovered:** A one-commit **shallow** `KernelSU` Git clone gave driver version `30001`, while Manager was `32525`. KernelSU's version calculation uses `30000 + (git rev-list --count HEAD)`. The source history was completed using `git fetch --unshallow origin`, giving **2525 commits**, and the module and embedded loader were rebuilt. Only then did Manager report **32525/32525** without warnings.

A direct helper route used the outdated CLI option `--ephemeral`; the custom v3.2.5 loader accepted `late-load --allow-shell` instead. The `s928u-v32525-late-load-once.sh` script provided the verified invocation and a temporary bind mount to `/system/bin/logcat`. The bind mount was explicitly removed after root became available.

### 9.3 Why the three carrier examples are not an unconditional compatibility claim

The **carrier firmware pages verify matching AP and kernel-family targets**, but this particular community experiment verified the final custom loader **only on AT&T SM-S928U**. Verizon and T-Mobile may have different runtime security policies, signed partition combinations, CSC-specific behavior or other runtime differences. The public Root My Galaxy E3Q reference test itself was on `SM-S928U1`. Therefore, users of TMB/VZW DZF2 should verify exact runtime identity and document their own results rather than treating the AT&T success as a guarantee.

---

## Phase 10 — Common stop conditions and exact diagnostics

| Observation | Meaning / next check |
|---|---|
| Odin won't detect the phone / ID:COM empty | Driver, USB cable or incorrect Download Mode; fix connectivity first |
| Odin `SW REV CHECK FAIL` | Bootloader downgrade prohibited by revision check; cannot flash bit 6 over an already raised minimum bit 7+ |
| Build/kernel name differs from `S928USQS6DZF2` | The exploit target is not verified; do not run it |
| Root My Galaxy app says `No compatible payload supports this model and kernel version` | The public application model allowlist originally did not accept AT&T `SM-S928U`; use the precisely built standalone files, not an arbitrary app profile |
| Exploit ends without root / phone reboots | No verified bootstrap privilege; do not assume success or load KernelSU |
| KernelSU late-load stops displaying output after `LOAD KERNELSU` | Can happen **even on a successful load**. Check `/proc/modules` and `su -c id` from a second terminal first |
| KernelSU Manager says driver `30001` and manager `32525` | Original shallow-history build metadata; need rebuilt full-history module/loader `32525` |
| KernelSU module visible but Manager errors persist | Confirm correct actual manager+driver version and that the embedded driver was replaced, not merely the executable's filename |
| Android `logcat` behaves like `ksud` | Temporary bind mount remained; once `su` works, `umount /system/bin/logcat` and retest |
| Root disappears after reboot | Expected: late-load is volatile; use the Phase 8 reroot steps |

## Reference links / provenance

**Stock firmware / Windows:**

- AT&T SM-S928U exact DZF2: https://samfw.com/firmware/SM-S928U/ATT/S928USQS6DZF2
- T-Mobile SM-S928U exact DZF2: https://samfw.com/firmware/SM-S928U/TMB/S928USQS6DZF2
- Verizon SM-S928U exact DZF2: https://samfw.com/firmware/SM-S928U/VZW/S928USQS6DZF2
- Samsung USB driver: https://developer.samsung.com/android-usb-driver
- Samsung US device firmware history: https://doc.samsungmobile.com/SM-S928U/029130240223/wel.html

**Payload and KernelSU source:**

- Native exploit and Samsung patch: https://github.com/BuSung-dev/Root-My-Galaxy-Payloads
- Published U1 DZF2 porting notes: https://github.com/BuSung-dev/Root-My-Galaxy-Payloads/blob/main/docs/SM-S928U1-S928U1UES6DZF2.md
- KernelSU v3.2.5: https://github.com/tiann/KernelSU/tree/v3.2.5
- KernelSU Manager APK releases: https://github.com/tiann/KernelSU/releases/tag/v3.2.5
- Google Platform Tools: https://developer.android.com/tools/releases/platform-tools

### Evidence and honesty boundaries

The actual AT&T Odin downgrade and the Linux bootstrap/KernelSU run were completed on one `SM-S928U`; the operator confirmed `su`, `Enforcing`, restored `logcat`, and zero Manager warnings. The original pre-flash kernel was never captured, nor was the exact Odin version or CSC-vs-HOME_CSC choice. The `.ko` and final `ksud` were **not** stock upstream binaries and their custom full-source delta was not delivered with these notes. This guide distinguishes **observed steps** from **cross-carrier examples** and provides the exact artifact fingerprints to prevent accidental substitution.
