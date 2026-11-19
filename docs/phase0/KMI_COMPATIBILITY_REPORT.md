# KMI_COMPATIBILITY_REPORT — KMI 与模块兼容性

Phase 0 只读调查产出。核心问题：自建内核必须能装载 439 个 stock 厂商模块（不重刷 vendor_dlkm），否则 Wi-Fi/音频/指纹/相机全部抓瞎。
## 核心事实

| 证据 | 值 | 状态 |
|---|---|---|
| 运行中内核 | `6.1.145-android14-11-o-g02eb3eaaeb40-lotus` | CONFIRMED（双通道） |
| stock 厂商模块 vermagic | `6.1.141-android14-11-o-g5de16d278e6c SMP preempt mod_unload modversions aarch64` | CONFIRMED（aw8697.ko、atmel_mxt_ts.ko 两个样本直接解析） |
| 模块目录 | /vendor/lib/modules，439 个 .ko | CONFIRMED |
| CONFIG_MODVERSIONS | y（启用符号 CRC 兼容机制） | CONFIRMED |
| CONFIG_MODULE_SIG | y + SIG_ALL + PROTECT，SHA1，SIG_FORCE 未启用 | CONFIRMED |
| lsmod | 厂商模块加载中（qca_cld3_kiwi_v2、rmnet_*、msm_drm 等） | CONFIRMED |

## 关键事实：跨版本装载已在设备上发生

运行内核是 6.1.145，但 stock 模块按 6.1.141 构建。二者版本串在同一 KMI（`android14-11`）内，且 `modversions` 机制启用。这证明当前内核与这批模块间**存在实际可用的兼容关系**；但“能装载在当前内核”不能推广为“能装载在任意同 KMI 串内核”。

### 结论分层（按证据支持程度）

| 结论 | 当前证据支持程度 |
|---|---|
| 这批 stock 模块能够在当前 6.1.145 内核上正常工作 | **强**（lsmod 实际加载中，双通道读取） |
| 这批模块依赖的符号 CRC 与当前内核兼容 | **待补证据**：CONFIG_MODVERSIONS=y 提供机制前提，但 CRC 级比对尚未执行 |
| 任意自行编译的 android14-11 内核都能兼容这批模块 | **不成立**：KMI 串一致 ≠ 符号 ABI 一致，CRC 漂移会直接导致加载失败 |

## 对自建内核的约束

1. **KMI 代号必须保持 `android14-11`**：不改变 CONFIG_LOCALVERSION 约定的 KMI 串，不改动受 KMI 保护的配置项。CONFIRMED（要求）
2. **符号 CRC 必须与 stock 一致**：构建后用 out/Module.symvers 与设备 vendor 模块的 CRC 比对（检查脚本 kmi_check/symbol_deps 已在第十三章设计中定义）。UNKNOWN：OnePlusOSS 公开源码能否重现 stock CRC（取决于源码完整性）。
3. **模块签名**：stock 强制签名检查未启用（SIG_FORCE 未启用），自建内核用自签密钥亦可装载；安全上需评估是否保持该设定。LIKELY。
4. **SUSFS 常规隐藏与 kptr_restrict**：/proc/kallsyms 地址全部置零（470,920 行），只能取符号名，不能取地址。自建内核需保留同样的 kptr 限制或明确评估。CONFIRMED。

## KMI 检查落点（与构建系统对接）
## Phase 1 硬约束（按审查意见固化）

1. 保持 `android14-11` KMI 目标，不偏离 KMI 代号与版本串约定。
2. 保留并核对厂商模块依赖的符号及 CRC：全量提取 /vendor/lib/modules 的 UND 符号与 CRC，与自建产物的 Module.symvers 逐项对比。
3. 不以 vermagic 一致作为唯一兼容性判据。
4. 必须对比自建源码构建出的符号 CRC 与 stock 内核（Module.symvers / abi_gki_aarch64.xml 途径）。
5. 禁止通过关闭 `CONFIG_MODVERSIONS` 等方式绕过问题：modversions 是兼容机制而非障碍，关闭只会让兼容性检查消失，不会让不兼容消失。

KMI 字符串一致，不等于符号 ABI 一致。此项作为 Phase 1 与 Phase 3 的验收红线。

执行框架已在 第十三章 的 `build/checks/kmi_check.sh`、`symbol_deps.sh`、`module_compat.sh` 中定义；Phase 3 首次构建时必须零失败：
- 符号依赖：设备提取的 /vendor/lib/modules 全量 UND 符号 vs 自建 Module.symvers。
- vermagic 对齐：自建内核版本串保持 `…-android14-11-o-g<sha>-lotus` 格式（否则需手动评估）。
