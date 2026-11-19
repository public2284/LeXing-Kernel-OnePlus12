# SUKISU_ULTRA_RESEARCH — SukiSU Ultra 官方资料与集成要求

Phase 0 只读调查产出。**关键发现：项目已经更名**——`SukiSU-Ultra/SukiSU-Ultra` 仓库 URL 现重定向到 **`SukiSU-Nova/SukiSU-Nova`**（7,246★，默认分支 main，描述 “Kernel-based Android Root Solution & KPM”，从 tiann/KernelSU 演化而来）。以下内容按官方 sukisu.org 集成指南整理。CONFIRMED（API 重定向 + 官网指南）。

## 最新版本

- Release **v3.0.0**（2026-11-15），管理器 APK v3.0.0_35000，ksud 全架构、ksuinit。
- **预编译 LKM 列表包含 `lkm-aarch64-android14-6.1_kernelsu.ko`**——与本设备内核族完全对应。CONFIRMED。

## 两种集成分支（按官方指南）

| 分支 | 机制 | 要求 | 对本设备 |
|---|---|---|---|
| `main` | kprobes/kretprobes + sys_enter 追踪点，运行时 hook，不改内核源码 | `CONFIG_KPROBES=y`（依赖）、`CONFIG_EXT4_FS=y`；可三态：`y` 内置 / `m` LKM | **全部满足**（stock config 中 KPROBES=y、KRETPROBES=y、EXT4_FS=y、HAVE_SYSCALL_TRACEPOINTS=y）CONFIRMED |
| `builtin` | 手动 hook，内核源码显式调用其入口 | 需改内核源码 | OPLUS 源码可用作为 fallback 路线 |

- 官方集成命令（示例）：`curl -LSs https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh | bash -s main`——脚本将仓库克隆并链接进 `drivers/kernelsu`，修改 drivers/Makefile 与 Kconfig。**本项目不会照原样执行 curl|bash**：Phase 2 将以 submodule 固定 commit 的方式安装同一脚本，并记录在 PATCHES.manifest（规则 13.4）。CONFIRMED（机制）+ LIKELY（适配）。

## KPM 支持

- 基于 KernelPatch（github.com/bmax121/KernelPatch），补丁仓库 `SukiSU-Nova/SukiSU_KernelPatch_patch`。需要 `CONFIG_KPM=y`；官方提示其会选中 `CONFIG_KALLSYMS`/`KALLSYMS_ALL`（本设备 stock 已开），“可能影响系统稳定性”。LIKELY（官方提示）。
- GKI 设备 KPM 通常可用；但当前设备未启用 KPM（stock config 无 CONFIG_KPM），Phase 1 需评估风险等级。

## 与管理器/现有环境的兼容性

- 现设备 ksud 为 4.1.3（KernelSU 体系），管理器为 KernelSU 4.x；迁移到 SukiSU Nova 需同时更换管理器 APK。切换是“镜像+管理器”配套动作，不存在仅换内核的可能。CONFIRMED（机制）。
- SukiSU Nova 的“内核扩展中心”包含 CPU/vvar 伪造、AVB 日志伪造、版本伪造、SUSFS 与挂载视图隐藏，与现有模块（PIF、SensorDecoy 等）可能功能重叠 → Phase 1 需逐项去重，避免双重伪造冲突。LIKELY。

## 其他官方资源

- 官网 sukisu.org（指南、App Profile 文档）；Weblate 项目名仍为 sukisu-ultra（历史名）；Telegram 频道 @Sukiksu。CONFIRMED。

## 适配 Android 16 的风险点（Phase 1 评估输入）

- 管理器需兼容 Android 16（SELinux enforcing 下 su 授权路径）。SukiSU Nova 版本迭代快（v3.0.0 于 2026-11 发布），发布说明需在 Phase 1 复核。LIKELY。
- 与现有 Zygisk Next/LSPosed 生态的交互保持不变（zygisksu 模块仍在 /data/adb/modules）。CONFIRMED（现状）。
