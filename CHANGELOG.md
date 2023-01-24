# Changelog

## [0.5.2](https://github.com/aileot/nvim-laurel/compare/v0.5.1...v0.5.2) (2023-01-24)


### Features

* **autocmd:** make `augroup!` accept `api-opts`; deprecate `augroup+` ([#178](https://github.com/aileot/nvim-laurel/issues/178)) ([1546d9b](https://github.com/aileot/nvim-laurel/commit/1546d9b3c0064ae1ec560b0d5d7168d7cc8ca1ba))

## [0.5.1](https://github.com/aileot/nvim-laurel/compare/v0.5.0...v0.5.1) (2022-12-20)


### Features

* extract callback in `quote`d symbol/list; deprecate callback in symbol ([#150](https://github.com/aileot/nvim-laurel/issues/150)) ([98f0dcd](https://github.com/aileot/nvim-laurel/commit/98f0dcdf07c9c762e3d7796bfbbc5c938ad1c0f3))

## [0.5.0](https://github.com/aileot/nvim-laurel/compare/v0.4.1...v0.5.0) (2022-12-13)


### ⚠ BREAKING CHANGES

* **keymap:** `map!` sets keymap non-recursively by default; `map!` requires `remap` option to set recursive mapping

### Code Refactoring

* **keymap:** make `map!` macro non-recursively by default, and deprecate its wrappers and `noremap!` ([#144](https://github.com/aileot/nvim-laurel/issues/144)) ([d086443](https://github.com/aileot/nvim-laurel/commit/d0864431dee8bbaf460b1ae0ba752e9373fcf9be))
