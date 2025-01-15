local utils = require "spec.utils"

--#region Types
---A Spec is predicate function built from other specs
---@alias Spec.Spec '__Spec'

---A spec predicate must be a unary function
---@alias Spec.Predicate fun(val: unknown): boolean

---A reference to a spec, can be the spec itself or it's id
---@alias Spec.Ref
---| Spec.Spec
---| Spec.Id

---@class Spec.Function
---@field args Spec.Ref[]
---@field ret? Spec.Ref[]
---@field fn? Spec.Ref[]

---@class Spec.Validation
---@field path string # fully qualified path to spec
---@field id string # spec name that failed
---@field input any # value that failed
--#endregion

--#region Registry

---Not sure if there's value in a global registry but this does mean a plugin
---can share it's specs if desired
---
---Currently storing as key,value pairs of string keys with function specs
---however if performance is an issue, could look at other approaches
---@type table<string, Spec.Spec>
local reg = {}

--#endregion

--#region Namespace

---@class Spec.NamespaceOpts
---@field testing? boolean
---@field on_key_clash? 'ignore' | 'error' | 'warn'

---@type Spec.NamespaceOpts
local defaultNamespaceOpts = {
	on_key_clash = "error",
	testing = true,
}

---@class Spec.NamespaceStruct
---@field protected svc Spec.Svs
---@field protected name string
---@field protected opts Spec.NamespaceOpts

---@class Spec.Namespace : Spec.NamespaceStruct
local Namespace = {}

---Validate if a spec is true
---@param spec Spec.Ref
---@param val unknown
---@return boolean
function Namespace:is_valid(spec, val)
	local validations = self:validate(spec, val)
	return #validations == 0
end

---Print an explanation of why a spec failed
---@overload fun(self, spec: Spec.Ref, val: unknown): nil
---@overload fun(self, spec: Spec.Ref, val: unknown, opts: { str: boolean }): string
function Namespace:explain(spec, val, opts)
	opts = opts or {}
	local validations = self:validate(spec, val)
	if opts.str then
		return #validations == 0 and "Success\n" or "oh dear!"
	else
		print(validations)
	end
end

---Create a spec, useful in nested contexts
---@param predicate Spec.Predicate
function Namespace:spec(predicate)
	return predicate --[[@as Spec.Spec]]
end

---@param name string
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

---@param svc Spec.Svs
---@param name string
---@param opts Spec.NamespaceOpts
---@package
function Namespace.new(svc, name, opts)
	---@type Spec.NamespaceStruct
	local ns = {
		svc = svc,
		name = name,
		opts = svc.deep_extend(defaultNamespaceOpts, opts),
	}
	return setmetatable(ns, { __index = Namespace }) --[[@as Spec.Namespace]]
end

---comment
---@param spec Spec.Ref
---@param val unknown
---@return Spec.Validation[]
function Namespace:validate(spec, val)
	---@type Spec.Spec
	local spec_obj

	if type(spec) == "string" then
		local name = spec
		local builtin = reg[name]

		if builtin then
			spec_obj = builtin
		else
			name = self:get_name(spec)
			spec_obj = reg[name]
		end

		if not spec_obj then error("no such spec: " .. name) end
	else
		spec_obj = spec
	end

	-- WIP, just return rsult for now, not a validatio
	if spec_obj(val) then
		return {}
	else
		return { "oh dear!" }
	end
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
		Namespace[builtin] = builtin
		reg[builtin] = pred --[[@as Spec.Spec]]
	end
end

--#endregion

--#region Namespaces
local M = {}

---@type table<string, Spec.Namespace>
local namespaces = {}

---@class Spec.Svs
local _svc = {
	deep_extend = function(...) return vim.tbl_deep_extend("force", ...) end,
	---@param msg string
	warn = function(msg) vim.notify(msg, vim.log.levels.WARN) end,
	---@param msg string
	error = function(msg) error(msg) end,
}

---Override services used by Spec - only needed if not running in neovim, or methods need polyfilling
---@param svc Spec.Svs
function M.set_svc(svc) svc = svc end

---Create a namespace for a package's specs
---@param namespace string
---@param opts? Spec.NamespaceOpts
---@return Spec.Namespace
function M.ns(namespace, opts)
	assert(type(namespace) == "string", "ns requires namespace string argument")

	local ns = namespaces[namespace]
	if opts then
		ns = Namespace.new(_svc, namespace, opts)
		namespaces[namespace] = ns
	end

	if ns then return ns end

	error(string.format("namespace % has not been created, see %s for info", namespace, utils.help(M.ns)))
end
--#endregion

return M
