 local function keymap_2f__3ecompatible_opts_21(opts) _G.assert((nil ~= opts), "Missing argument opts on fnl/nvim-laurel/utils.fnl:1")

 opts.buffer = nil
 opts["<buffer>"] = nil
 opts["<command>"] = nil
 opts.ex = nil
 opts["<callback>"] = nil
 opts.cb = nil
 if (opts.expr and (false ~= opts.replace_keycodes)) then opts.replace_keycodes = true else end

 if opts.literal then
 opts.literal = nil
 opts.replace_keycodes = nil else end
 return opts end

 local function command_2f__3ecompatible_opts_21(opts) _G.assert((nil ~= opts), "Missing argument opts on fnl/nvim-laurel/utils.fnl:16")
 opts.buffer = nil
 opts["<buffer>"] = nil
 return opts end

 local function autocmd_2f__3ecompatible_opts_21(opts) _G.assert((nil ~= opts), "Missing argument opts on fnl/nvim-laurel/utils.fnl:21")
 opts["<buffer>"] = nil
 opts["<command>"] = nil
 opts.ex = nil
 opts["<callback>"] = nil
 opts.cb = nil
 return opts end

 return {["keymap/->compatible-opts!"] = keymap_2f__3ecompatible_opts_21, ["command/->compatible-opts!"] = command_2f__3ecompatible_opts_21, ["autocmd/->compatible-opts!"] = autocmd_2f__3ecompatible_opts_21}
