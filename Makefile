SPEC=

RUN=nvim --headless --noplugin -u test/spec.vim

.PHONY: all nvim test watch install

install:
	mkdir -p test/vendor
	# luarocks install luacheck --local
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ./test/vendor/plenary.nvim
	git clone --depth 1 https://github.com/LuaCATS/luassert.git ./test/vendor/luassert
	# git clone --depth 1 https://github.com/m00qek/matcher_combinators.lua ./test/vendor/matcher_combinators

nvim:
	@nvim --noplugin -u test/spec.vim

test:
	@$(RUN) -c "PlenaryBustedDirectory test/spec/ {minimal_init = 'test/spec.vim'}"

types:
	@nvim -l test/types.lua --skip-tests=true

format:
	@stylua --glob '**/*.lua' lua

format-check:
	@stylua --check --glob '**/*.lua' lua

all: install format-check test types

