lua << EOF
	_G.Ct = { is_test = true }

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
