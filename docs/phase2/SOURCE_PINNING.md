# SOURCE_PINNING — 源码固定与映射证据（Phase 2 首段）

## pins（2026-11-19 固定，gitlink 已登记，更新仅限审查 PR）

| 路径 | 来源 | Commit | 同步点 |
|---|---|---|---|
| kernel/ | OnePlusOSS/android_kernel_oneplus_sm8650 | `b2696d4a2bda11cb74de35f839ef0cf6ccc1b9cb` | Synchronize code for OnePlus CPH2573_16.0.10.501(EX01) 等（2026-09-14） |
| kernel-common/ | OnePlusOSS/android_kernel_common_oneplus_sm8650 | `ebdd1643cfdbf719fb59c6573ce0abe6e794a5cc` | 同上 |
| vendor-modules/ | OnePlusOSS/android_kernel_modules_and_devicetree_oneplus_sm8650 | `c951f93ec63fbee49d468ee2f9d93ac0e807da67` | 同上 |
| sukisu-nova/ | SukiSU-Nova/SukiSU-Nova | `c60f21b9e00e35e898f8d21e0612465b76b9beec` (= release v3.0.0) | v3.0.0（2026-11-15） |
| AnyKernel3/ | Kernel-SU/AnyKernel3 | `80e0cc9e736572ad16c7dc539ba9b6e40749f8e7` | master head（2025-11-07） |

机器可读 pins：`build/source.lock`。

## 映射证据（补审查要求的“源码定位”）

| 证据 | 值 | 状态 |
|---|---|---|
| OSS Makefile SUBLEVEL（三仓同步点均一致） | 141 | CONFIRMED |
| OSS `android/ACK_SHA`（kernel 仓） | `5b80c8852557d24c2771da11044933210a92f543`，分支标签 `android14-6.1-2024-03_r7` | CONFIRMED |
| 设备内核 GKI commit | `-g02eb3eaaeb40`（定制内核） | CONFIRMED |
| stock 模块 vermagic GKI commit | `-g5de16d278e6c`（6.1.141） | CONFIRMED |

**结论**：OSS 源码与设备 stock 模块同代（141），但 GKI 基线快照不同（源码 2024-03_r7 / ACK 5b80c885 vs 设备侧 5de16d278e6c）。映射状态 = **PARTIAL**：子级别与模块代一致，精确 commit 对应未建立；最终裁决仍为 Phase 3 的符号 CRC 比对（硬约束 4）。

## 配置比对（流水线第 2 步，2026-11-19）

比较对象：设备 `/proc/config.gz`（6,052 符号）vs 源码 `gki_defconfig + pineapple_GKI.config`（合并后 1,259 显式符号，其余由 Kconfig 默认补齐）。

- **值冲突仅 1 项**：`CONFIG_MODULE_SIG_ALL`（设备 y / 源码 n）——为 OPLUS 构建配置层覆盖（defconfig 不是完整构建配置），非源码不匹配信号。
- 设备独有符号为定制内核预期项：全套 `CONFIG_KSU*`/`CONFIG_KSU_SUSFS*`、`CONFIG_SUKISU_KPM=y`（当前内核开了 KPM！）、GKI 标准的 MODULE_SIG/DEBUG_INFO_BTF/KALLSYMS/TRACEPOINTS/PREEMPT 等。
- 源码侧独有的 483 项绝大多数为 `# CONFIG_* is not set` 显式禁用，含义正常。

状态：**配置层面无重大不一致（PARTIAL CONFIRMED）**；完整等价性判定仍需 Phase 3 构建后的 config diff 检查。

## 设备补发现

- 设备当前内核 `CONFIG_SUKISU_KPM=y`：KPM 已启用（先前 PHASE0_GAPS 记录为“无需求”存在偏差——当前内核有 KPM，但我们的首构仍不启用，迁移后再评估）。
- ABI 工具链在位：源码含 `android/abi_gki_aarch64_oplus` / `abi_gki_aarch64_qcom` / `abi_gki_protected_exports_aarch64` 与 `abi_gki_aarch64.stg`——为 Phase 3 KMI 比对提供基线。

## 下一步

1. 构建 KMI 比对基线：以 `abi_gki_aarch64_oplus` 为基，提取设备模块符号 CRC（Phase 3 执行）。
2. 本仓编译环境率定：builder 镜像 pin（toolchain.env/image.lock），在 Phase 2 后续任务中完成。
