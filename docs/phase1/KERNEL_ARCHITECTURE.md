# KERNEL_ARCHITECTURE — 内核架构方案（Phase 1）

Phase 1 技术方案产出。继承 Phase 0 证据，继承审查硬约束（KMI、源码映射、不绕过 modversions）。

## 关键架构事实（Phase 0 + 补充探针）

1. 设备运行内核为**定制构建**：`CONFIG_KSU=y` 与全套 `CONFIG_KSU_SUSFS_*` 只可能出现在 KSU 系内核中；横幅虽为 OPLUS 风格（emira@Lotus）但内核为自带 KernelSU/SUSFS 的社区构建（manager 包名 `com.sukisu.ultra`）。CONFIRMED。
2. stock 厂商模块以 6.1.141-vermagic 装载在 6.1.145 定制内核上（modversions 兼容）——**设备本身就是“定制内核 + stock 模块”目标架构的存在证明**。CONFIRMED。
3. OnePlusOSS `oneplus/sm8650_b_16.0.0_oneplus12` 三仓公开源码 Makefile **SUBLEVEL=141**，与 stock 模块同代。CONFIRMED。

结论：**以 OSS 141 源码为构建基线**，与设备 vendor 模块同代，KMI 复现风险最低；不追求复现 6.1.145（该内核为定制源码构建，官方源码未发布）。

## 分层架构

```
┌────────────────────────────────────────────────────────────┐
│ 交付层：AnyKernel3 zip（仅刷写 boot 分区）                       │
├────────────────────────────────────────────────────────────┤
│ 集成层：SukiSU-Nova 驱动（drivers/kernelsu，固定 commit）          │
│         SUSFS（随 SukiSU 内置 susfs_extension，见 SUSFS 方案）      │
│         项目补丁层（patches/，有清单、有序）                        │
├────────────────────────────────────────────────────────────┤
│ 板级层：OnePlusOSS/android_kernel_oneplus_sm8650           │
│         （SM8650 SoC/板级代码，defconfig，设备驱动）                │
├────────────────────────────────────────────────────────────┤
│ GKI 层：OnePlusOSS/android_kernel_common_oneplus_sm8650    │
│         （ACK android14-6.1 谱系 + OPLUS common 改动 + ABI 符号表）  │
├────────────────────────────────────────────────────────────┤
│ 厂商侧（不重刷）：vendor_dlkm 439 模块（6.1.141，KMI android14-11）  │
└────────────────────────────────────────────────────────────┘
```

## Source Pinning 方案（Phase 2 执行，此处定方法）

候选 pin（2026-11-19 读取的分支头，对应 `Synchronize code for OnePlus CPH2573_16.0.10.501(EX01)`）：

| 仓库 | 候选 commit | 状态 |
|---|---|---|
| android_kernel_common_oneplus_sm8650 | `ebdd1643cf` | CANDIDATE（待 config/CRC 比对确认） |
| android_kernel_oneplus_sm8650 | `b2696d4a2b` | CANDIDATE |
| android_kernel_modules_and_devicetree_oneplus_sm8650 | `c951f93ec6` | CANDIDATE（为模块源码/设备树参考，非构建必需） |

确认流程（执行审查要求的流水线）：
1. checkout 三仓到上述 commit，记录 git tree hash。
2. 生成 defconfig 并与设备 `/proc/config.gz` 比对（diffconfig），差异列入兼容性矩阵。
3. 构建，产出 Module.symvers，与设备 439 模块的 vermagic/符号 CRC 比对（KMI 硬约束 2/4）。
4. 任一环节差异超阈值 → 回退到更早的 sync commit（分支历史包含 16.0.9.400、16.0.8.300 等更早点）重新比对。
5. 完成前，源码状态保持 UNKNOWN（设备匹配未确立）——本状态也在 `.phase-state` 与构建日志中体现。

## 编译期 vs 运行期分层

- **编译期**（Kconfig，进 Image）：SukiSU 驱动、SUSFS、BTF/kprobes/ftrace 基础设施、调度器与内存可选优化。由 Build Profile 冺定（docs/phase1/BUILD_PROFILES.md）。
- **运行期**（用户态配置，不进镜像）：ZRAM 参数、SUSFS 跰径清单、SukiSU 扩展中心开关、KPM 载入。由安装器/管理器管理。
- 原则：不把无法运行期关闭的功能伪装成可选；编译期差异必须以不同 Build Profile 提供。

## 模块签名与安全

- 沿用 stock 行为：`CONFIG_MODULE_SIG=y` + 自签构建密钥（密钥在构建时生成，不入仓库），`CONFIG_MODULE_SIG_FORCE` 保持未启用（stock 即如此，stock 模块与自建模块均可加载）。
- `CONFIG_MODVERSIONS` 必须保持启用（Phase 1 硬约束 5）。
- Kptr 限制保持与 stock 一致（kallsyms 地址置零）。

## 版本串与 vermagic 策略

- 自建内核 LOCALVERSION 保持 `…-android14-11-o-g<sha>-lotus` 主体格式，可追加项目后缀（如 `-lexing`）。
- 自建模块与自建内核共享 vermagic；stock 模块依靠 modversions CRC 装载（设备已实证该路径）。KMI 检查脚本（第十三章）负责验证。

## 未决项

- sync commit 与设备 OTA（CPH2573_11.F.57）的精确对应：UNKNOWN（见 COMPATIBILITY_MATRIX）。
- stock 内核的实际横幅未直接观测（设备现为定制内核）：UNKNOWN。
