# Changelog

## [0.7.0](https://github.com/aileot/nvim-laurel/compare/v0.6.2...v0.7.0) (2024-04-14)


### ⚠ BREAKING CHANGES

* **module:** The module prefix `nvim-laurel` is renamed to `laurel` following the nvim community convention.
* **option:** The previously deprecated macros (`set+`, `set^`, `set-`, `setlocal+`, `setlocal^`, `setlocal-`, `setglobal+`, `setglobal^`, `setglobal-`, `go+`, `go^`, `go-`) have been removed according to the "less" design principle of this project. Please make your own wrappers if you still need them: some sample snippets are available in [Cookbook](https://github.com/aileot/nvim-laurel/blob/main/COOKBOOK.md)
* **autocmd:** `autocmd` macros now interpret the symbol `*` at `pattern` position as an alias of `[:*]`. Since the symbol `*` is too unlikely to be overridden, this change is applied without deprecation notice.

### Features

* **autocmd:** make `au!`/`autocmd!` macro interpret the symbol `*` in pattern as an alias of `["*"]` ([#254](https://github.com/aileot/nvim-laurel/issues/254)) ([8b7b6da](https://github.com/aileot/nvim-laurel/commit/8b7b6da6341780fe5d6fae2f98630dc6963f0b36))


### Code Refactoring

* **module:** rename module `nvim-laurel` to `laurel` ([#266](https://github.com/aileot/nvim-laurel/issues/266)) ([fad4d55](https://github.com/aileot/nvim-laurel/commit/fad4d55332dd45242aec9bd1b060ef434c8a7e62))
* **option:** remove deprecated macros `set+`, `set-`, ... ([#273](https://github.com/aileot/nvim-laurel/issues/273)) ([95e8070](https://github.com/aileot/nvim-laurel/commit/95e8070f3d224e538a9f6fbcb5d924a4529e4154))

## [0.6.2](https://github.com/aileot/nvim-laurel/compare/v0.6.1...v0.6.2) (2024-04-07)


### Features

* **autocmd:** accept `buffer` with no next value in `extra-opts` to set it to `0` ([#268](https://github.com/aileot/nvim-laurel/issues/268)) ([4b4a82d](https://github.com/aileot/nvim-laurel/commit/4b4a82dcb6d1fc780cb18f2fa8c5ec1795066bb0))
* **command:** accept `buffer` with no next value in `extra-opts` to set it to `0` ([#268](https://github.com/aileot/nvim-laurel/issues/268)) ([4b4a82d](https://github.com/aileot/nvim-laurel/commit/4b4a82dcb6d1fc780cb18f2fa8c5ec1795066bb0))
* **keymap:** accept `buffer` with no next value in `extra-opts` to set it to `0` ([#268](https://github.com/aileot/nvim-laurel/issues/268)) ([4b4a82d](https://github.com/aileot/nvim-laurel/commit/4b4a82dcb6d1fc780cb18f2fa8c5ec1795066bb0))
* **keymap:** add extra-opt `wait` against `nowait` ([#264](https://github.com/aileot/nvim-laurel/issues/264)) ([528d8ae](https://github.com/aileot/nvim-laurel/commit/528d8ae45c061431275645bcd61aa3ea6be5d996))
* **option:** add `let!` macro as a superset of `opt`, `opt_local`, `opt_global`, `bo!`, `wo!`, ... ([#253](https://github.com/aileot/nvim-laurel/issues/253)) ([e737141](https://github.com/aileot/nvim-laurel/commit/e737141bf6c35eeec6f40d0dd0c29652a42bd977))


### Bug Fixes

* **command:** accept `:count` and `:range` without value to set default option value  ([#267](https://github.com/aileot/nvim-laurel/issues/267)) ([949686a](https://github.com/aileot/nvim-laurel/commit/949686ab3bac18e410ba2bd4cd45215e0ebf8ae5))

## [0.6.1](https://github.com/aileot/nvim-laurel/compare/v0.6.0...v0.6.1) (2024-03-16)


### Features

* **autocmd**: add option `&default-opts` ([#227](https://github.com/aileot/nvim-laurel/issues/227)) ([bc019ed](https://github.com/aileot/nvim-laurel/commit/bc019edcf3bf69339ced1214ed0a43c4b9219ff1))
* **command**: add option `&default-opts` ([#227](https://github.com/aileot/nvim-laurel/issues/227)) ([bc019ed](https://github.com/aileot/nvim-laurel/commit/bc019edcf3bf69339ced1214ed0a43c4b9219ff1))
* **keymap**: add option `&default-opts` ([#227](https://github.com/aileot/nvim-laurel/issues/227)) ([bc019ed](https://github.com/aileot/nvim-laurel/commit/bc019edcf3bf69339ced1214ed0a43c4b9219ff1))
* **highlight**: add option `&default-opts` ([#227](https://github.com/aileot/nvim-laurel/issues/227)) ([bc019ed](https://github.com/aileot/nvim-laurel/commit/bc019edcf3bf69339ced1214ed0a43c4b9219ff1))
* **option:** detect infix flag in symbol to append, prepend, ...; deprecate `:foo+`, ..., format and `set+`, ..., macros ([#233](https://github.com/aileot/nvim-laurel/issues/233)) ([669bdf4](https://github.com/aileot/nvim-laurel/commit/669bdf4ed5d4503f3eb40f28024f2ebbaa4547df))


### Bug Fixes

* **keymap:** correct docstring of `map!` macro ([#244](https://github.com/aileot/nvim-laurel/issues/244)) ([b982180](https://github.com/aileot/nvim-laurel/commit/b982180a285b001fd5324c739b6be7b72e28988a))

## [0.6.0](https://github.com/aileot/nvim-laurel/compare/v0.5.6...v0.6.0) (2023-02-11)


### ⚠ BREAKING CHANGES

* `command!` drops support to resolve unnecessary quote on callback
* `map!` no longer resolves quoted callback in itself.
* `map!` no longer accept special options `<command>`, `ex`, `<callback>`, and `cb`.
* `map!` no longer interpret callback of which the first symbol matches `^<.+>` as Lua function, but as Ex command.
* `map!` interprets callback in list as Lua function unless either symbol `&vim` precedes it or the first symbol of the list matches pattern `^<.+>`.
* `augroup!` & `autocmd!`/`au!` no longer resolves quoted callback in itself.
* `augroup!` & `autocmd!`/`au!` no longer accept special options `<command>`, `ex`, `<callback>`, and `cb`.
* `augroup!` & `autocmd!`/`au!` no longer interpret callback of which the first symbol matches `^<.+>` as Lua function, but as key sequence.
* `augroup!` & `autocmd!`/`au!` interprets callback in list as Lua function unless either symbol `&vim` precedes it or the first symbol of the list matches pattern `^<.+>`.
* `map!` wrapper macros, `nmap!`, `vmap!`, ..., are removed.
* `augroup+` is removed; use `augroup!` with `{:clear false}` instead.
  
### Code Refactoring

* remove support for deprecated features ([#210](https://github.com/aileot/nvim-laurel/issues/210)) ([c7f4069](https://github.com/aileot/nvim-laurel/commit/c7f4069faed58d7021c0a3533c219ba22d7cb9d7))

## [0.5.6](https://github.com/aileot/nvim-laurel/compare/v0.5.5...v0.5.6) (2023-02-09)


### Bug Fixes

* **option:** optimize values for short forms: `fo` and `shm` ([#223](https://github.com/aileot/nvim-laurel/issues/223)) ([1d3046b](https://github.com/aileot/nvim-laurel/commit/1d3046b3ec4d127febe289f9495ee9853566be65))

## [0.5.5](https://github.com/aileot/nvim-laurel/compare/v0.5.4...v0.5.5) (2023-02-05)


### Bug Fixes

* **autocmd:** filter non-deprecated format `^<.+>` not to deprecate ([#217](https://github.com/aileot/nvim-laurel/issues/217)) ([3a4b048](https://github.com/aileot/nvim-laurel/commit/3a4b048431973eee207072c3ad98d20184710903))
* **keymap:** filter non-deprecated format `^<.+>` not to deprecate ([#214](https://github.com/aileot/nvim-laurel/issues/214)) ([2812d82](https://github.com/aileot/nvim-laurel/commit/2812d82abc2a58201c67e3a7007dd9417faa6274))

## [0.5.4](https://github.com/aileot/nvim-laurel/compare/v0.5.3...v0.5.4) (2023-02-04)


### Bug Fixes

* **option:** detect sym/list in table not to concat at compile time ([#212](https://github.com/aileot/nvim-laurel/issues/212)) ([cf4dccc](https://github.com/aileot/nvim-laurel/commit/cf4dcccfdbdd885b0348b901964da528e3215ecd))

## [0.5.3](https://github.com/aileot/nvim-laurel/compare/v0.5.2...v0.5.3) (2023-02-04)


### Features

* **autocmd:** deprecate `^<.+>` pattern in sym/list to set Lua callback ([#197](https://github.com/aileot/nvim-laurel/issues/197)) ([5b970cf](https://github.com/aileot/nvim-laurel/commit/5b970cfa2c380e61268eaefd99349116aae8e549))
* **autocmd:** deprecate list to set Ex command ([#203](https://github.com/aileot/nvim-laurel/issues/203)) ([c1d7bbf](https://github.com/aileot/nvim-laurel/commit/c1d7bbf60d69435e51d1705a77f66682e0908836))
* **autocmd:** deprecate quoted callback format ([#202](https://github.com/aileot/nvim-laurel/issues/202)) ([fd0ba7c](https://github.com/aileot/nvim-laurel/commit/fd0ba7c582d52e23b3a9e00f7c4309d60464b705)), closes [#190](https://github.com/aileot/nvim-laurel/issues/190)
* **autocmd:** deprecate special opts `<command>`, `ex`, `<callback>`, and `cb` ([#200](https://github.com/aileot/nvim-laurel/issues/200)) ([cea9d45](https://github.com/aileot/nvim-laurel/commit/cea9d459b4083053b1ba0d259ff84928c2d36d57)), closes [#188](https://github.com/aileot/nvim-laurel/issues/188)
* **autocmd:** detect symbol `&vim` to set Vim Ex command ([#193](https://github.com/aileot/nvim-laurel/issues/193)) ([80f482b](https://github.com/aileot/nvim-laurel/commit/80f482b9e334ed90f8bd8d3c4584e4e1890a7006))
* **command:** deprecate quoted callback format ([#207](https://github.com/aileot/nvim-laurel/issues/207)) ([70f253b](https://github.com/aileot/nvim-laurel/commit/70f253b10e04e7efbaf6f3ee1c04415c23e02031)), closes [#205](https://github.com/aileot/nvim-laurel/issues/205)
* **keymap:** deprecate `^<.+>` pattern in sym/list to set Lua callback ([#199](https://github.com/aileot/nvim-laurel/issues/199)) ([69b3cef](https://github.com/aileot/nvim-laurel/commit/69b3cefa126a4366b04dee39f33888dfa7dd9d9a))
* **keymap:** deprecate list for key sequence ([#204](https://github.com/aileot/nvim-laurel/issues/204)) ([39eb8dc](https://github.com/aileot/nvim-laurel/commit/39eb8dc05b487634124309239a02f2324a66e908))
* **keymap:** deprecate quoted callback format ([#206](https://github.com/aileot/nvim-laurel/issues/206)) ([2a2a57a](https://github.com/aileot/nvim-laurel/commit/2a2a57a45ac5895c37e2dcf7a117ff31bcf25494)), closes [#191](https://github.com/aileot/nvim-laurel/issues/191)
* **keymap:** deprecate special opts `<command>`, `ex`, `<callback>` and `cb` ([#201](https://github.com/aileot/nvim-laurel/issues/201)) ([8a005ed](https://github.com/aileot/nvim-laurel/commit/8a005edf32938f4e296584f87cf76115ab5c4107)), closes [#189](https://github.com/aileot/nvim-laurel/issues/189)
* **keymap:** detect symbol `&vim` to set key sequence ([#195](https://github.com/aileot/nvim-laurel/issues/195)) ([b39b383](https://github.com/aileot/nvim-laurel/commit/b39b3832f36fce592ae05d641dc9c63c161c0646))

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
