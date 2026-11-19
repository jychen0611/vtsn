# vTSN — Virtual Time-Sensitive Networking Device
> A hardware-independent Linux networking project for exploring virtual Ethernet drivers, MAC Merge management, and Time-Sensitive Networking (TSN).

**Status:** Planned / early development  
**Primary language:** C (Linux kernel), with Python for optional user-space simulation  
**License:** To be determined

## Overview

vTSN is an educational, open-source-oriented project that develops a **virtual Ethernet network device** for Linux and incrementally explores the control and behavior of Time-Sensitive Networking features.

The project starts with the Linux networking subsystem—`net_device`, packet ownership, driver lifecycle, and `ethtool` integration—and then adds a software model of **MAC Merge / frame preemption** and, eventually, its interaction with **time-aware scheduling**.

**No specialized TSN NIC or switch is required for the initial milestones.** Kernel-facing functionality is exercised inside a disposable QEMU guest. Protocol behavior that requires physical MAC hardware is represented by an explicitly labeled simulation rather than claimed as wire-level compliance.

## Project Goals

### 1. Build practical Linux kernel engineering skills

- Implement and maintain a loadable virtual Ethernet driver.
- Understand `net_device`, `net_device_ops`, `sk_buff` ownership, TX/RX paths, and device lifecycle.
- Explore the Linux `ethtool` netlink interface and version-specific driver callbacks.
- Practice resource management, locking, timers, workqueues, error handling, and kernel API compatibility.
- Learn systematic kernel debugging with QEMU, GDB, logs, and kernel sanitizers.

### 2. Understand TSN through implementation

- Study **IEEE 802.3br** MAC Merge management and verification concepts.
- Explore **IEEE 802.1Qbu** express versus preemptible traffic classification.
- Model MAC Merge configuration, partner capabilities, verification state transitions, and operational status.
- Simulate express/preemptible traffic scheduling and fragment-boundary decisions.
- Explore **IEEE 802.1Qbv** time-aware gate schedules and their interaction with hold/release behavior.

### 3. Develop without dedicated TSN hardware

- Run the experimental kernel in QEMU rather than on the development host.
- Expose virtual state through Linux interfaces where supported by the selected kernel version.
- Use deterministic user-space simulations for timing and protocol scenarios that cannot be meaningfully verified through a virtual NIC alone.
- Separate **API behavior**, **model correctness**, and **physical hardware conformance** in documentation and tests.

### 4. Establish a reviewable engineering workflow

- Make small, testable changes with clear acceptance criteria.
- Use AI-assisted code review as a supplement—not a replacement—for compiler checks, static analysis, KUnit, and runtime testing.
- Maintain reproducible test cases and document design decisions.
- Build a public portfolio demonstrating independent Linux networking development skills.

## Architecture

```text
                        User Space
     +-------------------------------------------+
     | ip / ethtool / tc / test tools             |
     +--------------------+----------------------+
                          |
                Linux networking APIs
                          |
     +--------------------v----------------------+
     |              Linux Kernel                 |
     |                                           |
     |  net_device / net_device_ops               |
     |  ethtool_ops (where supported)             |
     |                  |                        |
     |          +-------v--------+               |
     |          | vTSN virtual   |               |
     |          | Ethernet driver|               |
     |          +-------+--------+               |
     |                  |                        |
     |        MAC Merge control state            |
     |        Verification model                 |
     +------------------+------------------------+
                        |
                Model/test boundary
                        |
     +------------------v------------------------+
     |         User-space TSN simulator          |
     |  Traffic arrival / frame boundaries       |
     |  Express vs. preemptible scheduling       |
     |  Qbv gate events / hold-release timeline  |
     +-------------------------------------------+
```

The user-space simulator is a separate model. It does **not** imply that Linux packet transmission through the virtual interface performs IEEE 802.3br-compliant fragmentation on the wire.

## Scope and Non-Goals

**In scope:**

- A virtual Linux Ethernet device and safe driver lifecycle.
- Linux MAC Merge configuration and status integration, subject to actual kernel API support.
- Simulated verification, partner behavior, and link transitions.
- Reproducible, deterministic scheduling and frame-preemption models.
- Kernel tests, simulation tests, documentation, and automated review.

**Not initial goals:**

- A production-ready Ethernet NIC or switch driver.
- Physical SMD-V/SMD-R transmission, real mPacket encoding, or wire-level interoperability.
- Certified IEEE 802.1Qbu / 802.3br / 802.1Qbv compliance.
- Guaranteed nanosecond-accurate timing from a general-purpose VM.
- Direct use of proprietary vendor register maps, SDKs, or confidential specifications.

## Development Roadmap

| Phase | Focus | Deliverable | Acceptance Criteria |
|---|---|---|---|
| 0 | Safe kernel lab | Linux kernel running in QEMU | Boot, capture logs, attach GDB, recover from guest failure |
| 1 | Virtual Ethernet driver | `vtsn.ko`, `vtsn0` | Load/unload, UP/DOWN, safe SKB disposal, no kernel warnings |
| 2 | MAC Merge control plane | `ethtool` MAC Merge callbacks and virtual state | Read/update supported settings; validate invalid inputs |
| 3 | Verification model | Deterministic verification state machine | Tests for success, timeout, disable, restart, and link loss |
| 4 | Frame-preemption model | User-space traffic/fragment scheduler | Reproducible express/preemptible scenarios and timelines |
| 5 | Qbv × Qbu model | Gate schedule and hold/release integration | Test gate transitions, scheduling constraints, and edge cases |

### Phase 0 — Kernel development environment

