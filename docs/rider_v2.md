# Rider V2

Version: v2alpha1

## Introduction

Rider V2 版本在 V1 版本的基础上做个更多的性能优化和功能增强的工作，同时可以兼容 V1 版本。具体的设计细节可以参考该[文章](https://cloudnative.to/blog/hango-rider/)。

这里我们将着重介绍 V2 版本的使用方式以及 V2 版本新增的 API，即在包含 V1 版本所有 API 的基础上新增的功能。

## 使用方式

### base 库及 version

首先在具体插件逻辑实现之前，require 的 base 库变成 `rider.v2`，同时在返回的 `exampleHandler` table 中设置 `version` 字段为 `v2`即可。

```
require("rider.v2")

local exampleHandler = {}
exampleHandler.version = "v2"
```

### 插件函数名

在 V1 版本中我们需要实现的插件函数阶段包括 `on_request` 和 `on_response` 阶段，而在 V2 版本中，出于性能优化的角度，我们将这两个阶段进一步细分为 `on_request_header`、`on_request_body`、`on_response_header`、`on_response_body` 四个阶段，即如果有 body 相关的处理则需要在对应的 body 处理函数中完成，举例：

```
require("rider.v2")

local envoy = envoy
local exampleHandler = {}
exampleHandler.version = "v2"

function exampleHandler:on_request_header()

end

function exampleHandler:on_request_body()
    local body = envoy.req.get_body()
    if (body == nil) then
        envoy.logErr("no body!")
        return
    end
    local header_to_add = ":path"
    envoy.req.set_header(header_to_add, body)
    envoy.req.clear_route_cache()
end

return exampleHandler
```

以上便是 V2 在使用上和 V1 的区别，只需要添加 `version`，修改函数名等极少量的变动即可完成。

## 新增 API

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

###  envoy.req.get_dynamic_metadata(key, filter_name)

获取 filter 中的 动态 metadata , 目前只支持获取 `string` 和 `integer`

Parameter

- key:  string, key specifies key of the value
- filter_name: string, filter_name specifies from which filter to get dynamic metadata

Return

- a string for the value
- nil if not found

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
