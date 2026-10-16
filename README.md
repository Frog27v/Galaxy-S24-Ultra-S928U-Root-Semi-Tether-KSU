# AT&T Galaxy S24 Ultra SM-S928U — Temporary KernelSU Root (Android 16)

A device-tested research record and experimental reroot package for **Samsung Galaxy S24 Ultra SM-S928U (AT&T)** with a **locked bootloader**.

> **Experimental, exact-build-only.** Tested on one device. Exploit attempts and loading custom kernel code can crash, reboot, or destabilize a phone. Keep backups, verify every prerequisite, and use only on a device you own or are authorized to test. **This does not unlock the bootloader or provide persistent root.**

## Verified configuration

| Item | Tested value |
| --- | --- |
| Device | Samsung Galaxy S24 Ultra **SM-S928U** (AT&T, not S928U1) |
| Android | **16** |
| Firmware | **S928USQS6DZF2** |
| Kernel | **6.1.145-android14-11-33419968-abS928USQS6DZF2** |
| Bootloader | **Locked** |
| Root result | Temporary / lost on reboot |
| KernelSU | Manager and driver **32525** |
| SELinux | **Enforcing** |

The successful experiment used a modified CVE-2026-43499 bootstrap and Samsung-specific KernelSU 3.2.5 late-load binary.

## Start here: full rooting guide

**[Complete Step-by-Step Rooting Guide](Documentation/SM-S928U_ATT_TMB_VZW_Complete_Rooting_Guide.md)** — the user-facing walkthrough for firmware checks, the tested manual rooting sequence, KernelSU verification, and rerooting after reboot.

The **AT&T SM-S928U on the exact DZF2 build** is the only confirmed hardware success. T-Mobile and Verizon firmware information is included for research and comparison; those variants have **not** been independently rooted and verified by this project.

For the investigation and artifact provenance, see the [Full Technical Record](Documentation/SM-S928U_ATT_Android16_KernelSU_Root_Full_Technical_Record.md) or the [AI Reference](Documentation/SM-S928U_ATT_Root_Experiment_AI_Reference.json).

## Repository layout

- `Documentation/SM-S928U_ATT_TMB_VZW_Complete_Rooting_Guide.md` — step-by-step rooting guide for readers.
- `Documentation/SM-S928U_ATT_Android16_KernelSU_Root_Full_Technical_Record.md` — detailed experimental record.
- `Documentation/SM-S928U_ATT_Root_Experiment_AI_Reference.json` — concise machine-readable reference.
- `RootBoot/` — reroot scripts, platform-specific ADB command notes, and the tested compiled components.
- `Source/` — locally modified KernelSU v3.2.5 and Root My Galaxy Payloads source snapshots, patches, and provenance.
- `Build-Reference/` — original debug and embedded kernel-module build-reference files.
- `Licenses/` and `THIRD_PARTY_NOTICES.md` — upstream license texts, credits, source locations, and limitations.

**Folder naming:** The repository directory is `RootBoot/`. On the phone, `rootboot.sh` expects its files in `/sdcard/RootBoot/` (the same location as `/storage/emulated/0/RootBoot/`).

## Before trying the reroot package

1. Confirm the Android build, model, and running kernel exactly match the tested values:

   ```bash
   adb devices
   adb shell 'getprop ro.product.model; getprop ro.build.version.incremental; uname -r'
   ```

2. Follow the [step-by-step rooting guide](Documentation/SM-S928U_ATT_TMB_VZW_Complete_Rooting_Guide.md) for the **tested manual sequence**. The documented individual bootstrap/late-load operations were tested; the combined `rootboot.sh` orchestration **has not been independently confirmed end-to-end** in the preserved evidence.
3. If you choose to try the experimental automated helper, copy **the contents of** `RootBoot/` to the expected directory on the phone:

   ```bash
   adb shell mkdir -p /sdcard/RootBoot
   adb push RootBoot/. /sdcard/RootBoot/
   ```

4. Only on that exact model/firmware/kernel, and with authorized ADB debugging, the helper's entry point is:

   ```bash
   adb shell sh /sdcard/RootBoot/rootboot.sh
   ```

The helper checks model, Android release, kernel, firmware, and known component SHA-256 hashes, makes only one bootstrap exploit attempt, and tries to verify KernelSU and SELinux afterward. **Passing these checks cannot guarantee safety or successful rooting.** Do not repeatedly rerun a failed exploit without inspecting its logs and the phone's condition.

## Checksums

The canonical checksums for the tested compiled components and loader script are in [the technical record](Documentation/SM-S928U_ATT_Android16_KernelSU_Root_Full_Technical_Record.md#6-exact-final-artifacts-and-hashes) and [JSON reference](Documentation/SM-S928U_ATT_Root_Experiment_AI_Reference.json). Verify downloaded binaries before running them.

## Source, credits, and licensing

This experiment builds on:

- [Root My Galaxy](https://github.com/BuSung-dev/Root-My-Galaxy) and [Root My Galaxy Payloads](https://github.com/BuSung-dev/Root-My-Galaxy-Payloads), including CVE-2026-43499 target and Samsung-specific patching work.
- [KernelSU](https://github.com/tiann/KernelSU) v3.2.5.

**Source included:** The patched exploit and KernelSU/`ksud` binaries are not stock upstream releases. The repository includes modified source snapshots with local diffs and provenance under `Source/`, and upstream license copies under `Licenses/`. See [Third-Party Notices](THIRD_PARTY_NOTICES.md) for the original authors, changes, separate licensing requirements and the still-unverified BusyBox corresponding-source detail. The exact modified checkout is now supplied, but a bit-for-bit independent rebuild has not been demonstrated. Do not treat the sources and attribution links as automatic legal certification.

## Scope of the evidence

The observed successful result was on **one AT&T SM-S928U using the exact DZF2 firmware/kernel**. It does **not** establish support for different S928U versions, S928U1, a different carrier firmware, later security patches, or other Samsung devices. Root was temporary and disappeared after reboot.

Contributions, additional reproducibility data, and independent confirmations are welcome. Please include the exact model, firmware, running kernel, and outcome.
