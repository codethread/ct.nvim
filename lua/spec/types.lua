---@meta _

---A Spec is predicate function built from other specs, you should use a Spec builder to create this
--- NOTE:
--- I strongly suspect this will become some kind of serialisable data structure, see `Spec.ISpec`
---
---@alias Spec.Spec '__Spec'

---A Key symbol used to reference other specs, accessed via the namespaced `k` value
---```lua
---local s, k = spec.ns("my namespace")
---s:def(k.answer, s:spec(function (input) return input == 42 end))
---```
---@alias Spec.Key '__Key'

---A spec predicate must be a unary function that returns an optional error message in the event of a failure
---@alias Spec.Predicate fun(val: unknown): boolean, string?

---Spec Keys allow referring to other specs.
---
---When accessing a new key, it will be created.
---
---Keys can be added to intelisense by extending `Spec.Keys`
---```lua
------@class Spec.Keys
------@field my_field Spec.Key
---
---k.my_ -- will provide completion
---```
---@class Spec.Keys
---@field int Spec.Key
---@field num Spec.Key
---@field [string] Spec.Key

---A reference to a spec, can be the spec itself or its Key
---@alias Spec.Ref
---| Spec.Spec
---| Spec.Key

---@class Spec.Function
---@field args Spec.Ref[]
---@field ret? Spec.Ref[]
---@field fn? Spec.Ref[]

---@class Spec.Problems
---@field problems Spec.Problem[]
---@field value any
---@field spec Spec.Spec

---@class Spec.Problem
---@field msg? string
---@field path string
---@field pred string
---@field val any
---@field in any

---@class Spec.ISpec
---@field name string

---@class Spec.ISpecPrimitive : Spec.ISpec
---@field predicate fun(val): boolean
---@field err_msg string|fun(val): string
---@field gen fun(): any
