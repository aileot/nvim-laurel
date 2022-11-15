 local function keymap_2f__3ecompatible_opts_21(opts) _G.assert((nil ~= opts), "Missing argument opts on fnl/nvim-laurel/utils.fnl:1")

 opts.buffer = nil
 opts["<buffer>"] = nil
 opts["<command>"] = nil
 opts.ex = nil
 opts["<callback>"] = nil
 opts.cb = nil
 opts.literal = nil
 return opts end

 local function command_2f__3ecompatible_opts_21(opts) _G.assert((nil ~= opts), "Missing argument opts on fnl/nvim-laurel/utils.fnl:12")
 opts.buffer = nil
 opts["<buffer>"] = nil
 return opts end

 local function autocmd_2f__3ecompatible_opts_21(opts) _G.assert((nil ~= opts), "Missing argument opts on fnl/nvim-laurel/utils.fnl:17")
 opts["<buffer>"] = nil
 opts["<command>"] = nil
 opts.ex = nil
 opts["<callback>"] = nil
 opts.cb = nil
 return opts end

 return {["keymap/->compatible-opts!"] = keymap_2f__3ecompatible_opts_21, ["command/->compatible-opts!"] = command_2f__3ecompatible_opts_21, ["autocmd/->compatible-opts!"] = autocmd_2f__3ecompatible_opts_21}
