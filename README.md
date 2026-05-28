# 🐧 Linux-TkG Kernel Builder for Debian Sid
# 🐧 适用于 Debian Sid 的 Linux-TkG 内核构建器

> **Automated, High-Performance Linux Kernel Builds optimized for x86-64-v3 & BORE Scheduler.**
> **自动化高性能 Linux 内核构建，针对 x86-64-v3 指令集与 BORE 调度器优化。**

[![Build Status](https://github.com/XiaoZuo1120/Action_Build_Linux-TkG_Debian_Mainline_X86-64-V3/actions/workflows/build-tkg-kernel.yml/badge.svg)](https://github.com/yourusername/action-build-linux-tkg-debian-mainline-x86-64-v3/actions)
[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

## ⚡ Features | 特性

*   **🔥 Latest Mainline**: Auto-tracks `torvalds/linux` GitHub tags (incl. RCs).
    **🔥 最新主线**：自动追踪 GitHub Torvalds 仓库标签（含 RC），规避 kernel.org Anubis 防护。
*   **⚡ Optimized Stack**:
    *   **Scheduler**: `BORE` (Auto-fallback to `EEVDF`).
        **调度器**：`BORE`（低延迟桌面/游戏），若补丁不可用则自动回退至 `EEVDF`。
    *   **Compiler**: `Clang/LLVM` + `Thin LTO`.
        **编译器**：`Clang/LLVM` + `Thin LTO`，平衡编译速度与运行时性能。
    *   **Arch**: `x86-64-v3`.
        **架构**：`x86-64-v3`，针对 Haswell/Zen 1 及以上 CPU 优化指令集。
    *   **Network**: `BBR` congestion control.
        **网络**：`BBR` 拥塞控制，优化高带宽高延迟网络表现。
*   **🛠️ TkG Patches**: Zen, Liquorix, Clear Linux tweaks included.
    **🛠️ TkG 补丁**：集成 Zen/Liquorix/Clear Linux 等社区性能优化补丁。
*   **🧩 Universal Compatibility**:
    *   **ACS Override**: Enabled for VFIO/IOMMU直通支持 (PVE/KVM friendly).
        **ACS 覆盖**：启用以支持 PCI 设备直通，兼容 PVE/KVM 虚拟化。
    *   **OpenRGB**: Kernel-level RGB control support.
        **OpenRGB**：内核级 RGB 灯光控制支持，兼容多种外设。
*   **📦 Debian Native**: Generates standard `.deb` packages.
    **📦 Debian 原生**：生成标准 `.deb` 包，便于 Debian/Ubuntu 系发行版安装。
*   **🤖 Automated**: Weekly builds, auto-config updates, timestamped releases.
    **🤖 自动化**：每周定时构建，自动更新版本配置，带时间戳发布。

## ⚙️ Key Config | 核心配置

| Param | Value | Note |
| :--- | :--- | :--- |
| `_cpusched` | `bore` | Low-latency desktop/gaming. Auto-fallback to EEVDF if patch missing. <br> 低延迟桌面/游戏。若补丁缺失自动回退至 EEVDF。 |
| `_compiler` | `llvm` | Faster build & better LTO integration. <br> 更快编译速度及更好的 LTO 集成。 |
| `_processor_opt` | `x86-64-v3` | Modern CPU instructions (AVX2, BMI2). Universal for Haswell/Zen+. <br> 现代 CPU 指令集。通用兼容 Haswell/Zen 1 及以上。 |
| `_tcp_cong_alg` | `bbr` | Better throughput for WiFi/high-latency networks. <br> 优化 WiFi 及高延迟网络的吞吐量。 |
| `_ftracedisable` | `false` | Enables Ftrace for SCX scheduler compatibility. <br> 启用 Ftrace 以兼容 SCX 等高级调度器。 |
| `_acs_override` | `true` | Allows PCI device isolation for VFIO/Virtualization. <br> 允许 PCI 设备隔离，支持 VFIO/虚拟化直通。 |
| `_openrgb` | `true` | Kernel-level support for RGB devices. <br> 内核级支持 RGB 设备控制。 |
| `_glitched_base` | `true` | Includes Zen/Liquorix/Clear Linux performance patches. <br> 包含 Zen/Liquorix/Clear Linux 性能补丁。 |
