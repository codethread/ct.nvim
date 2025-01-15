# Goal is to make Lua nicer to write

My personal taste of 'nice':

1. As much as possible in the type system
2. Push the rest into 'init' time - i.e validation functions that run when requiring a module
3. Assert what is left at runtime

> heavily inspired by:
>
> - https://zod.dev/?id=primitives
> - https://clojure.org/guides/spec

## Types

Types are great, and `rust` + `typescript` have great systems here - however lua is not either of those languages, and neither should it be. Both are actually available either via ffi or typescript-to-lua respectively. The goal here is not to turn lua into those langs, but instead bring some nice ergonomics to lua. I also want to make good typing easy to write (footguns are being captured in [lsp](./lsp.md))

Generics are still a WIP, so while we wait, we can actually take inspiration from `go` and just generate types from builders.

Generated types should be:

1. easy to read
1. easy to sync and update with the automated tooling
1. be as concrete as possible to help readability and LSP

## Spec

[Spec](https://clojure.org/guides/spec) allows runtime safely to functions and data in clojure

## Builders

Creating functions, data and classes is error prone - contracts are not all that well upheld by the LSP (at this time). Classes with inheritance are similarly a little confusing to type and easy to implement incorrectly (but they do provide the best LSP experience once built).

Current thinking is builders like:

```lua
local A = class {

}
```

## macros

Would be nice to combine the above to write the builders with "macros", could use a super simple dialect or could inject a language like rust or nushell - not the actual lang, just the syntax for closures, because both are very consise. E.g here's a nice rust one liner

```lua
---@type ct.is_big -- @alias ct.is_big fun<...> is magically created elsewhere
local is_big = def'|n| n > 10'
-->>  is_big = function (n) return n > 10 end
assert(is_big(11) == true)
assert(is_big(3) == false)

-- would be nice for inline stuff too
vim.iter(blah)
	:filter(def'|a| a > 10}')
	:map(def'|a,b| table { a, b: a + b }')
	:totable()


```

### Language experiments

Trying to find which language offers nice short syntax, and flexibility. Needs:

- closure syntax
- type only
- arg and return types
- list returns
- table returns
- vararg?
- ideally all parts are optional

Considered

- nu: has a parser, but syntax doesn't support custom types, might still work
- rust: nice syntax but anonymous return table is hard, would need to use tuples, generics or leave out
- tree sitter query: concise and builtin to neovim release

#### rust

Flexible but clunky around tables and lists

```rust
// semi colon only needed for new lines
let simple       = |i| i + 3;
let typed        = |i: number| -> number { i + 3 };
let typed_only   = |i: number| -> number {};
let typed_arg    = |i: number| i + 3 ;
let typed_return = |i| -> number { i + 3 };
let multi_return = |i| -> (string, number) { (i, tonumber(i)) }; // tuple syntax
let vararg       = |..:number| -> string {}; // 🤮
let table_return = |a, b| table { a, b, c: a + b }; // need a struct to return, so could use lowercase for builtin and uppercase for types
let table_type   = |a: Table, b: Table<string, number>| -> Table<string, User> {};
let table_list   = |a: number| -> Arr<number> {};
```

#### nu

Just falls to bits at complex types (because these aren't yet native to nushell)

```nu
let simple       = { |i| $i + 3 }
let typed        = { |i: number -> number| $i + 3 } # this isn't 'correct' nu syntax, but it is valid 😂
let typed_only   = { |i: number -> number| () } # needs something in the body, `()` is open for alternatives
let typed_arg    = { |i: number| $i + 3  }
let typed_return = { |i -> number| { $i + 3 } }
let multi_return = { |i -> string, number| { $i + (tonumber 3) } }
let vararg       = { |...n:number, -> string| $n }
let table_return = { |a, b| { a: $a b: $b c: ($a + $b) } };
def table_list [a: table, b: list<string]: nothing -> list<number> {};
let table_list   = { |a: number, -> list<number> {} }
```

#### query

Built in, but kind of sucky

```query
(simple) is: (fn i: _ (#impl! add i 3))
(typed ) is: (fn i: (number)? (#ret? number))
```
