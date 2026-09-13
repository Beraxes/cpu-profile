# cpu-profile & game-pin

Dynamic, zero-reboot Linux CPU core hotplugging, governor manager, and automated game process pinner.

Built for modern AMD (Ryzen / Threadripper / EPYC) and Intel (Core / Xeon) platforms, with primary reference tuning and validation on the **Intel Xeon E5-2696 v3** (18C/36T Haswell-EP with Turbo Boost Unlock) on X99. It enables dynamic workload switching between high-frequency gaming, heavy multi-threading, and ultra-low power idle without touching BIOS settings.

---

## Features

### 1. On-the-Fly Core Hotplugging (Zero Reboot Required)
* **Hardware Agnostic:** Automatically discovers total physical cores and thread topology on any CPU architecture.
* **True 0W Sleep State:** Offlines physical cores directly via Linux kernel CPU hotplugging (`/sys/devices/system/cpu/cpu*/online`). Offlined cores enter permanent **C6 Deep Sleep** with core clocks gated (0 MHz) and voltage planes cut (0V).
* **Maximize Turbo Headroom:** Offlining unused cores leaves the full TDP limit available to active cores, sustaining full all-core Turbo Boost / Precision Boost without power-throttling.
* **Instant SMT / Hyperthreading Toggle:** Enable or disable SMT/HT on the fly with a single command.

### 2. Tailored Governor & Frequency Profiles
* **`max`:** All online cores locked to `performance` governor at maximum Turbo clock (zero ramp latency).
* **`fast`:** All online cores on `schedutil` with full Turbo / Boost enabled (supports Intel Turbo Boost and AMD Core Performance Boost / CPB).
* **`base [GHz]` (or `noboost`):** All online cores on `schedutil` clamped strictly to base frequency (auto-detected, or customizable e.g. `cpu-profile base 2.5`, 0% Turbo). Ideal for cool, quiet multi-threaded crunching.
* **`eco`:** All online cores locked to `powersave` at hardware minimum frequency (~24W package idle floor).
* **`split [N] [max|fast]`:** Automated asymmetric cluster. Keeps primary cores at max turbo (using either `performance` governor for locked clock or `schedutil` for dynamic scaling) while locking secondary cores at powersave for background tasks or AFK games.

### 3. Automated Multi-Thread Game Pinning (`game-pin`)
* **Auto-Detection:** Automatically discovers running game processes, Steam Proton containers (`pressure-vessel`, `srt-bwrap`), Wine executables (`*.exe`), and `wineserver`.
* **Complete Process-Tree Pinning:** Moves **all threads** (60+ engine, render, audio, and DXVK threads) together using `taskset -a`.
* **Zero Sudo Required:** Runs instantaneously without root permissions or password prompts.
* **Topology-Aware:** Dynamically reads active kernel topology. Never attempts to pin to offlined cores.

---

## Installation

```bash
git clone https://github.com/Beraxes/cpu-profile.git
cd cpu-profile
./install.sh
```

The installer places `cpu-profile` and the `game-pin` symlink into `~/.local/bin/`.

Ensure `~/.local/bin` is in your `$PATH` (typically in `~/.bashrc` or `~/.zshrc`):
```bash
export PATH="${HOME}/.local/bin:${PATH}"
```

---

## Quick Usage Guide

### Core & Hardware Control

```bash
# Set active physical cores to 10 (power-gates remaining cores to 0W)
cpu-profile cores 10

# Set active physical cores to 12
cpu-profile cores 12

# Bring all physical cores back online
cpu-profile cores all

# Toggle Hyperthreading / SMT on the fly
cpu-profile ht off
cpu-profile ht on
```

### Governor & Clock Profiles

```bash
# Maximum Performance mode (All cores locked to Performance governor @ max Turbo)
cpu-profile max

# Full Performance mode (Schedutil with Turbo / Boost)
cpu-profile fast

# Base / No-Boost mode (Schedutil capped @ detected base clock, 0% Turbo)
cpu-profile base

# Base mode with custom clock cap (e.g. 2.5 GHz)
cpu-profile base 2.5

# Full Eco mode (All cores locked @ hardware minimum clock, lowest power)
cpu-profile eco

# Split mode (50% fast cores @ 3.8 GHz, 50% eco cores @ 1.2 GHz)
cpu-profile split

# Custom split (e.g., 8 fast cores, remainder eco)
cpu-profile split 8

# Split mode with locked Performance governor on primary 4 cores
cpu-profile split 4 max

# View live governor, frequency cap, and core status
cpu-profile status
```

