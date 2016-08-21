# On entry, $T is the target name.

define kernel-sna.rules

$1.result = $$($1.objdir)/$1-hex.ihx

$1: $$($1.result)
.PHONY: $1

$(call build, $1, kernel-ihx)

endef
