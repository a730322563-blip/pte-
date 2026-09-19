# 用 GKI 内核源码树编译外部模块
# KDIR 指向与设备内核匹配的源码树（5.10.209-android12-9）
KDIR ?= /workspace/kernel/src
ARCH ?= arm64
CROSS_COMPILE ?=

obj-m := pte_track.o
pte_track-objs := pte_core.o pte_stub.o

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) LLVM=1 LLVM_IAS=1 modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) ARCH=$(ARCH) clean

help:
	@echo "编译: make            （默认 KDIR=/workspace/kernel/src）"
	@echo "交叉: make CROSS_COMPILE=aarch64-linux-gnu-"