Create a reproducible build and debug workflow using a **pinned Linux kernel version** and QEMU. Enable useful debugging options such as lockdep and KASAN where practical. KCSAN can be used in a separate test configuration.

**Exit criteria:** a kernel change can be built, booted, observed, and debugged without rebooting the host.

### Phase 1 — Virtual Ethernet device

Register a `net_device` with basic `net_device_ops`, including open, stop, and transmit callbacks. Start with a TX-only drop path; do not claim ping works until a real RX/peer path exists. Document `sk_buff` ownership and ensure clean unload.

**Exit criteria:** the virtual interface appears in `ip link`, transitions UP/DOWN, handles TX packets safely, and unloads without leaks or warnings.

### Phase 2 — MAC Merge management

Study the selected kernel version's `net/ethtool/mm.c` and related `ethtool_ops` definitions. Implement compatible callbacks for supported MAC Merge configuration and status. Treat administrative TX enablement, verification status, and operational TX activity as distinct concepts.

**Exit criteria:** `ethtool --show-mm` and supported `--set-mm` operations exercise virtual state with consistent validation and status reporting.

### Phase 3 — Verification state machine

Create a testable state model for verification enable/disable, requests/responses, partner capability, timeout, restart, and link-down behavior. Keep the simplified model distinguishable from the complete normative state machines.

**Exit criteria:** automated tests cover normal transitions and failure/recovery paths.

### Phase 4 — Frame-preemption simulator

Implement a deterministic user-space model of frame arrivals, transmission time, express traffic interruption, fragment-size constraints, and release behavior. Use explicit assumptions for line rate, overhead, and time units.

**Exit criteria:** known traffic scenarios produce reproducible event timelines and assertions.

### Phase 5 — Qbv and Qbu integration

Model gate control list entries, gate states, Set-And-Hold-MAC / Set-And-Release-MAC behavior, and the interaction between scheduled express windows and preemptible traffic. Keep timing claims scoped to the simulation.

**Exit criteria:** tests explain expected and observed scheduling behavior, including boundary and invalid-configuration cases.

## Proposed Repository Layout

```text
vtsn/
├── README.md
├── LICENSE                    # once selected
├── docs/
│   ├── architecture.md
│   ├── kernel-api.md
│   ├── mac-merge.md
│   ├── verification.md
│   └── qbv-qbu-integration.md
├── kernel/
│   ├── vtsn_main.c
│   ├── vtsn_netdev.c
│   ├── vtsn_ethtool.c
│   ├── vtsn_mm.c
│   ├── vtsn_mm.h
│   └── Makefile
├── simulator/
│   ├── scheduler.py
│   ├── preemption.py
│   └── timeline.py
├── tests/
│   ├── kunit/
│   ├── test_netdev.sh
│   └── test_mm.sh
└── scripts/
    ├── build.sh
    ├── run_qemu.sh
    └── debug.sh
```

*This is the target layout; components will be added incrementally.*

## Development and Testing Strategy

```text
Design a small change
        |
        v
Implement + self-review
        |
        v
AI-assisted review (API, ownership, locking, cleanup)
        |
        v
Build / compiler warnings / static analysis
        |
        v
KUnit + user-space unit tests
        |
        v
QEMU runtime tests + KASAN / lockdep / KCSAN as applicable
        |
        v
Inspect logs, fix issues, document results
```

Review areas include NULL dereferences, use-after-free, double-free, `sk_buff` ownership, sleep-in-atomic-context, race conditions, lock ordering, timer cancellation, and init/error/unload cleanup. AI review is advisory; test results and kernel behavior are authoritative.

## Getting Started

**Prerequisites (planned):** a Linux development host, C toolchain, kernel build dependencies, QEMU, GDB, `iproute2`, and `ethtool`.

1. Select and pin a Linux kernel release; verify its MAC Merge API and the installed `ethtool` version.
2. Build and boot that kernel inside QEMU.
3. Confirm serial console logs and GDB connectivity.
4. Implement the minimal `vtsn0` interface.
5. Add tests before expanding the MAC Merge model.

> Build and run scripts are planned and are not yet provided. Commands and kernel callback signatures will be documented against the pinned version when Phase 0 is complete.

## Success Criteria

The project is successful when it demonstrates:

- A working, debuggable Linux virtual Ethernet driver with correct resource ownership.
- A clear understanding of the kernel-to-driver MAC Merge management path.
- Automated tests for state transitions and negative cases.
- A deterministic, documented TSN simulation that separates assumptions from measured behavior.
- A reproducible development workflow that supports continued learning and independent debugging.

**The primary outcome is engineering capability—not simply a large codebase.** vTSN is intended to deepen Linux kernel understanding, strengthen hands-on networking development skills, and create transferable expertise beyond any one hardware platform.

## References

- [Linux kernel networking documentation](https://docs.kernel.org/networking/)
- [Linux ethtool netlink documentation](https://docs.kernel.org/networking/ethtool-netlink.html)
- [Linux MAC Merge implementation (`net/ethtool/mm.c`)](https://github.com/torvalds/linux/blob/master/net/ethtool/mm.c)
- [Linux TAPRIO manual](https://man7.org/linux/man-pages/man8/tc-taprio.8.html)
- IEEE 802.1Q (including time-aware scheduling and frame preemption provisions)
- IEEE 802.3br (Interspersing Express Traffic)

## Project Independence

This project is intended for independent learning and public collaboration. All implementation, tests, and documentation should use public specifications, public Linux APIs, and original code. No employer-confidential register definitions, proprietary SDK code, or internal design documents should be included.
