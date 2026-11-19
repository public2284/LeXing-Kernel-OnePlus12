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

## 与现有 Root 环境的关系（Phase 1 输入，本阶段不做架构决策）

现状：设备内核内置 KernelSU 4.1.3 + SUSFS，Zygisk Next / LSPosed / PIF 等模块生态正常运行。因此 SukiSU-Nova **不是普通功能补丁**，集成即 root 实现的替换。需要明确：

1. **与现有 KernelSU 的关系**：SukiSU-Nova 是从 tiann/KernelSU 独立演化的分支，替换是整体替换，不存在与现有内置 KSU 并存运行的方式。
2. **LKM 与内置集成路线差异**：LKM 路线以预编译/自编译 `kernelsu.ko` 模块加载，不动内核主体，失败时可回退内核镜像而不动 root 交付物；内置路线把驱动编入 Image，性能与稳定性更可控但失败需整镜像回退。本设备 stock 配置（KPROBES/TRACEPOINTS/EXT4）满足 LKM 前提。
3. **是否需要移除/替换现有 Root 实现**：取决于管线。LKM 路线下 KSU 内核态与 SukiSU 内核态不能并存；内置路线下同样。必须设计明确的切换与回退步骤，不能出现两个 root 框架同时管理 su/模块的叠加态。
4. **是否改变 SUSFS 集成方式**：SukiSU-Nova 自带 `kernel/extension/susfs_extension.c`；如采用 SukiSU 内置路线，SUSFS 随之进树，独立 SUSFS 补丁需求需重新评估，避免重复集成。
5. **Zygisk Next / LSPosed 等现有模块兼容性**：这些模块面向 KSU 体系接口，SukiSU 作为 KSU 演化分支理论上兼容，但管理器更换后模块管理路径变化，需在 Phase 1 以实际加载验证，不默认沿用。

**Phase 1 倾向（非决策）**：优先研究 LKM 路线，本阶段不动现有内置 root 环境。最终架构决策由 Phase 1 兼容性研究支持。本报告仅完成资料收集，不含任何集成动作。

## 适配 Android 16 的风险点（Phase 1 评估输入）

- 管理器需兼容 Android 16（SELinux enforcing 下 su 授权路径）。SukiSU Nova 版本迭代快（v3.0.0 于 2026-11 发布），发布说明需在 Phase 1 复核。LIKELY。
- 与现有 Zygisk Next/LSPosed 生态的交互保持不变（zygisksu 模块仍在 /data/adb/modules）。CONFIRMED（现状）。
