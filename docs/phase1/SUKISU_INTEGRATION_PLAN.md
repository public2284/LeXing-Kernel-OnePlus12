# SUKISU_INTEGRATION_PLAN — SukiSU 集成方案（Phase 1）

## 现状（Phase 0 确认）

- 设备当前运行内核已内置 SukiSU-Ultra（ksud `4.1.3-83-g197cad88` uapi:2；manager 包名 `com.sukisu.ultra`，versionCode 35692）。CONFIRMED。
- 本项目将其替换为自建内核 + SukiSU-Nova v3.0.0（manager v3.0.0_35000）。
- 集成即 root 实现的整体替换：不存在与当前内置 KSU 并存的方式。CONFIRMED（机制）。

## 路线对比与决策

| 路线 | 机制 | 优点 | 缺点 |
|---|---|---|---|
| A. 内置（CONFIG_KSU=y） | 驱动编入 Image | 与设备当前模型一致（已实证可运行）；不依赖 init_boot 改动；启动最早 | root 与镜像绑定，迭代 root 需重刷内核 |
| B. LKM（CONFIG_KSU=m + ksuinit） | 预编译/自编译 kernelsu.ko，init_boot 注入 ksuinit 加载 | root 可不换内核镜像地迭代（回退粒度细） | 需改 init_boot；加载时机与早期 init 竞争；额外失败面 |

**推荐**：Phase 3 首次构建采用**路线 A（内置）**——与该设备已验证的运行模型一致，失败面最小。路线 B 作为 Phase 4+ 的演进选项（延迟到内核稳定之后再降低 root 迭代耦合）。最终决策点：Phase 3 首构评审。

## 集成步骤（Phase 2/3 执行）

1. 以 submodule 固定 commit 引入 SukiSU-Nova（**不直接执行官方 kernel/setup.sh**，按规则 13.4：固定 commit + 等效改动以补丁登记 PATCHES.manifest）。
2. setup.sh 的实际接口为 `kernel/setup.sh [--cleanup | <commit-or-tag>]`（无 `-s` 参数），其内部执行 `git clone` + `git pull` 并在无参数时检出“最新 tag”——均为未固定版本的网络操作，违反 13.4.2，因此**不执行该脚本**。等效改动由本项目脚本在固定 submodule 上完成：创建 `drivers/kernelsu → ../../sukisu-nova/kernel` 符号链接、向 `drivers/Makefile` 追加 `obj-$(CONFIG_KSU) += kernelsu/`、向 `drivers/Kconfig` 注入 `source "drivers/kernelsu/Kconfig"`，全部以补丁固化（可复现、可审计）。
3. 版本串纪律：v3.0.0 的 `kernel/Kbuild` 在构建期调用 `git fetch --unshallow` 与 api.github.com/releases 查询版本号（仅用于版本串，不取代码）。构建脚本须固定 `KSU_BUILD_REF=v3.0.0` 并保留 submodule 的 .git 元数据，使版本号可本地解析；离线时回退本地 git 值。
4. main 分支前提已在 stock config 中满足（KPROBES/KRETPROBES/TRACEPOINTS/EXT4 全部 =y）。CONFIRMED。
5. CONFIG_KSU=y（minimal profile 起）；KPM 不启用（见风险登记）。
6. manager：SukiSU_Nova_v3.0.0_35000（与镜像版本配套，版本不匹配时管理器不识别 root）。CONFIRMED（机制）。

## 迁移顺序（不得调换）

1. 备份（boot/init_boot/dtbo/vendor_boot/vbmeta + KSU 配置 + 模块清单，第 3.3 节）→
2. 自建内核镜像就位（CI 全绿 + L1–L3 通过 + 人工 L4 记录 APPROVED）→
3. 刷写并验证 root →
4. 切换 manager APK（新旧管理器短暂并存仅用于验证，不在 root 环境中叠加竞争。实际顺序：先验证 root 可用，再装新管理器；卸载旧管理器在确认新管理器工作后）→
5. Zygisk Next / LSPosed / PIF 依次重验证。任一失败 → 回退到步骤 1 的备份。

## 回退方案

- A/B 槽位：当前活动槽 `_b`；刷写前确认另一槽可启（或在专门批准的备份步骤中先升级非活动槽验证）。
- boot 镜像回退 = dd 回原镜像（备份步骤产出物）。
- manager 回退 = 重装旧 APK（保留至 Phase 4 验证完成）。

## 未决项

- SukiSU-Nova 与现有 `com.sukisu.ultra` 管理器的数据库/配置文件兼容性：UNKNOWN（Phase 3 迁移前抽样验证）。
- LKM 路线的 init_boot 注入细节未设计：路线 B 未选中，暂不投入。
