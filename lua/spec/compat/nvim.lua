local M = {}

local is = {}

function is.is_buf(val) return type(val) == "number" end

---@class Spec.Svc
local svc = {
	deep_extend = function(...) return vim.tbl_deep_extend("force", ...) end,
	---@param msg string
	warn = function(msg) vim.notify(msg, vim.log.levels.WARN) end,
	---@param msg string
	error = function(msg) error(msg) end,
}

---@param ns Spec.Namespace
function M.setup(ns)
	if not vim then error "nvim chosen as runtime, but `vim` global not available" end
	for key, pred in pairs(is) do
	end
	return svc
end

---@class Spec.KeysNvim
---@field in_nvim Spec.Spec # Checks if currently running inside nvim
---@field buf Spec.Spec # Is this a valid buffer id
---@field win Spec.Spec # Is this a valid window id

return M
