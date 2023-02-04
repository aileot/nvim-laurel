# Changelog

## [0.5.3](https://github.com/aileot/nvim-laurel/compare/v0.5.2...v0.5.3) (2023-02-04)


### Features

* **autocmd:** deprecate `^&lt;.+&gt;` pattern in sym/list to set Lua callback ([#197](https://github.com/aileot/nvim-laurel/issues/197)) ([5b970cf](https://github.com/aileot/nvim-laurel/commit/5b970cfa2c380e61268eaefd99349116aae8e549))
* **autocmd:** deprecate list to set Ex command ([#203](https://github.com/aileot/nvim-laurel/issues/203)) ([c1d7bbf](https://github.com/aileot/nvim-laurel/commit/c1d7bbf60d69435e51d1705a77f66682e0908836))
* **autocmd:** deprecate quoted callback format ([#202](https://github.com/aileot/nvim-laurel/issues/202)) ([fd0ba7c](https://github.com/aileot/nvim-laurel/commit/fd0ba7c582d52e23b3a9e00f7c4309d60464b705)), closes [#190](https://github.com/aileot/nvim-laurel/issues/190)
* **autocmd:** deprecate special opts &lt;command&gt;, ex, <callback>, and cb ([#200](https://github.com/aileot/nvim-laurel/issues/200)) ([cea9d45](https://github.com/aileot/nvim-laurel/commit/cea9d459b4083053b1ba0d259ff84928c2d36d57)), closes [#188](https://github.com/aileot/nvim-laurel/issues/188)
* **autocmd:** detect `&vim` indicator to set Vim Ex command ([#193](https://github.com/aileot/nvim-laurel/issues/193)) ([80f482b](https://github.com/aileot/nvim-laurel/commit/80f482b9e334ed90f8bd8d3c4584e4e1890a7006))
* **command:** deprecate quoted callback format ([#207](https://github.com/aileot/nvim-laurel/issues/207)) ([70f253b](https://github.com/aileot/nvim-laurel/commit/70f253b10e04e7efbaf6f3ee1c04415c23e02031)), closes [#205](https://github.com/aileot/nvim-laurel/issues/205)
* **keymap:** deprecate `^&lt;.+&gt;` pattern in sym/list to set Lua callback ([#199](https://github.com/aileot/nvim-laurel/issues/199)) ([69b3cef](https://github.com/aileot/nvim-laurel/commit/69b3cefa126a4366b04dee39f33888dfa7dd9d9a))
* **keymap:** deprecate list for key sequence ([#204](https://github.com/aileot/nvim-laurel/issues/204)) ([39eb8dc](https://github.com/aileot/nvim-laurel/commit/39eb8dc05b487634124309239a02f2324a66e908))
* **keymap:** deprecate quoted callback format ([#206](https://github.com/aileot/nvim-laurel/issues/206)) ([2a2a57a](https://github.com/aileot/nvim-laurel/commit/2a2a57a45ac5895c37e2dcf7a117ff31bcf25494)), closes [#191](https://github.com/aileot/nvim-laurel/issues/191)
* **keymap:** deprecate special opts &lt;command&gt;, ex, <callback> and cb ([#201](https://github.com/aileot/nvim-laurel/issues/201)) ([8a005ed](https://github.com/aileot/nvim-laurel/commit/8a005edf32938f4e296584f87cf76115ab5c4107)), closes [#189](https://github.com/aileot/nvim-laurel/issues/189)
* **keymap:** detect `&vim` indicator to set key sequence ([#195](https://github.com/aileot/nvim-laurel/issues/195)) ([b39b383](https://github.com/aileot/nvim-laurel/commit/b39b3832f36fce592ae05d641dc9c63c161c0646))

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
