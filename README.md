# nvim-laurel 🌿

nvim-laurel provides a syntax sugar macro collection to write neovim config in
[Fennel][Fennel], developped with [parinfer-rust][parinfer-rust],
[fnlfmt][fnlfmt] and [fennel-language-server][fennel-language-server], and
tested with [vusted][vusted].

## Requirements

- Neovim 0.8.0+
- A compiler: [Fennel][Fennel], [hotpot.nvim][hotpot.nvim], etc.

## Installation

### Compile outside Neovim

1. Download nvim-laurel where you feel like

```sh
git clone https://github.com/aileot/nvim-laurel /path/to/install
```

2. Compile your fennel files with macro path for nvim-laurel
   `/path/to/nvim-laurel/fnl/?.fnl;/path/to/nvim-laurel/fnl/?/init.fnl`. For
   example, in your Makefile,

```make
%.lua: %.fnl
	fennel --add-macro-path "/path/to/nvim-laurel/fnl/?.fnl;/path/to/nvim-laurel/fnl/?/init.fnl"
		--compile $< > $@
```

### With a compiler plugin

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

## Usage

```fennel
(import-macros {: nnoremap! : augroup! :au! ...} :nvim-laurel.macros)
```

### Examples

[Fennel]: https://github.com/bakpakin/Fennel
[parinfer-rust]: https://github.com/eraserhd/parinfer-rust
[fnlfmt]: https://git.sr.ht/~technomancy/fnlfmt
[fennel-language-server]: https://github.com/rydesun/fennel-language-server
[vusted]: https://github.com/notomo/vusted
[hotpot.nvim]: https://github.com/rktjmp/hotpot.nvim
