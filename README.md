# 🐧 Linux-TkG Kernel Builder for Debian Sid
# 🐧 适用于 Debian Sid 的 Linux-TkG 内核构建器

> **Automated, High-Performance Linux Kernel Builds optimized for x86-64-v3 & BORE Scheduler.**
> **自动化高性能 Linux 内核构建，针对 x86-64-v3 指令集与 BORE 调度器优化。**

[![Build Status](https://github.com/XiaoZuo1120/Action_Build_Linux-TkG_Debian_Mainline_X86-64-V3/actions/workflows/build-tkg-kernel.yml/badge.svg)](https://github.com/yourusername/action-build-linux-tkg-debian-mainline-x86-64-v3/actions)
[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

## ⚡ Features | 特性

*   **🔥 Latest Mainline**: Auto-tracks `kernel.org` tags (incl. RCs).
    **🔥 最新主线**：自动追踪 `kernel.org` 标签（含 RC）。
*   **⚡ Optimized Stack**:
    *   **Scheduler**: `BORE` (Low-latency desktop/gaming).
        **调度器**：`BORE`（低延迟桌面/游戏）。
    *   **Compiler**: `Clang/LLVM` + `Thin LTO`.
        **编译器**：`Clang/LLVM` + `Thin LTO`。
    *   **Arch**: `x86-64-v3` .
        **架构**：`x86-64-v3` 。
    *   **Network**: `BBR` congestion control.
        **网络**：`BBR` 拥塞控制。
*   **🛠️ TkG Patches**: Zen, Liquorix, Clear Linux tweaks included.
    **🛠️ TkG 补丁**：包含 Zen/Liquorix/Clear Linux 优化。
*   **📦 Debian Native**: Generates standard `.deb` packages.
    **📦 Debian 原生**：生成标准 `.deb` 包。
*   **🤖 Automated**: Weekly builds, auto-config updates, timestamped releases.
    **🤖 自动化**：每周构建，自动更新配置，时间戳发布。

## ⚙️ Key Config | 核心配置

| Param | Value | Note |
| :--- | :--- | :--- |
| `_cpusched` | `bore` | Desktop responsiveness. <br> 桌面响应性。 |
| `_compiler` | `llvm` | Faster build & LTO support. <br> 更快编译及 LTO 支持。 |
| `_processor_opt` | `x86-64-v3` | Modern CPU instructions. <br> 现代 CPU 指令集。 |
| `_tcp_cong_alg` | `bbr` | Better WiFi/high-latency perf. <br> 更好的 WiFi/高延迟性能。 |
| `_ftracedisable` | `false` | SCX scheduler compatibility. <br> SCX 调度器兼容性。 |
| `_numadisable` | `false` | NVIDIA/CUDA compatibility. <br> NVIDIA/CUDA 兼容性。 |
