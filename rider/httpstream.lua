local ffi = require("ffi")
local base = require("rider.base")

local C = ffi.C
local ffi_cast = ffi.cast
local ffi_str = ffi.string
local ffi_new = ffi.new
local get_string_buf = base.get_string_buf
local FFI_OK = base.FFI_OK
local get_context_handle = base.get_context_handle
local registry = debug.getregistry()

local SOURCE_REQUEST = 0
local SOURCE_RESPONSE = 1

ffi.cdef[[
    int envoy_http_lua_ffi_get_header_map(ContextBase* ctx, int source, envoy_lua_ffi_string_pairs* buffer);
    int envoy_http_lua_ffi_get_header_map_size(ContextBase* ctx, int source);
    int envoy_http_lua_ffi_get_header_map_value(ContextBase* ctx, int source, const char* key, int key_len, envoy_lua_ffi_str_t* value);
    int envoy_http_lua_ffi_set_header_map_value(ContextBase* ctx, int source, const char* key, int key_len, const char* value, int value_len);
    int envoy_http_lua_ffi_remove_header_map_value(ContextBase* ctx, int source, const char* key, int key_len);
    int envoy_http_lua_ffi_get_query_parameters(ContextBase* ctx, int source, envoy_lua_ffi_string_pairs* buf);
    int envoy_http_lua_ffi_get_shared_table(ContextBase* ctx);
    //int envoy_http_lua_ffi_req_get_metadata(RequestContext* r, const char* key, size_t key_len,
    //                                        const char* filter_name, size_t filter_name_len, envoy_http_lua_ffi_str_t* value);
]]

local table_elt_type = ffi.typeof("envoy_lua_ffi_table_elt_t*")
local table_elt_size = ffi.sizeof("envoy_lua_ffi_table_elt_t")

if envoy.stream.shared == nil then
    local proxy = {}
    local mt = {
        __index = function (t, k)
            local ctx = get_context_handle()
            if not ctx then
                error("no context")
            end

            local ref = C.envoy_http_lua_ffi_get_shared_table(ctx)
            if ref > 0 then
                return registry[ref][k]
            else
                error("error get shared table reference: "..ref)
            end
        end,

        __newindex = function (t, k, v)
            local ctx = get_context_handle()
            if not ctx then
                error("no context")
            end

            local ref = C.envoy_http_lua_ffi_get_shared_table(ctx)
            if ref > 0 then
                registry[ref][k] = v
            else
                error("error get shared table reference: "..ref)
            end
        end
    }
    setmetatable(proxy, mt)
    envoy.stream.shared = proxy
end

local function get_headers(source)
    local ctx = get_context_handle()
    if not ctx then
        error("no context")
    end

    local header_map_size = C.envoy_http_lua_ffi_get_header_map_size(ctx, source)
    if header_map_size == 0  then return nil end
    local raw_buf = ffi_new("envoy_lua_ffi_table_elt_t[?]", header_map_size)
    local pairs_buf = ffi_new("envoy_lua_ffi_string_pairs[1]", { [0] = {raw_buf, 0, header_map_size} })

    local rc = C.envoy_http_lua_ffi_get_header_map(ctx, source, pairs_buf)
    if rc ~= FFI_OK then
        error("error get headers")
    end

    local result = {}
    for i = 0, header_map_size - 1  do
      local h = pairs_buf[0].data[i]

      local key = ffi_str(h.key.data, h.key.len)
      local val = ffi_str(h.value.data, h.value.len)

      result[key] = val
    end
    return result
end

local function get_header_map_size(source)
    local ctx = get_context_handle()
    if not ctx then
        error("no context")
    end

    return C.envoy_http_lua_ffi_get_header_map_size(ctx, source)
end

local function get_header_map_value(source, key)
    local ctx = get_context_handle()
    if not ctx then
        error("no context")
    end

    if type(key) ~= "string" then
        error("header name must be a string", 2)
    end

    local buffer = ffi_new("envoy_lua_ffi_str_t[1]")
    local rc = C.envoy_http_lua_ffi_get_header_map_value(ctx, source, key, #key, buffer)
    if rc ~= FFI_OK then
        return nil
    end
    return ffi_str(buffer[0].data, buffer[0].len)
end

local function set_header_map_value(source, key, value)
    local ctx = get_context_handle()
    if not ctx then
        error("no context")
    end

    if type(key) ~= "string" then
        error("header name must be a string", 2)
    end

    if type(value) ~= "string" then
        error("header value must be a string", 2)
    end

    local rc = C.envoy_http_lua_ffi_set_header_map_value(ctx, source, key, #key, value, #value)
    if rc ~= FFI_OK then
        error("error set header")
    end
end

local function remove_header_map_value(source, key)
    local ctx = get_context_handle()
    if not ctx then
        error("no context")
    end

    if type(key) ~= "string" then
        error("header name must be a string", 2)
    end

    local rc = C.envoy_http_lua_ffi_remove_header_map_value(ctx, source, key, #key)
    if rc ~= FFI_OK then
        error("error remove header")
    end
end

function envoy.req.get_header_map_size()
    return get_header_map_size(SOURCE_REQUEST)
end

function envoy.resp.get_header_map_size()
    return get_header_map_size(SOURCE_RESPONSE)
end

function envoy.req.get_headers()
    return get_headers(SOURCE_REQUEST)
end

function envoy.resp.get_headers()
    return get_headers(SOURCE_RESPONSE)
end

function envoy.req.get_header(key)
    return get_header_map_value(SOURCE_REQUEST, key)
end

function envoy.resp.get_header(key)
    return get_header_map_value(SOURCE_RESPONSE, key)
end

function envoy.req.set_header(key, value)
    return set_header_map_value(SOURCE_REQUEST, key, value)
end

function envoy.resp.set_header(key, value)
    return set_header_map_value(SOURCE_RESPONSE, key, value)
end

function envoy.req.remove_header(key)
    return remove_header_map_value(SOURCE_REQUEST, key)
end

function envoy.resp.remove_header(key)
    return remove_header_map_value(SOURCE_RESPONSE, key)
end
