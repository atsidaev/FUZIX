# On entry, $T is the target name.

define copy.rules

$1.objdir ?= $$(OBJ)/host/$1
$1.result ?= $$($1.objdir)/$1

$1: $$($1.result)
.PHONY: $1

$$($1.result): $$($1.src) $$($1.extradeps)
	$$(hide) mkdir $$($1.objdir)
	$$(hide) cp $$($1.src) $$($1.result)

endef
