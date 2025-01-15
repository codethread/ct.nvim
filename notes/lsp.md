# lua lsp

The lsp is amazing, and the more can be pushed into static analysis, the better.

## 'Holes' in the system

### nested table fields

Using tables in fields will not be picked up correctly

```lua
---@class (exact) Struct
---@field a integer
---@field b { x: integer, b: integer }

---@param st Struct
local function sum(st) end

sum({ a = 1, b = {} }) -- 😞 no error
```

solution, define all structs

```lua
---@class NestedStruct
---@field x integer
---@field y integer

---@class (exact) Struct
---@field a integer
---@field b NestedStruct

---@param st Struct
local function sum(st) end

print(sum({ a = 1, b = {} })) -- error yay
```

### Meta methods are assumed to work

Understandably, anything on the `metatable` is assumed to work, e.g `+` or `..`, so it's easy to try it on things that don't work

```lua
---@class (exact) Struct
---@field a integer
---@field b { x: integer, b: integer }

---@param st Struct
local function sum(st)
	local t = st.a + st.b -- no error as `__add could be implemented`
	return t -- type unknown
end
```

Solution? None, tried playing with traits but it's a struggle and falls over due to lack of generics

### Interfaces don't need to be upheld

```lua
---@class Interface
---@field read fun(self, target: string): string[]
---@field write fun(self, target: string, out: string[]): boolean

---@class FileIo : Interface
local FileIo = {}
-- write isn't implemented

---@param t string
function FileIo:read(t) -- incorrect implementation
end

---@param reader Interface
local function process(reader)
	local lines = reader:read('target')
end

print(process(FileIo))
```

### Unions without discriminants are created as merged keys

```lua
---@type { str : string } | { num : number }
local union = {}
---@type { str : string? } | { num : number? }
local union_alt = {}

---@class Str
---@field s string
---@class Num
---@field n number

--- even if we really aggressively scope these types down
---@type { str? : Str, num : nil } | { num? : Num, str: nil }
local un = {}

local missing = union.str:len()
local also_missing = union_alt.str:len()
local missing = un.num.n -- lsp is very happy to charge on here
```

#### solution

Used tagged unions

```lua
---@class A
---@field _tag 'A'
---@field a string
---@class B
---@field _tag 'B'
---@field b number
---@type A | B
local conformed = nil
if conformed._tag == 'A' then
	local x = conformed.a -- narrowed
	local xy = conformed.b -- 'lsp Err! which is good!'
end
```

## generic issues (which is a WIP so this will likely change as time goes on)

### generics can't be inherited from

```lua
---@class XX<T>: { foo: T }

---@type XX<string>
local xx = {}
print(xx.foo:lower()) -- all good

---@class YY : XX<string>
local xxYY = {}

xxYY.foo -- no type
```

### generic captures don't work for functions

```lua
---@generic T
---@param type `T`
---@return T
local function _(type) end

local s = _"string"
--    ^ correctly typed as `string`

local fn = _"fun(): string"
--    ^ does not pick up function type
```

## casting and assertions

### primitives ignore `@as`

```lua
local s = "fn1" --[[@as number]]
--    ^ still a string)

-- can use parens
local n = ("fn1" --[[@as any]]) --[[@as number]]
--    ^ number
-- however stylua strips it out 🙁
```

Best workaround is an empty func

```lua
local _ = function(...)end

local fn = _ "fn1" --[[@as fun(): Foo]]
---   ^ correctly typed
```
