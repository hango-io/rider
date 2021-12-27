local ffi = require("ffi")
local C = ffi.C
local base = require("rider.base")

ffi.cdef[[
    int envoy_http_lua_ffi_v2_log(int level, const char* message);
]]

local TRACE = 0
local DEBUG = 1
local INFO = 2
local WARN = 3
local ERR = 4

function envoy.logTrace(message)
    C.envoy_http_lua_ffi_v2_log(TRACE, message)
end

function envoy.logDebug(message)
    C.envoy_http_lua_ffi_v2_log(DEBUG, message)
end

function envoy.logInfo(message)
    C.envoy_http_lua_ffi_v2_log(INFO, message)
end

function envoy.logWarn(message)
    C.envoy_http_lua_ffi_v2_log(WARN, message)
end

function envoy.logErr(message)
    C.envoy_http_lua_ffi_v2_log(ERR, message)
end