### Game Pinning (`game-pin`)

Whenever your game is open:

```bash
# Pin all game & wineserver threads to Fast cores (0-8)
game-pin fast

# Pin all game & wineserver threads to Eco cores (9-17) for low-power AFK
game-pin eco

# Unpin game across all active online cores
game-pin all

# Target a specific game by name or PID
game-pin fast warframe
game-pin eco 39167
```

---

## Status Output Example

Running `cpu-profile status` displays live information about all core slices:

```text
Current CPU Status: 20 Threads Online (Out of 36) | HT/SMT: on
CPU 0  (Core 0 )  schedutil   (Max: 3.8 GHz)  3800 MHz
CPU 1  (Core 1 )  schedutil   (Max: 3.8 GHz)  3800 MHz
CPU 2  (Core 2 )  schedutil   (Max: 3.8 GHz)  2300 MHz
...
CPU 9  (Core 16)  schedutil   (Max: 3.8 GHz)  2300 MHz
CPU 10 (Core --)  [OFFLINE]   (Power-Gated)    0 MHz (0W Sleep)
CPU 11 (Core --)  [OFFLINE]   (Power-Gated)    0 MHz (0W Sleep)
```

---

## How It Works

* **CPU Hotplugging:** Uses `/sys/devices/system/cpu/cpu*/online` to safely detach cores from the scheduler runqueue and transition them into hardware C6 sleep.
* **Frequency Caps & Turbo Control:** Modifies `/sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq` and toggles hardware boost via `intel_pstate/no_turbo` (Intel) or `cpufreq/boost` (AMD).
* **Affinity Masking:** Employs `sched_setaffinity(2)` via `taskset -a` across the complete task list of detected process trees (`/proc/$PID/task/*`).
* **Sibling Pairing:** Reads `/sys/devices/system/cpu/cpu*/topology/thread_siblings_list` to ensure logical hyperthreads stay grouped with their parent physical cores.

---

## Hardware Compatibility & Reference Testbed

### Universal Compatibility
`cpu-profile` and `game-pin` work on any modern Linux kernel (5.x / 6.x+) and x86_64 architecture:
* **Intel**: Core (i3/i5/i7/i9) and Xeon (E5 v3/v4, Scalable) utilizing `intel_pstate` or `acpi-cpufreq`.
* **AMD**: Ryzen, Threadripper, and EPYC utilizing `amd-pstate` or `acpi-cpufreq` (with `cpufreq/boost` control).
* **Linux Kernel Standard**: CPU hotplugging (`/sys/devices/system/cpu/cpu*/online`), SMT control (`/sys/devices/system/cpu/smt/control`), and affinity management via `taskset -a` are kernel-level POSIX/sysfs standards.

### Reference Hardware: Intel Xeon E5-2696 v3
While universally compatible, this tool was designed, optimized, and daily-driven on the **Intel Xeon E5-2696 v3** (18 Cores / 36 Threads, Haswell-EP, 145W TDP) on an X99 motherboard with Turbo Boost Unlock (Hack TBU):
* **Base Clock**: 2.30 GHz (auto-detected, used in `cpu-profile base`)
* **Unlocked All-Core Turbo**: 3.80 GHz
* **Why Core Hotplugging Matters Here**:
  * Under a full 18-core AVX/gaming load, the package power hits the 145W PL1 limit, causing clocks to throttle down to ~2.8–3.1 GHz.
  * Running `cpu-profile cores 10` or `12` gates the unused cores into 0W C6 deep sleep, freeing up the entire 145W power envelope for the active cores.
  * Result: **Locked 3.80 GHz all-core clock in gaming** without power-limit throttling or excessive heat.
  * When multi-threaded rendering or compilation is required, `cpu-profile cores all` instantly brings back all 18 cores (36 threads) without restarting the PC.

---

## Known Conflicts & Compatibility Notes

> [!WARNING]
> **CoreCtrl CPU Control Conflict:**  
> If you have [CoreCtrl](https://gitlab.com/corectrl/corectrl) running with **CPU control enabled** in its profile, it will continuously re-apply its own governor and frequency limits, immediately overriding changes made by `cpu-profile`.  
> **Fix:** In CoreCtrl, open your active profile(s) and **disable CPU control** (use CoreCtrl for GPU only). This lets `cpu-profile` manage your CPU without background conflicts.

---

## Uninstallation

From the command line:
```bash
cpu-profile uninstall
```

Or from the cloned repository:
```bash
./install.sh uninstall
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
