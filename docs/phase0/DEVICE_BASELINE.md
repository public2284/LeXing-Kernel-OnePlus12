# DEVICE_BASELINE — OnePlus 12 (CPH2573)

Phase 0 只读调查产出，2026-11-19。证据通道：ADB（主通道）与手机端 Agent root shell（交叉验证，`/proc/version` 两通道逐字节一致）。每条结论标注 CONFIRMED / LIKELY / UNKNOWN。

## 设备身份

| 项目 | 值 | 状态 |
|---|---|---|
| 厂商/型号 | OnePlus CPH2573（中国版，设备名 OP595DL1，区域 CPH2573IN） | CONFIRMED |
| SoC | Qualcomm SM8650（Snapdragon 8 Gen 3），平台代号 pineapple | CONFIRMED |
| 内存 | 15,560,844 kB（16 GB 配置） | CONFIRMED |
| 存储 | UFS，sda 1,989,976,064 扇区（×512 ≈ 1019 GB） | CONFIRMED |
| 系统 | Android 16（SDK 36）/ ColorOS 16 | CONFIRMED |
| 构建 | BP2A.250605.015 / 增量 U.R4T3.1ee2725_642f40_642bb6，release-keys | CONFIRMED |
| 安全补丁 | 2026-08-01（bootimage 构建日期 2026-08-11） | CONFIRMED |
| 设备树基线 | `qcom,pineapple-mtp qcom,pineapple qcom,pineapplep-mtp qcom,pineapplep qcom,mtp` | CONFIRMED |

## 内核

| 项目 | 值 | 状态 |
|---|---|---|
| /proc/version | `Linux version 6.1.145-android14-11-o-g02eb3eaaeb40-lotus (emira@Lotus) (Android (10087095, +pgo, +bolt, +lto, -mlgo, based on r487747c) clang version 17.0.2 …, LLD 17.0.2) #1 SMP PREEMPT Fri Jun 13 03:35:54 UTC 2025` | CONFIRMED（双通道） |
| 分支谱系 | ACK `android14-6.1`（GKI 2.0），KMI 代号 `android14-11` | LIKELY（由版本串推断，“-o-” 后缀与构建变体含义未核实，见 KMI 报告） |
| 构建变体 | 构建主机 `lotus`（OPLUS 内部），Android 16 OTA 沿用 2025-06-13 的内核构建横幅 | CONFIRMED |
| 调度 | PREEMPT（CONFIG_PREEMPT=y） | CONFIRMED |
| 完整内核配置 | `/proc/config.gz` 全局可读，已提取（7,613 行，2,190 个 CONFIG_） | CONFIRMED |

## 启动结构

| 项目 | 值 | 状态 |
|---|---|---|
| A/B 槽位 | 活动槽 `_b` | CONFIRMED |
| 动态分区 | 是（dm-30..46，super=sda13） | CONFIRMED |
| boot 参数 | `bootconfig` 支持；`kpti=0`、`kasan=off`、`nosoftlockup`、`loop.max_part=7`、OPLUS 私有参数（oplusboot.prjname=22825 等） | CONFIRMED |
| Bootloader | 两通道状态呈现不一致（原始记录见下节）。用户人工确认已解锁；差异机制未直接证明 | LIKELY |
| SELinux | Enforcing | CONFIRMED |

## Bootloader 状态证据（原始记录，未微调）

- 获取路径：`adb shell cat /proc/cmdline`（oplusboot 通道）与 `adb shell getprop`（标准通道，属性源于启动参数）。
- oplusboot 通道（/proc/cmdline 原文）：`oplusboot.verifiedbootstate=orange`
- 标准通道（getprop 原文）：`ro.boot.verifiedbootstate=green`、`ro.boot.vbmeta.device_state=locked`、`ro.boot.flash.locked=1`、`vendor.boot.verifiedbootstate=green`、`vendor.boot.vbmeta.device_state=locked`
- 相关配置：内核 `CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y`（内核侧具备伪造 cmdline/bootconfig 的能力，但本次未获取伪造动作本身的直接证据）。
- 评估：用户人工确认设备已解锁，oplusboot 通道的 orange 更接近真实状态；两通道差异**推断**为 KSU/SUSFS 侧对标准通道的呈现修改。结论等级：解锁状态 LIKELY（人工确认 + orange）；伪造机制 LIKELY（能力存在 + 逻辑推断，未直接证明）。
- 未使用 `fastboot oem device-info` 直接核实（不重启原则）。后续任何安全检查都不得以单一状态字符串作为判据。

## Root 环境（只读记录，不修改）

| 项目 | 值 | 状态 |
|---|---|---|
| 框架 | KernelSU，ksud `4.1.3-83-g197cad88`（uapi: 2） | CONFIRMED |
| SUSFS | 内核侧内置（config 中全套 CONFIG_KSU_SUSFS_*）；用户态 `susfs_manager` 模块 v4.0.0（作者 ShirkNeko），配置在 `/data/adb/ksu/susfs_config`（FSUS 二进制） | CONFIRMED |
| KernelSU 隐藏 | kallsyms 中仅 `setup_ksu_cred`、`is_task_ksu_domain` 等可见，常规模号被 SUSFS 隐藏（LH_SUS_PATH_LOOP、SUS_KSTAT_HLIST 两个数据符号残留） | CONFIRMED |
| 模块清单 | Caelifall_SensorDecoy、LeXingBoost_v1.2.zip.backup、RescueBrick、WorkSettingPro、fastchg_probe、hma_oss_zygisk、op12-unified-mod、playintegrityfix、susfs_manager、teesim、zygisk_lsposed、zygisksu | CONFIRMED |
| 版本 | Zygisk Next 1.5.2（864）、LSPosed v2.2.1（7912）、PlayIntegrityFix v4.9-inject-s | CONFIRMED |
| 其他 | /data/adb 下另有 lspd、zygisksu、tricky_store、kpm、备份与快照目录（本次仅读取，不动） | CONFIRMED |

## 关键启动参数（来自 /proc/cmdline，仅记录）

`console=ttynull bootconfig kpti=0 kasan=off fw_devlink.strict=1 service_locator.enable=1 cpufreq.default_governor=performance sysctl.kernel.sched_pelt_multiplier=4 … oplusboot.prjname=22825 … oplusboot.verifiedbootstate=orange`（完整原文保留在工作区原始证据，未入库）
