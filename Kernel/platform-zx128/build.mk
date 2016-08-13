$(call find-makefile)


kernelversion.ext = c
kernelversion.srcs = $(abspath $(TOP)/Kernel/makeversion)
$(call build, kernelversion, nop)
$(kernelversion.result):
	@echo MAKEVERSION $@
	$(hide) mkdir -p $(dir $@)
	$(hide) (cd $(dir $@) && $(kernelversion.abssrcs) $(VERSION) $(SUBVERSION))
	$(hide) mv $(dir $@)/version.c $@

syscallmap.ext = h
# Do not change the order below without updating main.c.
syscallmap.srcs = \
	../syscall_exec16.c \
	../syscall_fs.c \
	../syscall_fs2.c \
	../syscall_fs3.c \
	../syscall_other.c \
	../syscall_proc.c
$(call build, syscallmap, nop)
$(syscallmap.result): $(map_syscall.result)
	@echo SYSCALLMAP $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(map_syscall.result) $(syscallmap.abssrcs) > $@
	
$(TOP)/Kernel/platform-zx128/main.c: $(syscallmap.result)

kernel.srcs = \
	commonmem.s \
	../dev/blkdev.c \
	../dev/mbr.c \
	../devio.c \
	../devsys.c \
	../filesys.c \
	../inode.c \
	../lowlevel-z80-banked.s \
	../usermem_std-z80-banked.s \
	../kdata.c \
	../mm.c \
	../process.c \
	../simple.c \
	../start.c \
	../swap.c \
	../syscall_exec16.c \
	../syscall_fs.c \
	../syscall_fs2.c \
	../syscall_fs3.c \
	../syscall_other.c \
	../syscall_proc.c \
	../timer.c \
	../tty.c \
	../vt.c \
	../usermem.c \
	../font8x8.c \
	crt0.s \
	zx128.s \
	zxvideo.s \
	devices.c \
	devmdv.c \
	devfd.c \
	disciple.s \
	../dev/devide.c \
	../dev/devide_discard.c \
	devtty.c \
	main.c \
	tricks.s \
	microdrive.s \
	bank128.c \
	betadisk.c \
	betadisk_internal.s \
	$(kernelversion.result)

kernel.includes += \
	-I$(dir $(syscallmap.result)) \
	-I/home/nord/FUZIX_clean/Kernel/cpu-z80 \
	-I/home/nord/FUZIX_clean/Kernel/platform-zx128 \
	-I/home/nord/FUZIX_clean/Kernel/include \
	-I../dev/

kernel.cflags += \
	--no-std-crt0 \
	--max-allocs-per-node 30000 \
	--Werror \
	--stack-auto \
	--constseg CONST \
	--external-banker \
	--codeseg CODE3


kernel.asflags += \
	-g \

kernel.ldflags += \
	--relax \
	-s 
	
kernel.result = $(TOP)/kernel-$(PLATFORM).ihx
$(call build, kernel, kernel-ihx)
