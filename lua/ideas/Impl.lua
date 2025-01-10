---## Implementation builders
---
---these create factories for runtime data structures. Most will often be built out of `Spec` values
---@class SpecImpls
local Impl = {}

do -- Impl
	---@class SpecClassData : SpecDetails
	---@field visibility? 'private' | 'public' | 'protected'

	---@class SpecClass
	---@field doc? string
	---@field super? any # do i want to add inheritance?
	---@field data? table<string, SpecClassData>
	---@field implements "__Spec.interface"[]

	---Create a 'class' object with data and behaviour
	---@param spec SpecClass
	---@return any
	function Impl:class(spec)
		return Todo()
	end

	---@class SpecStruct
	---@field name string
	---@field doc? string
	---@field data SpecRecord
	---@field runtime_check? boolean # could make it this is off, but can be enabled for external API, e.g user config

	---Create a table of pure data
	---if needing behaviour, use `class`
	---@param spec SpecStruct
	---@return any
	function Impl.struct(spec)
		return Todo()
	end

	---Create an implementation of a function, intended for creating runtime
	---validated function
	---@return SpecFunctionImpl
	---@generic Fn
	---@param spec SpecFunction
	---@param impl `Fn`
	---@return Fn
	function Impl.fn(spec, impl)
		return Todo()
	end
end

return Impl
