# AGENTS.md

## Frozen: `fnl/nvim-laurel/` and `test/nvim-laurel-*`

The `nvim-laurel` alias module (`fnl/nvim-laurel/macros.fnl`) and its
dedicated specs (`test/nvim-laurel-*`) are deprecated, kept only for backward
compatibility, and scheduled for removal in v0.8.0. Do not update them; fix
bugs only in `fnl/laurel/` and the non-`nvim-laurel` specs.

## Testing

Run `make test` (compiles `test/*_spec.fnl` to Lua, then runs `vusted`).
The compiled `*_spec.lua` files are git-ignored; `make clean` removes them.
