# FEATURE_REGISTRY — 功能注册表初版（Phase 1）

所有候选功能的注册中心。注册 ≠ 启用：任何功能入默认 profile 前必须有源码、依赖、设备兼容性与稳定性评估（项目第六章）。初版仅注册 Root/Built-in 能力，其余列为候选（CANDIDATE）。具体记录 YAML 在 `features/` 目录，schema 由 `build/checks/manifest_schema.sh` 强制校验。

## Root / 内核框架

| ID | 名称 | 类型 | 默认 | 风险 | 状态 |
|---|---|---|---|---|---|
| root/sukisu-nova | SukiSU Nova | compile-time | enabled | high | REGISTERED（Phase 3 首构主功能，路线 A 内置） |
| root/susfs | SUSFS | compile-time | enabled | medium | REGISTERED（随 SukiSU 内置，功能对齐矩阵见 SUSFS 方案） |
| root/kpm | KPM | compile-time | disabled | medium | REGISTERED（官方提示影响稳定性；无需求，首构不启用） |

## 候选目录（未评估，不进入任何 profile）

| ID | 名称 | 类型 | 风险 | 状态 |
|---|---|---|---|---|
| memory/zram | ZRAM（含压缩算法选择） | compile+runtime | low | CANDIDATE |
| memory/zswap | zswap | compile-time | medium | CANDIDATE |
| memory/psi | PSI 压力信息 | compile-time | low | CANDIDATE（stock 可能已启用，需查 config.gz） |
| memory/damon | DAMON | compile-time | medium | CANDIDATE |
| scheduler/tunings | 调度器调优 | compile+runtime | medium | CANDIDATE |
| net/tcp-congestion | TCP 拥塞控制 | compile+runtime | low | CANDIDATE |
| net/ntsync | NTSync | compile-time | medium | CANDIDATE |
| debug/dynamic-debug | Dynamic Debug | compile-time | low | CANDIDATE |
| debug/ftrace | Ftrace | compile-time | low | CANDIDATE（stock 已启 CONFIG_FTRACE=y） |
| kernel/btf | BTF | compile-time | low | CANDIDATE（stock 已启 CONFIG_DEBUG_INFO_BTF=y） |

## 注册表与 Profile 的关系

- Build Profile（docs/phase1/BUILD_PROFILES.md）只能引用状态为 REGISTERED 且设备评估完成的功能。
- 每个功能 YAML 必须含：id/name/description/source/type/default_state/risk/enable/disable/rollback 以及 dependencies/conflicts/kconfig/compatibility。
- 编译期功能 → Kconfig 片段；运行期功能 → 安装器配置；hybrid 两者皆有，需明确拆分。
