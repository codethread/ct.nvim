set rtp^=./test/vendor/plenary.nvim/

" adjust per machine
set rtp^=~/.local/share/nvim/lazy/nvim-treesitter
" CI
set rtp^=~/.local/share/nvim/site/pack/vendor/start/nvim-treesitter
set rtp^=./

runtime plugin/plenary.vim

lua require('plenary.busted')

" runtime plugin/qmk.lua

lua << EOF
	-- -- not sure where this has gone XXX
	if table.pack == nil then
		function table.pack(...)
			return { n = select("#", ...), ... }
		end
	end

	if table.unpack == nil then
		table.unpack = unpack
	end
EOF
