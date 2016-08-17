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
	--external-banker

kernel.ldflags += \
	-b _COMMONDATA=0x4000 \
	-b _CODE=0xC000 \
	-b _CODE2=0xC000 \
	-b _CODE3=0xDB00 \
	-b _DISCARD=0x8000

# $1 is segment variable, $2 is segment name, $3 is section for CONST data (default value is CONST)
define_segment = \
	$(eval $1.name = $2) \
	$(eval $1.includes = $(kernel.includes)) \
	$(eval $1.cflags = $(kernel.cflags) --codeseg $2 --constseg $3) \
	$(eval $1.asflags = $(kernel.asflags))

# CODE1
segment1.srcs = \
	$(kernelversion.result) \
	../filesys.c \
	../devio.c \
	../kdata.c \
	../tty.c \
	../inode.c

# CODE2
segment2.srcs = \
	../process.c \
	../simple.c \
	bank128.c \
	$(syscallmap.srcs)

# CODE3
segment3.srcs = \
	commonmem.s \
	../dev/devide.c \
	../dev/mbr.c \
	../devsys.c \
	../lowlevel-z80-banked.s \
	../usermem_std-z80-banked.s \
	../mm.c \
	../swap.c \
	../timer.c \
	../vt.c \
	../usermem.c \
	../font8x8.c \
	zx128.s \
	zxvideo.s \
	devices.c \
	devmdv.c \
	devfd.c \
	disciple.s \
	devtty.c \
	main.c \
	tricks.s \
	microdrive.s \
	betadisk.c \
	betadisk_internal.s \
	../dev/blkdev.c

# DISCARD
segment4.srcs = \
	../start.c \
	../dev/devide_discard.c

$(call define_segment, segment1, CODE, CONST)
$(call define_segment, segment2, CODE2, CONST)
$(call define_segment, segment3, CODE3, CONST)
$(call define_segment, segment4, DISCARD, DISCARD)

$(call build, segment1, kernel-rel)
$(call build, segment2, kernel-rel)
$(call build, segment3, kernel-rel)
$(call build, segment4, kernel-rel)

kernel.srcs = \
	crt0.s

kernel.extradeps = \
	$(segment1.result) \
	$(segment2.result) \
	$(segment3.result) \
	$(segment4.result)
	
kernel.result = $(OBJ)/$(PLATFORM)/Kernel/kernel-$(PLATFORM).ihx
$(call build, kernel, kernel-ihx)

SNA=$(kernel.result:.ihx=.sna)
HOGS=$(kernel.result:.ihx=.hogs)

kernel.sna: $(SNA)
$(SNA): $(kernel.result)
	$(TOP)/Kernel/tools/memhogs < $(kernel.result:.ihx=.map) |sort -nr > $(HOGS)
	head -5 $(HOGS)
	(cd $(OBJ)/$(PLATFORM)/Kernel; $(abspath $(TOP)/Kernel/tools/bihx $(kernel.result)))
	-(cd $(OBJ)/$(PLATFORM)/Kernel; ln -s kernel-$(PLATFORM).map fuzix.map)
	(cd $(OBJ)/$(PLATFORM)/Kernel; $(abspath $(TOP)/Kernel/tools/binprep $(kernel.result)))
	(cd $(OBJ)/$(PLATFORM)/Kernel; $(abspath $(TOP)/Kernel/tools/bin2sna $(kernel.result:.ihx=.sna)))
