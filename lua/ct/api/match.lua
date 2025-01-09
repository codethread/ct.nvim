local M = {}

local function with(key, fn) end

---comment
---@param key string
---@return any
function M.new(key) end

---somehow @as is generated::
local match = require("ct.api.match").new("ct.TypeComment") --[[@as fun(union: ct.Type): ct.Match_TypeComment]]

return M
