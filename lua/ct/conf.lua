local M = {}

---@class ct.UserConfig
---@field macro_key? string String identifier for transforms in luadocs [default @macro]

---@type ct.Config
local default_config = {
	macro_key = "@macro",
}

---comment
---@param config ct.UserConfig
---@return ct.Config
function M.new(config)
	return vim.tbl_deep_extend("force", default_config, config)
end

return M

---@macro _.fn.required(`ct.UserConfig`,`ct.Config`)
