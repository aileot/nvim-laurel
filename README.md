# nvim-laurel 🌿

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![test](https://github.com/aileot/nvim-laurel/actions/workflows/test.yml/badge.svg)](https://github.com/aileot/nvim-laurel/actions/workflows/test.yml)

nvim-laurel provides syntax sugar macros for Neovim. The macros are developped
with [fnlfmt][fnlfmt] and [fennel-language-server][fennel-language-server], and
tested with [vusted][vusted].

## Requirements

- Neovim 0.8.0+
- A compiler: [Fennel][Fennel], [hotpot.nvim][hotpot.nvim], etc.

## Installation

### With a compiler plugin (recommended)

Install nvim-laurel by your favorite plugin manager.

[packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use "aileot/nvim-laurel"
```

[dein.vim](https://github.com/Shougo/dein.vim) in toml:

```toml
[[plugin]]
repo = "aileot/nvim-laurel"
```

### To compile outside Neovim

1. Download nvim-laurel where you feel like

```sh
git clone https://github.com/aileot/nvim-laurel /path/to/install
```

2. Compile your fennel files with macro path for nvim-laurel:

   `/path/to/nvim-laurel/fnl/?.fnl;/path/to/nvim-laurel/fnl/?/init.fnl`

   For example, in your Makefile,

```make
%.lua: %.fnl
	fennel --add-macro-path "/path/to/nvim-laurel/fnl/?.fnl;/path/to/nvim-laurel/fnl/?/init.fnl"
		--compile $< > $@
```

## Usage

```fennel
(import-macros {: setglobal! : augroup! :au! ...} :nvim-laurel.macros)
```

See
[doc/macros.md](https://github.com/aileot/nvim-laurel/blob/main/doc/macros.md)
for each macro usage in detail.

## Alternatives

- [aniseed](https://github.com/Olical/aniseed)
- [hibiscus.nvim](https://github.com/udayvir-singh/hibiscus.nvim)
- [katcros-fnl](https://github.com/katawful/katcros-fnl)
- [themis.nvim](https://github.com/datwaft/themis.nvim)
- [zest.nvim](https://github.com/tsbohc/zest.nvim)

[Fennel]: https://github.com/bakpakin/Fennel
[fnlfmt]: https://git.sr.ht/~technomancy/fnlfmt
[fennel-language-server]: https://github.com/rydesun/fennel-language-server
[vusted]: https://github.com/notomo/vusted
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
