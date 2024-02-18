# Changelog

## [0.7.0](https://github.com/aileot/nvim-laurel/compare/nvim-laurel-v0.6.0...nvim-laurel-v0.7.0) (2024-02-18)


### ⚠ BREAKING CHANGES

* `command!` drops support to resolve unnecessary quote on callback
* **keymap:** `map!` sets keymap non-recursively by default; `map!` requires `remap` option to set recursive mapping

### Features

* add `&lt;command&gt;` to ensure to set without callback ([f895d09](https://github.com/aileot/nvim-laurel/commit/f895d09d97254da1b0f2b12c2b584a8843b48aee))
* add `ex` key as an alias of `&lt;command&gt;` key ([945ea76](https://github.com/aileot/nvim-laurel/commit/945ea765b17287d1e1bfe855ace7a287d3d296cd))
* **autocmd:** convert `vim.fn.foo#bar` into "foo#bar" to set to "callback" ([8d88c61](https://github.com/aileot/nvim-laurel/commit/8d88c61ace331e97ed635c7f6088653f8fd28650))
* **autocmd:** deprecate `^&lt;.+&gt;` pattern in sym/list to set Lua callback ([#197](https://github.com/aileot/nvim-laurel/issues/197)) ([5b970cf](https://github.com/aileot/nvim-laurel/commit/5b970cfa2c380e61268eaefd99349116aae8e549))
* **autocmd:** deprecate list to set Ex command ([#203](https://github.com/aileot/nvim-laurel/issues/203)) ([c1d7bbf](https://github.com/aileot/nvim-laurel/commit/c1d7bbf60d69435e51d1705a77f66682e0908836))
* **autocmd:** deprecate quoted callback format ([#202](https://github.com/aileot/nvim-laurel/issues/202)) ([fd0ba7c](https://github.com/aileot/nvim-laurel/commit/fd0ba7c582d52e23b3a9e00f7c4309d60464b705)), closes [#190](https://github.com/aileot/nvim-laurel/issues/190)
* **autocmd:** deprecate special opts &lt;command&gt;, ex, <callback>, and cb ([#200](https://github.com/aileot/nvim-laurel/issues/200)) ([cea9d45](https://github.com/aileot/nvim-laurel/commit/cea9d459b4083053b1ba0d259ff84928c2d36d57)), closes [#188](https://github.com/aileot/nvim-laurel/issues/188)
* **autocmd:** detect `&vim` indicator to set Vim Ex command ([#193](https://github.com/aileot/nvim-laurel/issues/193)) ([80f482b](https://github.com/aileot/nvim-laurel/commit/80f482b9e334ed90f8bd8d3c4584e4e1890a7006))
* **autocmd:** enable to infer description from symbol name ([1498a0a](https://github.com/aileot/nvim-laurel/commit/1498a0a4259af18307c3debc0ae6258ea19263f2))
* **autocmd:** make `augroup!` accept `api-opts`; deprecate `augroup+` ([#178](https://github.com/aileot/nvim-laurel/issues/178)) ([1546d9b](https://github.com/aileot/nvim-laurel/commit/1546d9b3c0064ae1ec560b0d5d7168d7cc8ca1ba))
* **command:** deprecate quoted callback format ([#207](https://github.com/aileot/nvim-laurel/issues/207)) ([70f253b](https://github.com/aileot/nvim-laurel/commit/70f253b10e04e7efbaf6f3ee1c04415c23e02031)), closes [#205](https://github.com/aileot/nvim-laurel/issues/205)
* **extra-opts:** add `cb` alias `&lt;callback&gt;` ([6a3359e](https://github.com/aileot/nvim-laurel/commit/6a3359e91cec17f6d0a9b97cc5d33eb4eb05a264))
* extract callback in `quote`d symbol/list; deprecate callback in symbol ([#150](https://github.com/aileot/nvim-laurel/issues/150)) ([98f0dcd](https://github.com/aileot/nvim-laurel/commit/98f0dcdf07c9c762e3d7796bfbbc5c938ad1c0f3))
* **keymap:** add `&lt;Cmd&gt;` and `<C-u>` ([ad61530](https://github.com/aileot/nvim-laurel/commit/ad61530e3bf0dfa4e22112814cd7d272b8c3038b))
* **keymap:** add `map-range!` macros ([470cfb5](https://github.com/aileot/nvim-laurel/commit/470cfb523d12d2723e8d7c405e920ddadb8529e1))
* **keymap:** deprecate `^&lt;.+&gt;` pattern in sym/list to set Lua callback ([#199](https://github.com/aileot/nvim-laurel/issues/199)) ([69b3cef](https://github.com/aileot/nvim-laurel/commit/69b3cefa126a4366b04dee39f33888dfa7dd9d9a))
* **keymap:** deprecate list for key sequence ([#204](https://github.com/aileot/nvim-laurel/issues/204)) ([39eb8dc](https://github.com/aileot/nvim-laurel/commit/39eb8dc05b487634124309239a02f2324a66e908))
* **keymap:** deprecate quoted callback format ([#206](https://github.com/aileot/nvim-laurel/issues/206)) ([2a2a57a](https://github.com/aileot/nvim-laurel/commit/2a2a57a45ac5895c37e2dcf7a117ff31bcf25494)), closes [#191](https://github.com/aileot/nvim-laurel/issues/191)
* **keymap:** deprecate special opts &lt;command&gt;, ex, <callback> and cb ([#201](https://github.com/aileot/nvim-laurel/issues/201)) ([8a005ed](https://github.com/aileot/nvim-laurel/commit/8a005edf32938f4e296584f87cf76115ab5c4107)), closes [#189](https://github.com/aileot/nvim-laurel/issues/189)
* **keymap:** detect `&lt;Cmd&gt;`/`<C-u>` macros for excmd ([8be7b92](https://github.com/aileot/nvim-laurel/commit/8be7b92a6ce7e815d2ed6227fca8d14f3181ef27))
* **keymap:** detect `&vim` indicator to set key sequence ([#195](https://github.com/aileot/nvim-laurel/issues/195)) ([b39b383](https://github.com/aileot/nvim-laurel/commit/b39b3832f36fce592ae05d641dc9c63c161c0646))
* **keymap:** detect `remap` option in `extra-opts` ([e770902](https://github.com/aileot/nvim-laurel/commit/e77090295603db23148875d48df078a421cd7ab1))
* **keymap:** modes can contain multi modes in bare-string ([e7d9230](https://github.com/aileot/nvim-laurel/commit/e7d9230b324c54c2a172caefe92446dcb2d3642e))
* **option:** add `bo!` and `wo!` ([679e82e](https://github.com/aileot/nvim-laurel/commit/679e82e2e391ed65da9dc0387b27791a3cf2e1e4)), closes [#101](https://github.com/aileot/nvim-laurel/issues/101)
* **option:** add `go!`, `go+`, ..., alias `setglobal!`, ... ([14ebf25](https://github.com/aileot/nvim-laurel/commit/14ebf25487c995f0f39521210bb1e27b7346a6c9))
* **option:** detect infix flag in symbol to append, prepend, ...; deprecate `:foo+`, ..., format and `set+`, ..., macros ([#233](https://github.com/aileot/nvim-laurel/issues/233)) ([669bdf4](https://github.com/aileot/nvim-laurel/commit/669bdf4ed5d4503f3eb40f28024f2ebbaa4547df))
* **utils:** add `first-symbol` ([8b118ef](https://github.com/aileot/nvim-laurel/commit/8b118ef866fbcf3f03d433de4125ae945cb143ae))
* **variable:** add variable macros ([95b72e8](https://github.com/aileot/nvim-laurel/commit/95b72e863888fddf33a5fe3694b28a31697dc746))
* **wrapper:** add `keymap/set-maps!` for runtime ([fc2a1e1](https://github.com/aileot/nvim-laurel/commit/fc2a1e1133f085278ab3633ed381ff93294883b6))
* **wrapper:** add wrapper to merge api-opts in runtime ([6bdde21](https://github.com/aileot/nvim-laurel/commit/6bdde2125737b17e8d4b32eeeea6871255156c40))


### Bug Fixes

* **autocmd:** filter non-deprecated format `^&lt;.+&gt;` not to deprecate ([#217](https://github.com/aileot/nvim-laurel/issues/217)) ([3a4b048](https://github.com/aileot/nvim-laurel/commit/3a4b048431973eee207072c3ad98d20184710903))
* **autocmd:** set `?pattern` to `extra-opts` only if it makes sense ([42f8472](https://github.com/aileot/nvim-laurel/commit/42f8472188284390f83278cd07cf6ae90f9ad16a))
* **command:** merge api-opts in symbol/list safely ([7da9340](https://github.com/aileot/nvim-laurel/commit/7da93402ed0125f1284ab8e756a22705575e74ab))
* **feedkeys:** set `""` if `?flags` is `nil` ([89fbf84](https://github.com/aileot/nvim-laurel/commit/89fbf848d8e80e21f4a7e7cf3be6e8b54d0a2513))
* **hi!:** correct indent ([69a8c23](https://github.com/aileot/nvim-laurel/commit/69a8c23c1293f06c8e22dbb819cddd973fc06ab8))
* **hi!:** cterm color can be set in symbol/list ([634ccf1](https://github.com/aileot/nvim-laurel/commit/634ccf127b927c224067462292b48bf9ba05fff3))
* **hi!:** omit `cterm.fg` and `cterm.bg` at compile time ([2bef93a](https://github.com/aileot/nvim-laurel/commit/2bef93a51ee182873e6143596bf6db65da5f34db))
* **infer-desc:** replace string separators correctly with spaces ([a6a178f](https://github.com/aileot/nvim-laurel/commit/a6a178faf3c61700301a13970583453d16fb39b8))
* **keycodes:** interpret `&lt;lt&gt;` in `str->keycodes` ([23ad5bb](https://github.com/aileot/nvim-laurel/commit/23ad5bb8adbf3b7ff61ab540441de2fa4031752f))
* **keymap|autocmd:** add `&lt;callback&gt;` key to set anonymous-function via user function ([0a388f1](https://github.com/aileot/nvim-laurel/commit/0a388f18efef3970ee8a269a2d530e674d5a6c69))
* **keymap:** add missing map-args to `trues` detection ([ff221b3](https://github.com/aileot/nvim-laurel/commit/ff221b318eb5faa96946739c86b8a91a0736c5ee))
* **keymap:** delete smap in buffer as its necessity ([99b84f5](https://github.com/aileot/nvim-laurel/commit/99b84f5ff433e4ededc4fc578a866ded35cc15dd))
* **keymap:** detect `ex-` prefix in list in addition to that in symbol ([7d552a4](https://github.com/aileot/nvim-laurel/commit/7d552a40b25babfaad744bda5d965594077e2787))
* **keymap:** detect missing `noremap` key as boolean ([cf73e7d](https://github.com/aileot/nvim-laurel/commit/cf73e7d2bb1a961ef287015dfdc8928f1d736ab7))
* **keymap:** do not `:sunmap` if `lhs` is invisible in `map-motion!` ([f4b2cb2](https://github.com/aileot/nvim-laurel/commit/f4b2cb2f339c7c1f0c432682ed8317bd24ec292f))
* **keymap:** filter non-deprecated format `^&lt;.+&gt;` not to deprecate ([#214](https://github.com/aileot/nvim-laurel/issues/214)) ([2812d82](https://github.com/aileot/nvim-laurel/commit/2812d82abc2a58201c67e3a7007dd9417faa6274))
* **keymap:** insert missing `?api-opts` ([7d1e954](https://github.com/aileot/nvim-laurel/commit/7d1e95483f51f047585d6911a0d5ff2fb69e1d68))
* **keymap:** set keymap via `vim.keymap.set` only if `modes` is symbol or list ([b0b7d3e](https://github.com/aileot/nvim-laurel/commit/b0b7d3e654b31cd532dde032d76343ca4a84e563))
* **macro:** add `if-not` ([0415544](https://github.com/aileot/nvim-laurel/commit/041554456888b2c0b71fc7ab7c3d7f6f56425142))
* **option:** detect sym/list in table not to concat at compile time ([#212](https://github.com/aileot/nvim-laurel/issues/212)) ([cf4dccc](https://github.com/aileot/nvim-laurel/commit/cf4dcccfdbdd885b0348b901964da528e3215ecd))
* **option:** improve `vim.opt` detection ([fb9c32a](https://github.com/aileot/nvim-laurel/commit/fb9c32aeb1f87c381e5723c3f6b591544820eb3f))
* **option:** optimize values for short forms: `fo` and `shm` ([#223](https://github.com/aileot/nvim-laurel/issues/223)) ([1d3046b](https://github.com/aileot/nvim-laurel/commit/1d3046b3ec4d127febe289f9495ee9853566be65))
* **option:** remove `?` prefix from un-nilable var ([e1333ab](https://github.com/aileot/nvim-laurel/commit/e1333ab33b21c6c702e761ac0e498edba6e3f3df))
* **option:** surely remove flags for `&shortmess`/`&formatoptions` ([db3fdf1](https://github.com/aileot/nvim-laurel/commit/db3fdf1191b32b7eeb00bd16f6e9a1377efba6a4))
* **pattern:** insert missing `%` before `-` ([15cc72f](https://github.com/aileot/nvim-laurel/commit/15cc72fb52bb54819e1e0be1e2faf0cbb9d0a267))
* **util:** make predicate arg nillable ([6c759e7](https://github.com/aileot/nvim-laurel/commit/6c759e738f708b4dbad060e4fcd23112e565bdea))
* **utils:** correct `slice` logic ([1156aef](https://github.com/aileot/nvim-laurel/commit/1156aefa6ae70ee1acdcf17a8a277b21efd82288))
* **utils:** correctly get key from `another` kv-table ([bf1b89f](https://github.com/aileot/nvim-laurel/commit/bf1b89fcdf2ee6aca2a51967fb76beccad48e5df))


### Performance Improvements

* **autocmd:** extract pattern if only one in sequence ([d2c159a](https://github.com/aileot/nvim-laurel/commit/d2c159a622a652bf8dff2b87f16a7e63ccd8edcf))
* **keymap:** remove `noremap` w/ `callback`, but w/o `expr` ([e28e63b](https://github.com/aileot/nvim-laurel/commit/e28e63b3b4cf39b539fa60bb48f6a4b0094d4235))
* **util:** remove unused util functions ([63f7acb](https://github.com/aileot/nvim-laurel/commit/63f7acbbf13cdfe6051d2593afae4c21ae84c44d))
* **wrapper:** remove unnecessary wrapper definitions ([84f35cf](https://github.com/aileot/nvim-laurel/commit/84f35cf6edfa2a9ffc18af13da7813dcd56bb926))


### Code Refactoring

* **keymap:** make `map!` macro non-recursively by default ([#144](https://github.com/aileot/nvim-laurel/issues/144)) ([d086443](https://github.com/aileot/nvim-laurel/commit/d0864431dee8bbaf460b1ae0ba752e9373fcf9be))
* remove support for deprecated features ([#210](https://github.com/aileot/nvim-laurel/issues/210)) ([c7f4069](https://github.com/aileot/nvim-laurel/commit/c7f4069faed58d7021c0a3533c219ba22d7cb9d7))

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
