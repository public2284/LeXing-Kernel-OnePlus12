# PARTITION_LAYOUT — OnePlus 12 分区布局

Phase 0 只读调查产出。全部来自只读读取（`ls /dev/block/by-name`、`/sys/block/*/size`、`blockdev --getsize64`、mountinfo）。

## 磁盘结构

- 主盘 /dev/block/sda，UFS，1,989,976,064 扇区 ×512 ≈ 1019 GB。CONFIRMED
- A/B 双槽分区成对存在（`*_a` / `*_b`），活动槽 `_b`。CONFIRMED
- super = sda13（16 GiB，33554432 扇区），userdata = sda14（1,955,629,176 扇区 ≈ 933 GiB，f2fs）。CONFIRMED

## 关键分区尺寸（字节）

| 分区 | 尺寸 | 备注 |
|---|---|---|
| boot_a/b | 201,326,592 | 192 MiB，含 GKI kernel + ramdisk |
| init_boot_a/b | 8,388,608 | 8 MiB（Android 13+ 通用 ramdisk） |
| dtbo_a/b | 25,165,824 | 24 MiB |
| vendor_boot_a/b | 201,326,592 | 192 MiB（vendor ramdisk + dlkm 加载者） |
| vbmeta_a/b | 65,536 | 64 KiB |
| super | 16 GiB | 动态分区容器 |

CONFIRMED（root shell blockdev 读取）

## super 内动态分区（dm 设备）

已挂载的逻辑分区：system(dm-30)、system_ext(dm-31)、product(dm-32)、vendor(dm-33)、vendor_dlkm(dm-34)、system_dlkm(dm-35)、odm(dm-36)、my_product/my_*系列、oplusreserve（sdf3）。CONFIRMED（mount 输出）。

- vendor_dlkm 仅 46 MiB（439 个 .ko 所在分区）；system_dlkm 14 MiB。CONFIRMED
- A/B OTA 分区清单（getprop ab_ota_partitions）：abl、aop、boot、cpucp、cpucp_dtb、dtbo、init_boot、keymaster、modem、shrm、tz、uefivbmeta*、vendor、vendor_boot、vendor_dlkm 等 50+ 个。CONFIRMED

## 刷写含义（Phase 3+ 预研，本次不刷）

- AnyKernel3 途径仅需写入 boot（kernel）与指定 ramdisk 补丁；dtbo/vendor_boot 动作需在安装器设计中明确。LIKELY（待安装器设计阶段确认）
- dm-verity 全分区启用，且 root_digest 已记录（若后续 fastboot 解锁重刷可能改变）。CONFIRMED（分区 verified=2 属性）
- userdata f2fs，fsck 路径 dm-85。CONFIRMED

遗留：super 内部分区表的精确偏移未提取（可用 `lptools` 或 fastboot getvar 获取）→ UNKNOWN，Phase 0 不需要。
