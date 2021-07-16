local ffi = require 'ffi'
local ffi_new = ffi.new

local _M = {}
local str_buf_size = 4096
local str_buf

if not pcall(ffi.typeof, "ContextBase") then
    ffi.cdef[[
        typedef struct ContextBase ContextBase;
    ]]
end

if not pcall(ffi.typeof, "envoy_lua_ffi_str_t") then
    ffi.cdef[[
        typedef struct {
            int             len;
            const char      *data;
        } envoy_lua_ffi_str_t;
    ]]
end

if not pcall(ffi.typeof, "envoy_lua_ffi_table_elt_t") then
    ffi.cdef[[
        typedef struct {
            envoy_lua_ffi_str_t key;
            envoy_lua_ffi_str_t value;
        } envoy_lua_ffi_table_elt_t;
    ]]
end

if not pcall(ffi.typeof, "envoy_lua_ffi_string_pairs") then
    ffi.cdef[[
        typedef struct {
            envoy_lua_ffi_table_elt_t* data;
            int size;
            int capacity;
          } envoy_lua_ffi_string_pairs;
    ]]
end

local c_buf_type = ffi.typeof("char[?]")

function _M.get_string_buf(size, must_alloc)
    if size > str_buf_size or must_alloc then
        return ffi_new(c_buf_type, size)
    end

    if not str_buf then
        str_buf = ffi_new(c_buf_type, str_buf_size)
    end

    return str_buf
end

local getfenv = getfenv

-- get_context_handle returns a light userdata which stores address of a ContextBase* object.
function _M.get_context_handle()
  return getfenv(0)._envoy_context
end

-- FFI function return codes.
_M.FFI_OK = 0
_M.FFI_BadContext = -1
_M.FFI_NotFound = -2
_M.FFI_BadArgument = -3
_M.FFI_Unsupported = -4


return _M