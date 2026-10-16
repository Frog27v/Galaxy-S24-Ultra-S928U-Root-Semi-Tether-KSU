# Source attribution and license notices

This repository combines independently licensed components. **No single blanket license is claimed for all files.** Each upstream component retains its own copyright and license terms. The files in `RootBoot/` are modified builds; they are **not** official releases from the upstream developers.

## Root My Galaxy / Root My Galaxy Payloads

- Authors/project: BuSung-dev and original contributors.
- Source: https://github.com/BuSung-dev/Root-My-Galaxy-Payloads
- Original application: https://github.com/BuSung-dev/Root-My-Galaxy
- License: Apache License 2.0, full text in `Licenses/Root-My-Galaxy-Payloads-Apache-2.0.txt` and `Source/Root-My-Galaxy-Payloads/LICENSE`.
- Pinned payloads source commit: `6e3223e689688540060ddd97a0927e927bfed207`.
- Local modification to source file `src/slide_app.c`: changed two atomic readiness checks to `slide_stack_write_window` from `slide_pselect_write_window`.
- See `Source/Root-My-Galaxy-Payloads/LOCAL_DIFF_FROM_PINNED_BASE.patch` and `SOURCE_PROVENANCE.txt`. The snapshot omits upstream compiled outputs for unrelated devices, not the relevant C source or build scripts. The full original upstream history and artifacts remain available at the upstream link.

## KernelSU v3.2.5

- Authors/project: tiann and KernelSU contributors.
- Source: https://github.com/tiann/KernelSU
- Pinned commit: `b0bc817b4e966aa6aa830834eaf6ef765d821d40`.
- Userspace components: GPL version 3 in `Licenses/KernelSU-Userspace-GPL-3.0.txt`, see `Source/KernelSU-v3.2.5/LICENSE` for original terms. Check individual source file notices for particular code.
- Kernel components: GPL version 2 in `Licenses/KernelSU-Kernel-GPL-2.0.txt` and `Source/KernelSU-v3.2.5/kernel/LICENSE`.
- The source snapshot includes extra Samsung KDP/DEFEX compatibility source files, syscall/trace changes, no-patch-text modifications, and edits to the Rust `ksud` installation/late-load routines. The `LOCAL_DIFF_FROM_PINNED_BASE.patch` covers *tracked* changes; the complete snapshot additionally includes previously untracked Samsung compatibility files. Do not treat the patch alone as the full modified source release.
- Related published Samsung patch in `Source/Root-My-Galaxy-Payloads/kernelsu/patches/KernelSU-v3.2.5-samsung-kdp-rkp-defex.patch`.

## BusyBox component embedded in `ksud`

The KernelSU v3.2.5 source checkout includes `userspace/ksud/bin/aarch64/busybox` with version string `BusyBox v1.36.1.1 topjohnwu`; the custom `ksud` embeds assets from that directory. BusyBox is GPL-2.0-only (full generic license text copied at `Licenses/BusyBox-GPL-2.0.txt`; this notice is not a substitute for corresponding source).

- BusyBox upstream source: https://git.busybox.net/busybox/ (release `1.36.1`).
- Android patches/build instructions: https://github.com/topjohnwu/ndk-box-kitchen (supports BusyBox 1.36.1).
- Versioned prebuilt artifact (for tracing origin): https://github.com/topjohnwu/magisk-files/releases/download/files/busybox-1.36.1.1.zip

**Source caveat:** The precise BusyBox build-input commit and local modifications behind the embedded binary have not been independently verified. For full GPL compliance, verify that the complete corresponding BusyBox source and relevant build scripts are available to recipients under the license, rather than assuming that a homepage link automatically fulfills source-distribution obligations. The same applies to other embedded binary dependencies.

## Reproducibility and distribution scope

The `Source/` directory contains the locally modified source checkout exports and relevant provenance records; `Build-Reference/` contains kernel module files from the archive. The Android DDK container, Android NDK, firmware/build environment and publicly sourced Rust dependencies are not mirrored here. Their versions and repository links are documented in `Documentation/`. The source was compared for completeness, **but no independent bit-for-bit rebuild of the distributed executables has been performed** in preparing this publication package.

Before redistribution, review the license notices for the embedded components, include any additional necessary corresponding sources, and do not claim that this package has received legal certification.
