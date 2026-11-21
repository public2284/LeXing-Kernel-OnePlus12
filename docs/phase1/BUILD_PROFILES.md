# BUILD_PROFILES — 构建变体定义（Phase 1）

四个产品 Build Profile（第 6/7 章）和一个临时诊断变体。Kconfig 片段位于 `build/profiles/*.fragment`，以内核 `merge_config.sh` 合并入设备 defconfig。**以下符号为第一步计划，符号有效性在 Phase 2 源码 pin 后由 `build/checks/kconfig_symbols.sh` 强制校验**。

| Profile | 目的 | 编译期内容 | Phase 3 构建顺序 |
|---|---|---|---|
| minimal | 最小化、兼容性优先 | GKI 基线 + SukiSU 内置（SUSFS 随之无条件编入，见下）+ kprobes/ftrace/BTF 基础设施 | **首构唯一 profile** |
| full | 功能完整 | minimal + Feature Registry 中经评估的稳定编译期功能（当前 CANDIDATE 完成评估后填充） | 首构验证通过后 |
| debug | 调试 | full + 详细调试信息与调试设施（保持可启动） | 按需 |
| experimental | 实验性 | full + 实验性功能（如 KPM） | 仅 experimental/* 分支，产物永不进 release |
| diagnostic | 临时诊断 | minimal 基线 + 仅关闭 SCX（KSU 保持 y） | 仅 Phase 3 bisect，禁止用于 release |

## 首构 minimal 定义（详细）

- 不启用：KPM（CONFIG_KPM 保持默认 n）、任何 CANDIDATE 功能、任何调度器/内存调优。
- SUSFS 说明：SukiSU-Nova v3.0.0 路线 A 下 SUSFS 随 CONFIG_KSU 无条件编入（Kbuild 无开关），无法在编译期排除；首构的“最小化”体现为不下发任何运行期 SUSFS 清单。需要编译期排除须走路线 B（独立补丁）。
- 保留：stock 已启且政策要求的项（kprobes/kretprobes/tracepoints/ext4/BTF/ftrace、modversions、module signing、kptr 限制）。
- LOCALVERSION：保持 `…-android14-11-…-lotus` 主体 + 项目后缀。

## diagnostic 变体边界

- 仅用于 Phase 3 启动失败 bisect；不得作为 minimal、release 或候选发布产物。
- 每次只验证一个变量，构建信息必须能明确区分 diagnostic 与正式 minimal。
- 当前 diagnostic 仅关闭 `CONFIG_SCHED_CLASS_EXT`，保持 `CONFIG_KSU=y`；PR #51 的 KSU-off 构建已经失败，因此这不是当前待测变量。
- 关闭 KSU 时不得期待 Root；关闭 SCX 时不得据此宣称调度器兼容性已验证。
- bisect 结束后必须删除或停止维护该变体，避免诊断配置漂移进正式 profile。

## profile 验证规则

- 每个引用的 CONFIG_ 符号必须存在于内核源码 Kconfig（静态检查，PR 级）。
- 保护符号表（安全/启动关键 CONFIG）变更需人工 review（docs/phase1/RISK_ASSESSMENT.md）。
- 差异不得改变 KMI（Phase 1 硬约束 1）。
