local ffi = require("ffi")
local base = require("rider.base")

local C = ffi.C
local ffi_cast = ffi.cast
local ffi_str = ffi.string
local ffi_new = ffi.new
local get_string_buf = base.get_string_buf
local FFI_OK = base.FFI_OK
local registry = debug.getregistry()

local SOURCE_REQUEST = 0
local SOURCE_RESPONSE = 1

ffi.cdef[[
    int envoy_http_lua_ffi_v2_get_header_map(int source, envoy_lua_ffi_string_pairs* buffer);
    int envoy_http_lua_ffi_v2_get_header_map_size(int source);
    int envoy_http_lua_ffi_v2_get_header_map_value(int source, const char* key, int key_len, envoy_lua_ffi_str_t* value);
    int envoy_http_lua_ffi_v2_set_header_map(int source, envoy_lua_ffi_string_pairs* buffer);
    int envoy_http_lua_ffi_v2_set_header_map_value(int source, const char* key, int key_len, const char* value, int value_len);
    int envoy_http_lua_ffi_v2_remove_header_map_value(int source, const char* key, int key_len);
    int envoy_http_lua_ffi_v2_get_query_parameters(envoy_lua_ffi_string_pairs* buf);
    int envoy_http_lua_ffi_v2_get_shared_table();
    int envoy_http_lua_ffi_v2_get_metadata(envoy_lua_ffi_str_t* filter_name, envoy_lua_ffi_str_t* key,  envoy_lua_ffi_str_t* value);
    int envoy_http_lua_ffi_v2_get_body(int source, envoy_lua_ffi_str_t* body);

    int64_t envoy_http_lua_ffi_v2_streaminfo_start_time();
    const char* envoy_http_lua_ffi_v2_upstream_host();
    const char* envoy_http_lua_ffi_v2_upstream_cluster();
    const char* envoy_http_lua_ffi_v2_downstream_local_address();
    const char* envoy_http_lua_ffi_v2_downstream_remote_address();
    int64_t envoy_http_lua_ffi_v2_get_current_time_milliseconds();
    void envoy_http_lua_ffi_v2_file_log(const char *buf, size_t len);
]]

local table_elt_type = ffi.typeof("envoy_lua_ffi_table_elt_t*")
local table_elt_size = ffi.sizeof("envoy_lua_ffi_table_elt_t")

