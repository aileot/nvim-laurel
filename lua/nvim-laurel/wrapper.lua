


 local _local_1_ = require("nvim-laurel.utils") local keymap_2f__3ecompatible_opts_21 = _local_1_["keymap/->compatible-opts!"]





 local function merge_api_opts(_3fapi_opts, _3fextra_opts)





 if (_3fapi_opts and _3fextra_opts) then
 local tbl_14_auto = _3fextra_opts for k, v in pairs(_3fapi_opts) do
 local _2_, _3_ = k, v if ((nil ~= _2_) and (nil ~= _3_)) then local k_15_auto = _2_ local v_16_auto = _3_ tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto else
 return (_3fapi_opts or _3fextra_opts or {}) end end

 local function keymap_2fset_maps_21(modes, extra_opts, lhs, rhs, _3fapi_opts) _G.assert((nil ~= rhs), "Missing argument rhs on fnl/nvim-laurel/wrapper.fnl:21") _G.assert((nil ~= lhs), "Missing argument lhs on fnl/nvim-laurel/wrapper.fnl:21") _G.assert((nil ~= extra_opts), "Missing argument extra-opts on fnl/nvim-laurel/wrapper.fnl:21") _G.assert((nil ~= modes), "Missing argument modes on fnl/nvim-laurel/wrapper.fnl:21")
 local _3fbufnr = extra_opts.buffer
 local api_opts = merge_api_opts(_3fapi_opts, keymap_2f__3ecompatible_opts_21(extra_opts)) local set_keymap

 if _3fbufnr then
 local function _6_(mode) _G.assert((nil ~= mode), "Missing argument mode on fnl/nvim-laurel/wrapper.fnl:26")
 return vim.api.nvim_buf_set_keymap(_3fbufnr, mode, lhs, rhs, api_opts) end set_keymap = _6_ else

 local function _7_(mode) _G.assert((nil ~= mode), "Missing argument mode on fnl/nvim-laurel/wrapper.fnl:29")
 return vim.api.nvim_set_keymap(mode, lhs, rhs, api_opts) end set_keymap = _7_ end
 if ("string" == type(modes)) then
 return set_keymap(modes) else
 for _, m in ipairs(modes) do
 set_keymap(m) end return nil end end

 return {["merge-api-opts"] = merge_api_opts, ["keymap/set-maps!"] = keymap_2fset_maps_21}
