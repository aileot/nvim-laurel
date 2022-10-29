


 local function merge_api_opts(_3fapi_opts, _3fextra_opts)





 if (_3fapi_opts and _3fextra_opts) then
 local tbl_14_auto = _3fextra_opts for k, v in pairs(_3fapi_opts) do
 local _1_, _2_ = k, v if ((nil ~= _1_) and (nil ~= _2_)) then local k_15_auto = _1_ local v_16_auto = _2_ tbl_14_auto[k_15_auto] = v_16_auto else end end return tbl_14_auto else
 return (_3fapi_opts or _3fextra_opts or {}) end end

 return {["merge-api-opts"] = merge_api_opts}
