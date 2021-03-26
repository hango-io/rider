local ffi = require("ffi")
local C = ffi.C
local base = require("rider.base")
local get_context_handle = base.get_context_handle

ffi.cdef[[
    int envoy_http_lua_ffi_log(ContextBase* ctx, int level, const char* message);
]]

local TRACE = 0
local DEBUG = 1
local INFO = 2
local WARN = 3
local ERR = 4

function envoy.logTrace(message)
    C.envoy_http_lua_ffi_log(get_context_handle(), TRACE, message)
end

function envoy.logDebug(message)
    C.envoy_http_lua_ffi_log(get_context_handle(), DEBUG, message)
end

function envoy.logInfo(message)
    C.envoy_http_lua_ffi_log(get_context_handle(), INFO, message)
end

function envoy.logWarn(message)
    C.envoy_http_lua_ffi_log(get_context_handle(), WARN, message)
end

function envoy.logErr(message)
    C.envoy_http_lua_ffi_log(get_context_handle(), ERR, message)
end
