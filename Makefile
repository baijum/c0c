KAAPPI ?= kaappi
KAAPPI_DIR ?= ../kaappi

.PHONY: all clean gen-embed test

all: c0c-standalone

gen-embed: lib/c0c/runtime-embed.sld

lib/c0c/runtime-embed.sld: runtime/c0rt.h runtime/c0rt.c scripts/gen-runtime-embed.scm
	$(KAAPPI) scripts/gen-runtime-embed.scm

c0c.sbc: c0c.scm lib/c0c/runtime-embed.sld $(wildcard lib/c0c/*.sld)
	$(KAAPPI) --lib-path lib --compile c0c.scm -o c0c.sbc

c0c-standalone: c0c.sbc
	cd $(KAAPPI_DIR) && zig build -Dbundle="$(CURDIR)/c0c.sbc" -Doptimize=ReleaseSafe -Dgc-threshold=20000
	cp $(KAAPPI_DIR)/zig-out/bin/kaappi $@
	cd $(KAAPPI_DIR) && zig build
	@echo "Built standalone binary: $@"

test:
	bash tests/run-tests.sh

test-standalone: c0c-standalone
	C0C=./c0c-standalone bash tests/run-tests.sh

clean:
	rm -f c0c.sbc c0c-standalone
