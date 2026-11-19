# BUILD_PROFILES — 构建变体定义（Phase 1）

四个 Build Profile（第 6/7 章）。Kconfig 片段位于 `build/profiles/*.fragment`，以内核 `merge_config.sh` 合并入设备 defconfig。**以下符号为第一步计划，符号有效性在 Phase 2 源码 pin 后由 `build/checks/kconfig_symbols.sh` 强制校验**。

| Profile | 目的 | 编译期内容 | Phase 3 构建顺序 |
|---|---|---|---|
| minimal | 最小化、兼容性优先 | GKI 基线 + SukiSU 内置（SUSFS 随之无条件编入，见下）+ kprobes/ftrace/BTF 基础设施 | **首构唯一 profile** |
| full | 功能完整 | minimal + Feature Registry 中经评估的稳定编译期功能（当前 CANDIDATE 完成评估后填充） | 首构验证通过后 |
| debug | 调试 | full + 详细调试信息与调试设施（保持可启动） | 按需 |
| experimental | 实验性 | full + 实验性功能（如 KPM） | 仅 experimental/* 分支，产物永不进 release |

## 首构 minimal 定义（详细）

- 不启用：KPM（CONFIG_KPM 保持默认 n）、任何 CANDIDATE 功能、任何调度器/内存调优。
- SUSFS 说明：SukiSU-Nova v3.0.0 路线 A 下 SUSFS 随 CONFIG_KSU 无条件编入（Kbuild 无开关），无法在编译期排除；首构的“最小化”体现为不下发任何运行期 SUSFS 清单。需要编译期排除须走路线 B（独立补丁）。
- 保留：stock 已启且政策要求的项（kprobes/kretprobes/tracepoints/ext4/BTF/ftrace、modversions、module signing、kptr 限制）。
- LOCALVERSION：保持 `…-android14-11-…-lotus` 主体 + 项目后缀。

## profile 验证规则

- 每个引用的 CONFIG_ 符号必须存在于内核源码 Kconfig（静态检查，PR 级）。
- 保护符号表（安全/启动关键 CONFIG）变更需人工 review（docs/phase1/RISK_ASSESSMENT.md）。
- 差异不得改变 KMI（Phase 1 硬约束 1）。
