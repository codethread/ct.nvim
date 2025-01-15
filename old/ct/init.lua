local M = {}

---buffer text => parsed tree => transforms => write
---@param bufn number
function M.run_for_buffer(bufn)
	---@type ct.Global
	_G.Ct = {} -- XXX: needs something better
	local transformers = require("ct.transformers")
	local conf = require("ct.conf")
	local file_parser = require("ct.parser")

	local b = bufn or vim.api.nvim_get_current_buf()
	local config = conf.new {}
	local parsed = file_parser.parse(config, b)
	local transforms = transformers.run(config, parsed)
	for _, transform in ipairs(transforms) do
		transform:write {}
	end
end

function M.setup() end

return M
