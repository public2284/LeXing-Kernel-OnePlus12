# COMPATIBILITY_MATRIX — 兼容性矩阵（Phase 1）

各行 = 组件；列 = 现状 / 目标 / 验证方法 / 状态。状态语义：OK=已验证兼容；PLAN=方案已定待 Phase 2/3 验证；UNKNOWN=需补证据。

| 组件 | 设备现状 | 自建内核目标 | 验证方法 | 状态 |
|---|---|---|---|---|
| 内核基线 | 定制 6.1.145（SukiSU 内置） | OSS b_16 分支 6.1.141 | Makefile SUBLEVEL + 版本串 + config 比对 | PLAN（141 基线已选；设备 145 存在证明跨 sublevel 可行） |
| KMI | android14-11 | 保持 android14-11 | 版本串 + L2 检查 | PLAN（硬约束已固化） |
| 符号 ABI | 模块 6.1.141 装载于内核 6.1.145 | 自建 Module.symvers 比对设备模块 CRC | kmi_check.sh / symbol_deps.sh | PLAN（验证方法已定，执行在 Phase 3） |
| vendor_dlkm | 439 个 stock 模块 | 不重刷 | 扫描全量 UND 符号 vs 自建 Module.symvers | PLAN |
| modversions | y（启用） | 保持 y | /proc/config.gz 与自建 config 比对 | PLAN |
| 模块签名 | y + SIG_ALL，SIG_FORCE 未启用 | 自签密钥，SIG_FORCE 保持未启用 | /proc/config.gz 与自建 config 比对 | PLAN |
| boot 镜像 | boot_b=192MiB，横幅已验证 | 仅刷 boot 分区 | mkbootimg 往返 + 刷号前 dd 备份 | PLAN（镜像未提取，备份步骤执行） |
| init_boot | 8MiB，未提取 | 路线 A 不改动 | dd 备份 + 结构检查 | PLAN |
| dtbo | 24MiB，未提取 | 不改动 | dd 备份 + L3 比对 | PLAN |
| vendor_boot | 192MiB，未提取 | 不改动 | dd 备份 | PLAN |
| Root 框架 | SukiSU-Ultra（内置），manager com.sukisu.ultra | SukiSU-Nova v3.0.0 内置 + manager v3.0.0_35000 | 迁移顺序 + 回退方案（SUKISU 方案） | PLAN |
| SUSFS | KSU_SUSFS 全套启用 | SukiSU 内置 susfs_extension | 功能对齐矩阵 | PLAN |
| Zygisk Next 1.5.2 / LSPosed 2.2.1 / PIF 4.9 | 装载中 | 保留，迁移后重验证 | 第九章模块测试矩阵 | PLAN |
| SELinux | Enforcing | 不变 | getenforce | OK |
| dm-verity | 全分区 verified=2 | 不刷 system/vendor 分区，不影响 | 不过滤刷分区清单 | OK |
| A/B 槽位 | 活动 _b | 刷写前确认另一槽可启 | 分区表 + 备份 | PLAN |

## KMI CRC 验证方法（扇入 Phase 3 执行）

1. 从设备提取全量 /vendor/lib/modules/*.ko（或用现有样本抽样，全量在 Phase 2 备份步骤抽取）。
2. 解析每个模块的 `__versions` 小节（modversions 表）获得所需符号与 CRC。
3. 与自建内核的 out/Module.symvers 逐符号对比；任何缺失或 CRC 不一致 → 阻断发布（L4 前的硬检查）。
4. 不允许通过关闭 modversions 或伪造 vermagic 绕过（硬约束 5）。

## 存在证明（高性能证据）

设备当前的定制内核（6.1.145）与 stock 厂商模块（6.1.141）在同一 KMI 下共存 —— 该组合已在设备上实际运行，直接证明目标架构可行。CONFIRMED。
