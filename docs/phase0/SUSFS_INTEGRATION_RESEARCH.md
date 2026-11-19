# SUSFS_INTEGRATION_RESEARCH — SUSFS 来源与集成路径

Phase 0 只读调查产出。仅记录与评估，不合并任何源码。

## 设备现状

| 项目 | 值 | 状态 |
|---|---|---|
| 内核侧 | 由 KernelSU 内置携带（config 中存在 `CONFIG_KSU_SUSFS=y` 及全套子项：SUS_PATH、SUS_MOUNT、SUS_KSTAT、SUS_MAP、SPOOF_UNAME、SPOOF_CMDLINE_OR_BOOTCONFIG、OPEN_REDIRECT、HIDE_KSU_SUSFS_SYMBOLS、ENABLE_LOG） | CONFIRMED |
| 版本 | 用户口径 2.2.0；源码侧应从 KSU fork 的补丁来源核实 → UNKNOWN（本次未定位到当前 KSU 4.1.3 fork 具体携带的 SUSFS 版本号） |
| 用户态 | `susfs_manager` 模块 v4.0.0（作者 ShirkNeko），配置文件 `/data/adb/ksu/susfs_config`（FSUS 二进制）：sus_loop_paths、sus_paths、hide_bl、avc_log_spoofing、hide_sus_mounts_for_all_procs 等均启用 | CONFIRMED |
| 隐藏证据 | kallsyms 中常规 SUSFS 符号被隐藏，仅剩 LH_SUS_PATH_LOOP、SUS_KSTAT_HLIST 两个数据符号 | CONFIRMED |

## 上游来源

| 来源 | 位置 | 说明 | 状态 |
|---|---|---|---|
| SUSFS 内核补丁（正溯） | gitlab.com/simonpunk/susfs4ksu | 作者 simonpunk；有 `gki-android14-6.1` 与 `-dev` 分支；按内核版本打 tag | CONFIRMED |
| KSU-Next 路线 | github.com/KernelSU-Next/KernelSU-Next（v3.4.2） | 内核驱动内置 SUSFS，README: “Built-in SUSFS LKM driver loading for GKI 2.0 devices” | CONFIRMED |
| SukiSU Nova 路线 | github.com/SukiSU-Nova/SukiSU-Nova | `kernel/extension/susfs_extension.c` 直接捆绑；manager 内置 SUSFS 管理与一键隐藏 | CONFIRMED |
| 用户态 helper | github.com/sidex15/susfs4ksu-module | 提供 ksu_susfs/sus_su 工具；**要求内核 SUSFS ≥1.5.2**；wiki 有配置文档 | CONFIRMED |
| 参考实现 | github.com/WildKernels/OnePlus_KernelSU_SUSFS | 一加设备上 KSU+SUSFS 的社区构建（其 README 可追溯到上述源） | CONFIRMED |

## 集成路径评估（Phase 1 决策用）

1. **SukiSU Nova 内置路线**（候选优先）：其 kernel/extension/susfs_extension.c 随 SukiSU 一起进树，一次集成同时获得 Root+SUSFS；管理器原生支持。LIKELY（可靠度取决于其内核分支与 android14-6.1 的适配验证）。
2. **独立 SUSFS 补丁路线**：用 simonpunk/susfs4ksu 的 gki-android14-6.1 分支补丁 + 独立 KSU。控制力最强但补丁冲突面更大。LIKELY。
3. **KSU-Next 路线**：SUSFS LKM 驱动加载（部分场景免内核补丁），但与 SukiSU 目标不完全一致。记录为对照项。CONFIRMED（能力存在）。

## 功能与版本要点

- 设备已用功能（需在迁移后保留行为）：路径隐藏、挂载隐藏、maps/kstat 伪造、uname/cmdline/bootconfig 伪造、AVC 日志伪造、给全部进程隐藏 sus mounts。
- 版本下限：用户态 helper 模块要求内核 SUSFS ≥1.5.2；当前内核为 2.x 口径，满足。新版本 SUSFS 的功能集升级需在 Phase 1 逐项评估（Unicode 修复、ptrace 相关修复等）。
