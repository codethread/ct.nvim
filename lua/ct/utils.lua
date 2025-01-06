local M = {}

---comment
---@param msg string
---@param ... string | number
M.warn = function(msg, ...)
	vim.notify(string.format(msg, ...), vim.log.levels.WARN)
end

---@param str string
---@param substring string
---@return boolean
function M.string_includes(str, substring)
	return str:find(substring, 1, true) ~= nil
end

return M
