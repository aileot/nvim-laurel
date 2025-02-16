# Contributing

> [!IMPORTANT]
> This project is mainly written in [Fennel][] to be transpiled to Lua.
> The Lua files under `fnl/` are also copied to `lua/` directory.
>
> Do **NOT** directly edit **any** Lua files under `lua/` directory.
> Instead, edit the files under `fnl/` directory.

Any kind of contributions are welcome.

Before any changes,
please run [`make init`](#make-init)
at the repository's root directory.
For larger features,
please open an issue first to avoid duplicate work.

## Building

## Testing

1. Make sure [Requirements](#test-requirements) are installed,
   or follow the steps [for nix users](#testing-for-nix-users).
2. Run `make test`.

### Test Requirements

- [make][]: the build/test interface
- [fennel][]: the compiler
- [vusted][]: the test runner

#### Testing for nix users

If you have `nix` installed,
you can automate the requirement installation
with the following options enabled:

1. `flake` feature
2. `programs.direnv.enable`

Then, run `direnv allow` in this project directory.
Otherwise, please run `nix develop` in this project directory.

[fennel]: https://sr.ht/~technomancy/fennel/
[make]: https://www.gnu.org/software/make/manual/html_node/index.html
[vusted]: https://github.com/notomo/vusted
