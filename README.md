# pte_track 修复版（stop_machine 安全版）

基于你给的 0902 重构版修，目标：**能编、能加载、不再 patch 到一半被别的 CPU 读到飞**。

## 改了什么（相对 0902 版）

| 问题（原 README 第六节列的嫌疑） | 本版修法 |
|---|---|
| patch `do_mem_abort` 没停 CPU，其他核正在跑该函数读到半写跳板 | **patch/unpatch 全部包在 `stop_machine` 里**，所有其他核停在 stopper 线程后才写 16 字节 |
| 写入顺序不安全（先写 br 后写地址，存在 br 到垃圾地址的窗口） | **先写跳板目标地址(p[2..3])，再写 ldr(p[0])，最后写 br(p[1])** |
| 0902 的 `kln` 赋值/检查重复了两遍 | 删掉重复 |
| 0902 `unhook_page` 用 `hooks[i].mm` 不够直观 | 改成 `h->mm = NULL` |
| `stop_machine` 找不到时带病加载 | **解析不到就拒绝 insmod**，宁可报错不要重启设备 |
| 测试程序 V4/V5 的 buf 索引算错（拿 buf[4]/buf[5] 当 V4/V5） | 改成 buf[0]=V3, buf[2]=V4, buf[4]=V5 |

保留 0902 已有的加固：`untagged_addr(far)`、`spin_lock_irqsave`、独立 `pte_stub.S`、手动 `dc cvau/ic ivau` 刷 icache。

## 文件

```
pte_core.c            驱动主源码
pte_stub.S            do_mem_abort 跳板汇编
pte_track_ioctl.h     用户态接口（HOOK/ARM/UNHOOK）
Kbuild / Makefile     构建
test_pte.c            用户态自测
insmod_pte.sh         设备上一键加载脚本
```

## 编译（在你的编译机上，KDIR 指向 5.10.209 内核源码树）

```sh
cd pte_track_fixed
make            # 默认 KDIR=/workspace/kernel/src
# 或指定：
make KDIR=/path/to/kernel/src CROSS_COMPILE=aarch64-linux-gnu-
```

产物：`pte_track.ko`

## 加载（设备上，需 root/KernelSU）

```sh
# 把 pte_track.ko 和 insmod_pte.sh 推到设备同目录
sh insmod_pte.sh
```

脚本会自动从 `/proc/kallsyms` 取 `kallsyms_lookup_name` 地址并 insmod，
同时打印 `do_mem_abort` / `stop_machine` 地址供核对。
成功后应有 `/dev/pte_track`，dmesg 里看到 `stop_machine patching do_mem_abort` 和 `/dev/pte_track ready`。

## 自测（设备上）

```sh
# 编译 test_pte（在设备或 NDK 里）：
aarch64-linux-android-clang -O2 -o test_pte test_pte.c
./test_pte
```

看到 `=== ALL PASS ===` 就说明：置 UXN 触发 IABT → hook 命中 → 清 UXN → 写 V3/V4/V5 → 正常重试，整条 PTE 链路通了。

## 卸载

```sh
rmmod pte_track
```

## 仍然没做 / 注意

- 我这边没有 5.10.209 内核源码树，**没能实机跑 make**；你第一次编译如果报符号/版本问题，把报错贴回来。
- `stop_machine` 必须能从 kallsyms 找到；极少数 GKI 配置可能不导出，脚本里会先打印 `stop_machine` 地址，空了会拒载。
- 游戏内联调和 40–50ms 周期 ARM 重新武装，等这个稳定加载、test_pte 全过后再上。
