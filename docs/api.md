# Rider SDK

Version: v1alpha1

## Introduction

Rider SDK 定义了编写插件需要用到的 API。

Rider 提供了一个名为 `envoy` 全局可见的对象, 用户可以用 `envoy.*` 的形式调用 SDK。

建议采用下面的方法, 使用本地变量将 `envoy` 以及用到的方法缓存下来, 通过减少查找来提高性能

``` lua
local envoy = envoy

local get_request_header = envoy.req.get_header
```

而不是直接使用

``` lua
local foo = envoy.req.get_header("foo")
```

插件中所定义所有函数, 都建议声明为 `local`, 避免全局可见。


## envoy.req

### envoy.req.get_header(name)

获取指定的 header

Parameter

- name: header name

Return

- a string for header value
- nil if not exist 

### envoy.req.get_header_size(name)

获取指定 header 的 value 数量

Parameter

- name: header name

Return

- a int for header size

### envoy.req.get_header_index(name, index)

获取指定 header 的 第 index 个 value

Parameter

- name: header name
- index: header index

Return

- a string for header value at index
- nil if not exist 

### envoy.req.get_headers()

获取所有 header

Return

- a table, key is header name, value is header value

```lua
local get_request_headers = envoy.req.get_headers

function handler:on_request(conf, handle)
    local headers =  get_request_headers
    for key, val in pairs(headers) do INFO_LOG(key, val) end
end
```

### envoy.req.get_body()

获取 request body, 该方法会使 coroutine yield 直至获取到所有 body

当 buffer 的数据超过 [`per_connection_buffer_limit_bytes`](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener.proto)(默认为 1M), envoy 会返回 413 错误

Return

- `table` a buffer object represents the request body

返回的对象有两个方法

- `length()` 返回 `number`  body 字节数
- `getBytes(start, end)` 返回 `string` body 内容, 从 start 到 end - 1

Usage

``` lua
    local body = envoy.req.get_body()
    envoy.logDebug("body is: "..body:getBytes(0, body:length())) --- "body is: hello world"
```

###  envoy.req.get_metadata(key, filter_name)

获取 route 中的 metadata , 目前只支持获取 `string` 和 `integer`

Parameter

- key:  string, key specifies key of the value
- filter_name: string, filter_name specifies from which filter to get metadata

Return

- a string for the value
- nil if not found

例如, 获取下面配置中的 `api_id` 

``` lua
envoy.req.get_metadata("api_id", "metadatahub")
```

``` yaml
virtual_hosts:
- name: local_service
  domains:
    - "foo.com"
  routes:
  - match:
      prefix: "/"
    route: 
      cluster: web_service
    metadata:
      filter_metadata:
        com.netease.metadatahub:
          api_id: 11111
          svc_id: "svc_id_test"
```

###  envoy.req.get_dynamic_metadata(key, filter_name)

获取 filter 中的 动态 metadata , 目前只支持获取 `string` 和 `integer`

Parameter

- key:  string, key specifies key of the value
- filter_name: string, filter_name specifies from which filter to get dynamic metadata

Return

- a string for the value
- nil if not found

### envoy.req.set_header(name, value)

设置一个 header,  如果原来存在则覆盖

Parameter

- name:  string, header name
- value: string, header value

Return

- No return value

### envoy.req.set_headers(headers)

设置所有 header

Parameter

- headers: table, header table

Return

- No return value

```lua
local set_request_headers = envoy.req.set_headers

function handler:on_request_header()
    set_request_headers({[":path"] = "/haha", [":method"] = "GET"})
end
```

### envoy.req.clear_header(name)

移除指定的 header

Parameter

- name:  string, header name

Return

- No return value

### envoy.req.clear_route_cache()

使用场景，请求阶段可以调用该函数来清除路由缓存，下一次获取路由时会重新计算路由

Return

- No return value

## envoy.resp

### envoy.resp.set_header(name, value)

设置 header, 如果原来存在则覆盖

Parameter

Return

### envoy.resp.get_header(name)

获取指定的 header

Parameter

- name: string, header name

Return

- a string for header value
- nil if not exist

### envoy.resp.get_header_size(name)

获取指定 header 的 value 数量

Parameter

- name: header name

Return

- a int for header size

### envoy.resp.get_header_index(name, index)

获取指定 header 的 第 index 个 value

Parameter

- name: header name
- index: header index

Return

- a string for header value at index
- nil if not exist 

### envoy.resp.get_headers()

获取所有 header

Return

- No return value

### envoy.resp.clear_header(name)

移除指定的 header

Parameter

- name:  string, header name

Return

- No return value

## envoy.stream.shared

用于保存临时变量，在请求结束时被释放。通常用于在 request 阶段存储一些信息,在 response 阶段引用

