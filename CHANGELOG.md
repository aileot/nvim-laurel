# Changelog

## [0.5.0](https://github.com/aileot/nvim-laurel/compare/v0.4.1...v0.5.0) (2022-12-13)


### ⚠ BREAKING CHANGES

* **keymap:** `map!` sets keymap non-recursively by default; `map!` requires `remap` option to set recursive mapping

### Code Refactoring

* **keymap:** make `map!` macro non-recursively by default ([#144](https://github.com/aileot/nvim-laurel/issues/144)) ([d086443](https://github.com/aileot/nvim-laurel/commit/d0864431dee8bbaf460b1ae0ba752e9373fcf9be))
