SPEC=

RUN=nvim --headless --noplugin -u test/spec.vim

.PHONY: all nvim test watch prepare

prepare:
	@echo "nothing to do"

nvim:
	@nvim --noplugin -u test/spec.vim

test:
	@echo "nothing to do yet"

types:
	@nvim -l test/types.lua --skip-tests=true

format:
	@stylua --glob '**/*.lua' lua

format-check:
	@stylua --check --glob '**/*.lua' lua

all: prepare format-check test types