``` lua
local envoy = envoy

local get_req_headers = envoy.req.get_headers

function handler:on_request(conf, handle)
    envoy.stream.shared.original_headers = get_req_headers()

    -- Then modify headers
end

function handler:on_response(conf, handle)
    local original_headers = envoy.stream.shared.original_headers
end
```

`envoy.stream.shared` 生命周期不能超过请求的生命周期, 像下面的代码会引起异常

```lua
local envoy = envoy

local foo

function handler:on_request(conf, handle)
    foo = envoy.stream.shared
end

function handler:on_response(conf, handle)
    foo.x = y
end
```

## envoy.httpCall(cluster, headers, body, timeout)

发送异步 http 请求, coroutine 会 yield 直到请求返回

`cluster` 参数对应 envoy 中配置的 cluster
`headers` 中可以通过 `:method`, `:path`, `:authority` 来配置 http method, url (https://en.wikipedia.org/wiki/URL)

Parameter

- cluster(string, required): upstream cluster
- headers(table, required): request headers
- body(string, optional): request body, nil for empty body
- timeout(number, required): timeout in milliseconds

Return

- `table` response headers
- `string` response body, nil for empty body

Usage

``` lua
    local headers, resp_body = envoy.httpCall(
        "security-server",
        {
            [":method"] = "POST",
            [":path"] = "/",
            [":authority"] = "security-server"
        },
        "hello world",
        1000
    ) --- POST http://security-server/

    if resp_body then
      envoy.logDebug("response body lengh: "..#resp_body)
    end
```

## envoy.respond(headers, body)

直接向 downstream 发送 response, 必须在 `on_request` 阶段执行, 调用后从插件逻辑返回, 后续代码不会再执行

Parameter

- headers(table, required): response headers
- body(string, optional): response body

Return

- nil

Usage

``` lua
    local host = envoy.req.get_header(":authority")
    if host == "bar.com" then
        envoy.respond({[":status"] = 403}, "nope")
    end
```

## envoy.filelog(msg)

Parameter

- msg(string, required): message

Return

- nil

Usage

``` lua
    envoy.filelog("write to file")
```

## envoy.streaminfo 

### envoy.streaminfo.start_time()

The time that the first byte of the request was received.

Return

- `number` unix timestamp in milliseconds 

Usage

``` lua
envoy.streaminfo.start_time() --- 1591168355117
```

### envoy.streaminfo.current_time_milliseconds()

Current time in milliseconds.

Return

- `number` unix timestamp in milliseconds 

Usage

``` lua
envoy.streaminfo.current_time_milliseconds() --- 1591168355453
```

### envoy.streaminfo.downstream_local_address()

The downstream local address.

Return

- `string` 

Usage

``` lua
envoy.streaminfo.downstream_local_address() --- 127.0.0.1:8000
```

### envoy.streaminfo.downstream_remote_address()

The downstream remote ddress.

Return

- `string` 

Usage

``` lua
envoy.streaminfo.downstream_remote_address() --- 127.0.0.1:51042
```

### envoy.streaminfo.upstream_cluster()

The upstream cluster.

Return

- `string` cluster name
- `nil` if not exist

Usage

``` lua
envoy.streaminfo.upstream_cluster() --- web_service
```

### envoy.streaminfo.upstream_host()

The upstream host.

Return

- `string` host address
- `nil` if not exist

Usage

``` lua
envoy.streaminfo.upstream_host() --- 127.0.0.1:8000
```

## 打印日志

通过下面的函数可以利用 envoy 的日志接口打印信息(msg is string type)

- envoy.logErr(msg)
- envoy.logWarn(msg)
- envoy.logInfo(msg)
- envoy.logDebug(msg)
- envoy.logTrace(msg)

``` lua
local logInfo = envoy.logInfo

logInfo("hello envoy")
```

## Metric

### envoy.define_metric(metric_type, metric_name)

Define metric.

Parameter

- metric_type: int, 0 for Counter, 1 for Gauge, 2 for Histogram
- metric_name: string, metric name

Return

- int, >0 for metric id, <0 for error

### envoy.increment_metric(metric_id, offset)

Increment metric.

Parameter

- metric_id: int, metric_id return from envoy.define_metric
- offset: int, offset

Return

- No return value

### envoy.record_metric(metric_id, value)

Record metric.

Parameter

- metric_id: int, metric_id return from envoy.define_metric
- value: int, value

Return

- No return value

### envoy.get_metric(metric_id)

Record metric.

Parameter

- metric_id: int, metric_id return from envoy.define_metric

Return

- int, >0 for metric value, <0 for error

Usage

``` lua
    local metric_id = envoy.define_metric(0, "test")
    if metric_id < 0 then
        error("define metric errror")
    end
    envoy.increment_metric(metric_id, 1)
    envoy.record_metric(metric_id, 1)
    local metric_value = envoy.get_metric(metric_id)
    if metric_value < 0 then
        error("get metric errror")
    end
```