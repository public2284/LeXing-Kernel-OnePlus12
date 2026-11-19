# RISK_ASSESSMENT — 风险登记表（Phase 1）

影响 × 可能性评级，附带缓解与回退。Phase 3 首构前必须逐项复核。

| # | 风险 | 影响 | 可能性 | 缓解 | 回退 |
|---|---|---|---|---|---|
| R1 | 自建 CRC 与 stock 模块不匹配 → 模块加载失败（Wi-Fi/音频/指纹/相机等） | 高 | 中 | KMI 硬约束全流程（CRC 比对阻断发布）；设备存在证明 141 模块与 145 内核兼容 | 回退到 stock 内核镜像（dd 备份） |
| R2 | OSS 141 源码与设备实际不完全对应（未可视化具体 commit 映射） | 高 | 中 | 源码 pin 流水线（config 比对 + CRC 比对）；不作设备匹配断言 | 更早 sync commit 重试 |
| R3 | 刷写后无法启动（启动循环） | 高 | 低 | A/B 槽位 + 仅刷 boot + 首构 minimal profile；AnyKernel3 严格分区检查 | dd 回原 boot 镜像；必要时进 recovery |
| R4 | manager 切换后 root 识别失败 / 模块生态受损 | 中 | 中 | 镜像与 manager 版本配套；迁移顺序固定；Zygisk/LSPosed 逐项重验证 | 回退旧 manager + 备份镜像 |
| R5 | SUSFS 功能回归（某些隐藏能力夹失或行为变化） | 中 | 低 | 功能对齐矩阵逐项核对（8 项必保） | 回退备份镜像 |
| R6 | KPM 启用导致不稳定 | 中 | 避免中 | 首构不启用 KPM（风险等级 medium，无需求） | 不启用即无此风险 |
| R7 | dtbo/vendor_boot 误改动 → 硬件异常 | 高 | 低 | 架构决定不改动；备份原分区 | dd 回原分区 |
| R8 | 模块签名机制变更导致 stock 模块加载被拦截 | 中 | 低 | SIG_FORCE 保持未启用；config 比对 | 回退 |
| R9 | 编译环境漂移导致不可复现 | 中 | 低 | digest 固定镜像 + 双版本链（ENV_VERSION） | 重新构建并核对 |
| R10 | 高安全环境检测（银行/Play Integrity）因内核变动失败 | 中 | 中 | SUSFS 伪造能力保留；迁移后用 PIF 等验证 | 回退 |

## Phase 3 准入门槛（合并 R1–R3 为硬门槛）

1. 源码 pin 完成（config 比对与 CRC 比对通过，源码状态由 UNKNOWN 转为 MATCHED）。
2. 镜像备份完成且 SHA256 校验通过。
3. CI L1–L3 全绿；L4 人工记录机制就位。
4. 风险登记表复核（本文件）。
