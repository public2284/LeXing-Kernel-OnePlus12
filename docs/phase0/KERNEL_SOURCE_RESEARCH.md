# KERNEL_SOURCE_RESEARCH — 内核源码候选与来源记录

Phase 0 只读调查产出。仅记录来源与候选版本，不克隆、不合并（项目规则 13.4 / 第四章）。

## 源码版图

设备内核为 `6.1.145-android14-11-o-g02eb3eaaeb40-lotus`，谱系为 ACK `android14-6.1` 的 OPLUS 交付（SM8650）。对应官方开源源码在 GitHub 组织 `OnePlusOSS`，三仓配套：

| 仓库名 | 作用 | 状态 |
|---|---|---|
| OnePlusOSS/android_kernel_common_oneplus_sm8650 | GKI/ACK 基础（common） | CONFIRMED（存在） |
| OnePlusOSS/android_kernel_oneplus_sm8650 | SM8650 SoC/板级内核 | CONFIRMED（存在） |
| OnePlusOSS/android_kernel_modules_and_devicetree_oneplus_sm8650 | 厂商模块与设备树 | CONFIRMED（存在） |

## 匹配分支

三仓均存在 `oneplus/sm8650_b_16.0.0_oneplus12`（对应 ColorOS 16 / Android 16 一加 12），以及 `v_15.0.0_oneplus12`、`u_14.0.0_oneplus12`。设备版为 Android 16，故候选源码分支为 `…_b_16.0.0_oneplus12`（三仓同名分支）。CONFIRMED（分支存在）。

分支头采样（2026-11-19 查询）：common 仓库默认分支头 `5c8c927af4`（2026-08-15 12:21 提交）、modules_and_devicetree `a7ab73a78d`（2026-08-15）。**这些仅是抽样点，不是锁定值**：精确 pinning 必须在 Phase 2 从 Release 清单 / 分支提交与设备构建增量（U.R4T3.…）对应后确定。状态：UNKNOWN（精确 commit ↔ 设备构建映射未建立）。

**当前阶段不把 OnePlusOSS 源码标记为“设备匹配版本”。** 分支名匹配是线索而非证据。完整映射需按以下流水线建立，全部走完之前任何构建都不得以“源码=设备”为前提：

```
stock kernel（设备实况：版本串 / config.gz / vermagic）
    ↓
OnePlusOSS source（候选分支 b_16.0.0_oneplus12，三仓）
    ↓
commit identification（设备增量与分支提交的对应关系）
    ↓
config comparison（自建 .config vs 设备 /proc/config.gz）
    ↓
symbol CRC comparison（自建 Module.symvers vs 设备模块符号 CRC）
    ↓
vendor module compatibility assessment（第十三章 L2 检查）
```

此流水线为 Phase 1/2 首要任务；未完成前，源码状态保持 UNKNOWN（设备匹配未确立）。

## 上游 GKI

- ACK `android14-6.1` 分支：设备版本串中 `-g02eb3eaaeb40` 指向其内部 GKI 提交（设备证据）。直接从 android.googlesource.com 核实分支列表未成功（本会话网络对 googlesource 不可达），状态 LIKELY（由版本串结构 + SukiSU/社区仓库惯例推断）。
- 版本串中 `-11`：KMI 代内序号（KMI `android14-11`）；`-o-`/`lotus` 为 OPLUS 构建侧标记，未从官方文档核实（UNKNOWN 详细语义，见 KMI 报告）。

## 构建工具链线索

- stock 内核横幅：clang 17.0.2 `based on r487747c`（AOSP prebuilt clang，来源 android.googlesource.com）——自建镜像的候选工具链起点。CONFIRMED（设备证据）。

## 集成对象来源（仅记录，不升级/不合并）

| 目标 | 官方来源 | 候选版本/分支 | 状态 |
|---|---|---|---|
| SukiSU Ultra | github.com/SukiSU-Ultra/SukiSU-Ultra → 已重命名重定向至 SukiSU-Nova/SukiSU-Nova（7.2k★） | 最新 release v3.0.0（2026-11-15），提供 `lkm-aarch64-android14-6.1_kernelsu.ko` | CONFIRMED |
| SUSFS | gitlab.com/simonpunk/susfs4ksu（112★，活跃） | 分支 `gki-android14-6.1` / `gki-android14-6.1-dev` | CONFIRMED |
| KernelSU-Next（对照项） | github.com/KernelSU-Next/KernelSU-Next | 最新 release v3.4.2，内置 SUSFS LKM 驱动加载 | CONFIRMED |
| SUSFS 用户态 | github.com/sidex15/susfs4ksu-module | 最新 v1.5.2+_R28（要求内核 SUSFS ≥1.5.2） | CONFIRMED |
| KPM | SukiSU-Nova 组织 SukiSU_KernelPatch_patch（206★），基于 KernelPatch（bmax121/KernelPatch） | — | CONFIRMED |

## 规则重申

以上全部为“记录来源”。按项目规范：不提前升级、不提前合并；锁定动作发生在 Phase 2，且必须经审查 PR，按 `patches/PATCHES.manifest` 记录来源与 SHA256（docs/PATCHES.md）。
