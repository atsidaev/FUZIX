$(call find-makefile)

map_syscall.srcs = map_syscall.c
$(call build, map_syscall, host-exe)

sdldz80.cfiles = \
        lk_readnl.c lkaomf51.c lkar.c lkarea.c lkdata.c lkelf.c lkeval.c \
        lkhead.c lklex.c lklib.c lklibr.c lklist.c lkmain.c lkmem.c \
        lknoice.c lkout.c lkrel.c lkrloc.c lkrloc3.c lks19.c lksdcclib.c \
        lksym.c sdld.c lksdcdb.c lkbank.c
sdldz80.srcs = $(addprefix bankld/, $(sdldz80.cfiles))
sdldz80.cflags = -g -O2 -Wall -Wno-parentheses -DINDEXLIB -DUNIX 
sdldz80.cflags += -IKernel/tools/bankld
$(call build, sdldz80, host-exe)

bihx.srcs = bihx.c
$(call build, bihx, host-exe)

binmunge.srcs = binmunge.c
$(call build, binmunge, host-exe)

analysemap.srcs = analysemap.c
$(call build, analysemap, host-exe)

memhogs.src = $(analysemap.result)
memhogs.extradeps = $(analysemap.result)
$(call build, memhogs, copy)
