# SUSFS_INTEGRATION_PLAN — SUSFS 集成方案（Phase 1）

## 版本选择

设备内核现有 SUSFS 为 KSU 4.1.3 fork 携带（用户口径 2.2.0，源号未定位——Phase 0 UNKNOWN）。新版来源三选：

| 路线 | 来源 | 状态 |
|---|---|---|
| A. SukiSU 内置 | SukiSU-Nova `kernel/extension/susfs_extension.c` | 推荐（Phase 3 首构随 SukiSU 一起进树；补丁冲突面最小、管理器原生支持） |
| B. 独立补丁 | gitlab.com/simonpunk/susfs4ksu 分支 `gki-android14-6.1` | 备选（控制力最强、冲突面更大；独立补丁源 commit 需在 Phase 2 pin） |
| C. KSU-Next 内置 | KernelSU-Next | 对照项（与 SukiSU 目标不一致，不采用） |

**推荐 A**，保留 B 为 fallback：若 SukiSU 内置版本功能与设备现有集出现缺口（对比下表），则用独立补丁补齐缺口项。

## 功能对齐矩阵（设备现有 vs 目标）

| 功能 | 设备现有（CONFIG） | SukiSU-Nova 扩展中心 | 迁移处理 |
|---|---|---|---|
| 路径隐藏（sus_path） | ✅ KSU_SUSFS_SUS_PATH | ✅ | 必保 |
| 挂载隐藏（sus_mount） | ✅ | ✅ | 必保 |
| maps/kstat 伪造 | ✅ SUS_KSTAT/SUS_MAP | ✅ | 必保 |
| uname/cmdline/bootconfig 伪造 | ✅ | ✅ | 必保（Bootloader 指示器呈现依赖此项） |
| AVC 日志伪造 | ✅（avc_log_spoofing 启用） | ✅ | 必保 |
| 给全部进程隐藏 sus mounts | ✅ | ✅ | 必保 |
| open_redirect | ✅ | ✅ | 必保 |
| 符号隐藏 | ✅ HIDE_KSU_SUSFS_SYMBOLS | ✅ | 必保 |

迁移时将 `/data/adb/ksu/susfs_config` 的清单（sus_paths/sus_loop_paths 等）导出并导入新管理器。

## 用户态

- 采用路线 A 时：SukiSU-Nova 的 ksud 自动生成 `susfs_manager` 模块（设备上现有 v4.0.0 为同一机制产物）。不额外安装 sidex15 helper。
- 配置备份与迁移纳入刷机前备份清单（抄 3.3 节）。

## 编译期开关现状（v3.0.0 源码实测，2026-11-19）

- SukiSU-Nova v3.0.0 的 `kernel/Kconfig` 只定义 KSU / KSU_DEBUG / KSU_MANUAL_SU / KPM / KSU_DISABLE_MANAGER / KSU_DISABLE_POLICY 等符号，**不定义 CONFIG_KSU_SUSFS 及其子符号**。
- `kernel/Kbuild` 中 `kernelsu-objs += extension/susfs_extension.o` 为**无条件**语句：只要 CONFIG_KSU=y，SUSFS 必然编入。
- 因此路线 A 下 SUSFS **没有独立编译期开关**；启用/停用粒度在运行期（管理器清单与内核启动参数）。
- 设备现有 CONFIG_KSU_SUSFS_* 符号集来自旧 KSU 4.1.3 系补丁，与 v3.0.0 不同名；功能对齐矩阵按**功能等价**理解，不按符号同名理解。
- 需要编译期关闭 SUSFS 的场景只能由路线 B 承担（gitlab simonpunk/susfs4ksu 分支 `gki-android14-6.1` 已确认存在）。
