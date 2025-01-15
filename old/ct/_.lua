local M = {}

---The macro expansion context, this will contain all sorts of goodies
---@class ct.Global
---@field types? ct.TypeLookup
---@field macro_cache? table<string, ct.Macro> Cache of evaled macro strings, not their contents, saves calling `luastring` if the macro has not changed

---A macro is a function that will take in the Global type and produce a Transform
---@class ct.Macro
---@field run fun(_:ct.Global): ct.Transform

return M