if envoy.stream.shared == nil then
    local proxy = {}
    local mt = {
        __index = function (t, k)

            local ref = C.envoy_http_lua_ffi_v2_get_shared_table()
            if ref > 0 then
                return registry[ref][k]
            else
                error("error get shared table reference: "..ref)
            end
        end,

        __newindex = function (t, k, v)

            local ref = C.envoy_http_lua_ffi_v2_get_shared_table()
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
    local header_map_size = C.envoy_http_lua_ffi_v2_get_header_map_size(source)
    if header_map_size == 0  then return nil end
    local raw_buf = ffi_new("envoy_lua_ffi_table_elt_t[?]", header_map_size)
    local pairs_buf = ffi_new("envoy_lua_ffi_string_pairs[1]", { [0] = {raw_buf, 0, header_map_size} })

    local rc = C.envoy_http_lua_ffi_v2_get_header_map(source, pairs_buf)
    if rc ~= FFI_OK then
        error("error get headers: "..tonumber(rc))
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
    return C.envoy_http_lua_ffi_v2_get_header_map_size(source)
end

local function get_header_map_value(source, key)
    if type(key) ~= "string" then
        error("header name must be a string", 2)
    end

    local buffer = ffi_new("envoy_lua_ffi_str_t[1]")
    local rc = C.envoy_http_lua_ffi_v2_get_header_map_value(source, key, #key, buffer)
    if rc ~= FFI_OK then
        return nil
    end
    return ffi_str(buffer[0].data, buffer[0].len)
end

local function set_headers(source, headers)
    if type(headers) ~= "table" then
        error("headers must be a table", 2)
    end

    local length = 0
    for key, value in pairs(headers) do 
        length = length + 1
    end
    local raw_buf = ffi_new("envoy_lua_ffi_table_elt_t[?]", length)
    local pairs_buf = ffi_new("envoy_lua_ffi_string_pairs[1]", { [0] = {raw_buf, length, length} })

    local index = 0
    for key, value in pairs(headers) do 
        pairs_buf[0].data[index].key.data = key
        pairs_buf[0].data[index].key.len = #key
        pairs_buf[0].data[index].value.data = value
        pairs_buf[0].data[index].value.len = #value
        index = index + 1
    end

    local rc = C.envoy_http_lua_ffi_v2_set_header_map(source, pairs_buf)
    if rc ~= FFI_OK then
        error("error set headers: "..tonumber(rc))
    end

end

local function set_header_map_value(source, key, value)
    if type(key) ~= "string" then
        error("header name must be a string", 2)
    end

    if type(value) ~= "string" then
        error("header value must be a string", 2)
    end

    local rc = C.envoy_http_lua_ffi_v2_set_header_map_value(source, key, #key, value, #value)
    if rc ~= FFI_OK then
        error("error set header")
    end
end

local function remove_header_map_value(source, key)
    if type(key) ~= "string" then
        error("header name must be a string", 2)
    end

    local rc = C.envoy_http_lua_ffi_v2_remove_header_map_value(source, key, #key)
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

function envoy.req.set_headers(headers)
    return set_headers(SOURCE_REQUEST, headers)
end

function envoy.resp.set_headers(headers)
    return set_headers(SOURCE_RESPONSE, headers)
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

local MAX_QUERY_ARGS_DEFAULT = 100
local MIN_QUERY_ARGS = 1
local MAX_QUERY_ARGS = 100

function envoy.req.get_query_parameters(max_args)
    if max_args == nil then
        max_args = MAX_QUERY_ARGS_DEFAULT
    else
        if type(max_args) ~= "number" then
            error("max_args must be a number", 2)
        end

        if max_args < MIN_QUERY_ARGS then
            error("max_args must be >= " .. MIN_QUERY_ARGS, 2)
        end

        if max_args > MAX_QUERY_ARGS then
            error("max_args must be <= " .. MAX_QUERY_ARGS, 2)
        end
    end

    local raw_buf = ffi_new("envoy_lua_ffi_table_elt_t[?]", max_args)
    local pairs_buf = ffi_new("envoy_lua_ffi_string_pairs[1]", { [0] = {raw_buf, 0, max_args} })

    local rc = C.envoy_http_lua_ffi_v2_get_query_parameters(pairs_buf)

    if rc ~= FFI_OK then
        error("error get queries: "..tonumber(rc))
    end

    if rc == 0 then
        local queries = {}
        local n = pairs_buf.size
        local buf = pairs_buf.data
        for i = 0, n - 1 do
            local h = buf[i]

            local key = h.key
            key = ffi_str(key.data, key.len)

            local val = h.value
            val = ffi_str(val.data, val.len)

            local existing = queries[key]
            if existing then
                if type(existing) == "table" then
                    existing[#existing + 1] = val
                else
                    queries[key] = {existing, val}
                end

            else
                queries[key] = val
            end

            queries[key] = val
        end

        return queries
    end

    return {}
end

function envoy.streaminfo.upstream_cluster()
    local res = C.envoy_http_lua_ffi_v2_upstream_cluster()
    if res == nil then
        return nil
    end

    return ffi_str(res)
end

function envoy.streaminfo.upstream_host()
    local res = C.envoy_http_lua_ffi_v2_upstream_host()
    if res == nil then
        return nil
    end

    return ffi_str(res)
end

function envoy.streaminfo.downstream_local_address()
    local res = C.envoy_http_lua_ffi_v2_downstream_local_address()
    if res == nil then
        return ""
    end

    return ffi_str(res)
end

function envoy.streaminfo.downstream_remote_address()
    local res = C.envoy_http_lua_ffi_v2_downstream_remote_address()
    if res == nil then
        return ""
    end

    return ffi_str(res)
end

function envoy.streaminfo.start_time()
    return tonumber(C.envoy_http_lua_ffi_v2_start_time())
end

function envoy.nowms()
    return tonumber(C.envoy_http_lua_ffi_v2_get_current_time_milliseconds())
end

function envoy.filelog(msg)
    if type(msg) ~= "string" then
        error("msg must be a string", 2)
    end

    C.envoy_http_lua_ffi_v2_file_log(msg, #msg);
end

function envoy.req.get_metadata(key, filter_name)
    if type(key) ~= "string" then
        error("metadata key must be a string", 2)
    end

    if not filter_name then
        error("filter name is required")
    end

    if type(filter_name) ~= "string" then
        error("filter name must be a string", 2)
    end
    
    local filter_name_ = ffi_new("envoy_lua_ffi_str_t[1]", { [0] = {#filter_name, filter_name} })
    local key_ = ffi_new("envoy_lua_ffi_str_t[1]", { [0] = {#key, key} })
    local value = ffi_new("envoy_lua_ffi_str_t[1]")
    local rc = C.envoy_http_lua_ffi_v2_get_metadata(filter_name_, key_, value)

    if rc == FFI_OK then
        return ffi_str(value[0].data, value[0].len)
    end

    return nil
end


local function get_body_value(source)
    local buffer = ffi_new("envoy_lua_ffi_str_t[1]")
    local rc = C.envoy_http_lua_ffi_v2_get_body(source, buffer)
    if rc ~= FFI_OK then
        return nil
    end
    return ffi_str(buffer[0].data, buffer[0].len)
end

function envoy.req.get_body()
    return get_body_value(SOURCE_REQUEST)
end

function envoy.resp.get_body()
    return get_body_value(SOURCE_RESPONSE)
end
