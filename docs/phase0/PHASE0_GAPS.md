# PHASE0_GAPS — 未决项、方法学注记与遗留风险

Phase 0 只读调查产出。列出尚未验证、需人工裁决或需下一阶段补齐的项。

## 数据与方法学

- **Agent 通道可信度**：手机端 Agent（Operit root shell）在本次两轮调用中，首轮末尾曾混入一段与本次任务无关的回复内容（技能文档预警过该通道存在注入伪造输出先例）。处置：仅采信带 `===标签===` 的原始命令回显，且关键值（/proc/version、分区尺寸列表）均已由 ADB 独立交叉验证。CONFIRMED（方法）。不在本次调查结论中引用任何未交叉验证的 Agent 叙述。
- **原始证据不入库**：`/proc/config.gz`、kallsyms（22 MB）、两个 .ko 样本、kernel.config 等仅保留在本地工作区 `docs/phase0/raw/`（未提交），报告内只写结论。CONFIRMED（策略）。
- **安全地读取**：本次全部设备操作为 read-only（getprop、cat、ls、blockdev --getsize64、adb pull /proc/* 与 /vendor/lib/modules/*.ko）。未执行任何 setprop、写入、重启或刷写。CONFIRMED。

## 未决项（UNKNOWN）

1. **源码 commit ↔ 设备构建的精确映射**：OnePlusOSS 分支 `oneplus/sm8650_b_16.0.0_oneplus12` 存在，但设备增量版本 U.R4T3.1ee2725_642f40_642bb6 对应的具体 commit 未确定。Phase 2 pinning 前必须解决，否则"可复现构建"无从谈起。
2. **OnePlusOSS 源码完整性**：公开源码是否包含全部 OPLUS 私有改动与 vendor 模块构建产物（stock 模块的 vermagic/CRC 能否从公开源码重现）。决定 KMI 复现风险。
3. **KMI 详细语义未从官方文档核实**：本会话对 source.android.com 与 android.googlesource.com 均不可达；"android14-11" 的代内编号规则、"-o-" 后缀含义为推断。需在后续会话或通过其他网络出口核实（如可翻“墙”或换出口）。
4. **SUSFS 精确版本**：设备 KSU 4.1.3（-83-g197cad88，uapi 2）属于哪个 fork、携带的 SUSFS 版本号未定位（用户口径 2.2.0）。影响新 SUSFS 版本的功能差异比对。
5. **Bootloader 标准指示器与真实状态不一致**：oplusboot.verifiedbootstate=orange（ unlocked）与 ro.boot.verifiedbootstate=green/vbmeta.device_state=locked 并存。用户确认已解锁，绿色指示系 KSU/SUSFS 伪造（SPOOF_CMDLINE_OR_BOOTCONFIG 配置佐证）。**不重启设备、不进 fastboot 核实**——按用户结论采信，伪造机制为 LIKELY。
6. **启动镜像未导出**：boot/init_boot/dtbo/vendor_boot 的实际镜像内容未 dd 提取。这是 Phase 3 前备份方案（第三章 3.3）的必要输入，但提取动作属于"备份"步骤，应在专门批准的备份环节执行。
7. **DTB/DTBO 基线**：/proc/device-tree 仅提供 compatible 等顶层信息；原始 dtbo/dtb 二进制未提取，L3 比对基线缺失（与第 6 项一并处理）。
8. **super 内部布局偏移**未测量。
9. **当前管理器 APK 版本**：KernelSU Manager 的具体版本号未读（未连接其应用数据），对评估 SukiSU Nova 管理器替换步骤有影响。

## 需要人工裁决的判断（Phase 1 输入）

- SukiSU 集成分支选择（main=运行时 hook vs builtin=手动 hook）——本设备 main 分支前提全部满足，倾向 main（LKM 或内核内置均可），Phase 1 决策。
- KPM 是否启用：官方提示可能影响稳定性，且当前没有 KPM 使用需求（kpm 目录存在仅作记录）。
- SukiSU 扩展中心与现有隐藏模块（SensorDecoy/PIF/SUSFS manager）功能重叠的去重策略。

## 下一步建议（不在本轮执行）

按项目规范等待 Phase 0 人工审核通过后，进入 Phase 1：Kernel Architecture、SukiSU 集成方案、SUSFS 方案、Feature Registry 初版、兼容性矩阵与风险评估。
