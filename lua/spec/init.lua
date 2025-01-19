local utils = require "spec.utils"

--#region Types
--#endregion

--#region Registry

---Not sure if there's value in a global registry but this does mean a plugin
---can share it's specs if desired
---
---Currently storing as key,value pairs of string keys with function specs
---however if performance is an issue, could look at other approaches
---@type table<string, Spec.Spec>
local reg = {}

local keys = {}
local Keys = setmetatable(keys, { __index = function(key) keys[key] = math.random() end })

--#endregion

--#region Namespace

---@class Spec.NamespaceOpts
---@field testing? boolean
---@field on_key_clash? 'ignore' | 'error' | 'warn'
---@field svc? Spec.Svc # Service implementatons, defaults to neovim

---@type Spec.NamespaceOpts
local defaultNamespaceOpts = {
	on_key_clash = "error",
	testing = true,
}

---@class Spec.NamespaceStruct
---@field protected keys table<Spec.Id, Spec.Spec>
---@field protected svc Spec.Svc
---@field protected name string
---@field protected opts Spec.NamespaceOpts

---@class Spec.Namespace : Spec.NamespaceStruct
local Namespace = {}

---Validate if a spec is true
---@param spec Spec.Ref
---@param val unknown
---@return boolean
function Namespace:is_valid(spec, val)
	local ok = self:validate(spec, val)
	return ok
end

---Print an explanation of why a spec failed
---@param spec Spec.Ref
---@param val unknown
---@return string
function Namespace:explain_str(spec, val)
	local _, err = self:validate(spec, val)
	if err then
		local m = ""
		for _, e in ipairs(err.problems) do
			m = m .. e.msg
		end
		return m
	end
	return "Success\n"
end

---Print an explanation of why a spec failed
---@param spec Spec.Ref
---@param val unknown
function Namespace:explain(spec, val) print(self:explain_str(spec, val)) end

---Create a spec, useful in nested contexts
---@param predicate Spec.Predicate
function Namespace:spec(predicate)
	return predicate --[[@as Spec.Spec]]
end

---@param name Spec.Ref
---@param spec Spec.Spec
function Namespace:def(name, spec)
	local n = self:get_name(name)
	if reg[n] then
		if self.opts.on_key_clash == "warn" then self.svc.warn("clash for key " .. name) end
		if self.opts.on_key_clash == "error" then self.svc.error("clash for key " .. name) end
	end
	reg[n] = spec
end

---Create a function spec
---@param opts Spec.Function
---@param spec Spec.Ref
function Namespace:fspec(opts, spec) end

---@param specs Spec.Ref[]
---@return Spec.Spec
function Namespace:or_(specs)
	return self:spec(function(val)
		for _, spec in ipairs(specs) do
			if self:is_valid(spec, val) then return true end
		end
		return false
	end)
end

---@param specs Spec.Ref[]
---@return Spec.Spec
function Namespace:and_(specs)
	return self:spec(function(val)
		for _, spec in ipairs(specs) do
			if not self:is_valid(spec, val) then return false end
		end
		return true
	end)
end

---@param svc Spec.Svc
---@param name string
---@param opts Spec.NamespaceOpts
---@package
function Namespace.new(svc, name, opts)
	---@type Spec.NamespaceStruct
	local ns = {
		keys = Keys,
		svc = svc,
		name = name,
		opts = svc.deep_extend(defaultNamespaceOpts, opts),
	}
	return setmetatable(ns, { __index = Namespace }) --[[@as Spec.Namespace]]
end

---comment
---@param spec Spec.Ref
---@param val unknown
---@return boolean, Spec.Problems?
function Namespace:validate(spec, val)
	---@type Spec.Predicate
	local spec_obj

	if type(spec) == "string" then
		local name = spec
		local builtin = reg[name]

		if builtin then
			spec_obj = builtin --[[@as Spec.Predicate]]
		else
			name = self:get_name(spec)
			spec_obj = reg[name] --[[@as Spec.Predicate]]
		end

		if not spec_obj then error("no such spec: " .. name) end
	else
		spec_obj = spec
	end

	local ok, err = spec_obj(val)
	if ok then return ok end
	if err then return false, { problems = { { msg = err } } } end
	-- WIP
	return false, nil
end

---build up key id
---@param ... string
---@private
function Namespace:get_name(...) return table.concat({ self.name, ... }, "_") end

--#endregion

--#region Builtins

do
	---@enum (key) Spec.Builtin
	local builtins = {
		["int"] = function(val) return type(val) == "number" and (val % 1 == 0) end,
		["int?"] = function(val) return not val or type(val) == "number" and (val % 1 == 0) end,
	}

	for builtin, pred in pairs(builtins) do
		-- Keys[builtin]
		Namespace[builtin] = builtin
		reg[builtin] = pred --[[@as Spec.Spec]]
	end
end

--#endregion

--#region Namespaces

---@class Spec.Lib
local M = {}

---@type table<string, Spec.Namespace>
local namespaces = {}

---Override services used by Spec - only needed if not running in neovim, or methods need polyfilling
---@param svc Spec.Svc
function M.set_svc(svc) svc = svc end

---Create a namespace for a package's specs
---@param namespace string
---@param opts? Spec.NamespaceOpts
---@param runtime? 'nvim' | 'wez' | 'none'
---@return Spec.Namespace, Spec.Keys | Spec.KeysNvim
---@overload fun(namespace: string, opts: Spec.NamespaceOpts, runtime: 'none'): Spec.NamespaceOpts, Spec.Keys
---@overload fun(namespace: string, opts: Spec.NamespaceOpts, runtime: 'wez'): Spec.NamespaceOpts, Spec.Keys | Spec.KeysWezterm
function M.ns(namespace, opts, runtime)
	runtime = runtime or "nvim" -- default for convenience
	assert(type(namespace) == "string", "ns requires namespace string argument")

	local ns = namespaces[namespace]

	if not opts and not ns then
		error(string.format("namespace % has not been created, see %s for info", namespace, utils.help(M.ns)))
	elseif ns then
		return ns, Keys
	end

	opts = opts or {}

	local svc = opts.svc
		or runtime == "nvim" and require("spec.compat.nvim").setup(ns)
		or runtime == "wez" and require("spec.compat.wez").setup()
		or error "either choose a runtime or provide opts.svc"

	ns = Namespace.new(svc, namespace, opts)
	namespaces[namespace] = ns
	return ns, Keys
end

-- M.str = nil --[[@as Spec.Id]]
-- M.num = nil --[[@as Spec.Id]]

--#endregion

return M
