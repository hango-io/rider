# 配置

## 从 Envoy 的 HTTP 插件配置说起

首先所有的 HTTP 插件都是 `http_connection_manager` 这个 L4 插件的子插件。
当我们说新增一个 HTTP 插件时，指的是在 `http_connection_manager` 的 `http_filters` 中增加一项。
在新增项的 `typed_config` 中可以填写该 HTTP 插件的配置。这里的配置对整个 Listener 接收的流量都会生效。
如果用户想要为不同的 VirtualHost，不同的 Route 做不同的配置，Envoy 在 VirtualHost 和 Route 中提供了 `typed_per_filter_config`，
这是一个 map，key 为插件的名字，value 为配置数据。插件可以按照自身需求，去取不同层级的配置。

## Lua plugin 配置

Rider 也是一个 HTTP 插件，相当于是一个盒子，将用户写的 Lua plugin 加载进来运行，和 plugin 是一对一的关系。
如果要运行多个 Lua plugin，则需要添加多个 Rider 插件，每个 Rider 插件内部配置不同的 Lua plugin。
因此 Lua plugin 在 Envoy 中可添加配置的地方和 HTTP 插件一样也是有三处。

首先是 `http_filters` 中，`Rider` 插件的 `typed_config.plugin.config` 是基础配置，可以在 plugin 中通过 `envoy.get_baseconfig` 获取到。

```yaml
          http_filters:
          - name: proxy.filters.http.rider
            typed_config:
              "@type": type.googleapis.com/proxy.filters.http.rider.v3alpha1.FilterConfig
              plugin:
                vm_config:
                  package_path: "/usr/local/lib/rider/?/init.lua;/usr/local/lib/rider/?.lua;"
                code:
                  local:
                    filename: /usr/local/lib/rider/plugins/echo/echo.lua
                name: echo
                config:
                  message: "C++ is awesome!"
                  source: Static
                  destination: Body
```

然后 `VirtualHost` 和 `Route` 中可以配置 `typed_per_filter_config`，key 为 Rider 插件的名字，value 为一个列表，其中
每一项有 name 和 config 两个字段，name 对应 Lua plugin 的 name，config 是配置数据。当调用 `envoy.config.get_route_config` 时，
Rider 会依次去看 Route 和 VirtualHost 的 `typed_per_filter_config`，如果有 Rider 插件，那么就用 name 在列表中匹配，返回第一个匹配到的配置项。

```yaml
              routes:
              - match:
                  prefix: "/static-to-header"
                route: 
                  cluster: web_service
                typed_per_filter_config:
                  proxy.filters.http.rider:
                    "@type": type.googleapis.com/proxy.filters.http.rider.v3alpha1.RouteFilterConfig
                    plugins:
                      - name: echo
                        config:
                          message: "Lua is awesome!"
                          source: Static
                          destination: Header
                          header_name: x-echo-foo
```

完整的示例可以参考 [envoy.yaml](../scripts/dev/envoy.yaml)

## 配置校验

### Json validator

以 echo plugin 为例， 下面是该 plugin 的配置 schema 定义:

```lua
local base_json_schema = {
    type = 'object',
    properties = {
        message = {
          type = 'string',
        },
        destination = {
          type = 'string',
        },
        source = {
          type = 'string',
        },
        external_service = {
          type = 'string',
        },
        external_service_authority = {
          type = 'string',
        },
        header_name = {
          type = 'string',
        }
    },
    required = {"source", "destination"},
}

local route_json_schema = {
    type = 'object',
    properties = {
        message = {
          type = 'string',
        },
        destination = {
          type = 'string',
        },
        source = {
          type = 'string',
        },
        external_service = {
          type = 'string',
        },
        external_service_authority = {
          type = 'string',
        },
        header_name = {
          type = 'string',
        }
    },
    required = {"source", "destination"},
}

json_validator.register_validator(base_json_schema, route_json_schema)
```

Schema 的定义可以参照 [json schema](https://json-schema.org/understanding-json-schema), 定义好 schema 后需要调用 `register_validator` 完成注册。

### Custom validator

自定义 validator 可以参考 [json_validator](https://github.com/hango-io/rider/blob/master/rider/json_validator.lua) 的实现。

```lua
local config = require("rider.config")

-- @param: config, a string contains configuration data
-- @return: enum, config.VALIDATE_OK if config is valid, otherwise config.VALIDATE_FAIL
-- @return: string, error message if the first return value is config.VALIDATE_FAIL
local function base_config_validator(config)
  if config_is_valid(config) then
    return config.VALIDATE_OK
  else
    return 
  end
end

local function route_config_validator(config)
  if config_is_valid(config) then
    return config.VALIDATE_OK
  else
    return 
  end
end

-- Register validators
config.register_config_validator(base_config_validator, route_config_validator)
```

首先定义两个函数分别用于校验 base config 和 route config, 然后调用 `register_config_validator` 注册自定义的 validator。
如果 base config 校验错误，Envoy 会拒绝加载对应的 Listener，如果 route config 校验错误，Envoy 会输出错误日志，跳过后续的插件代码，继续处理请求。

## Rider 自身配置

```yaml
          http_filters:
          - name: proxy.filters.http.rider
            typed_config:
              "@type": type.googleapis.com/proxy.filters.http.rider.v3alpha1.FilterConfig
              plugin:
                vm_config:
                  package_path: "/usr/local/lib/rider/?/init.lua;/usr/local/lib/rider/?.lua;"
                code:
                  local:
                    filename: /usr/local/lib/rider/plugins/echo/echo.lua
                name: echo
                config:
                  message: "C++ is awesome!"
                  source: Static
                  destination: Body
```

所有配置目前都在 `typed_config.plugin` 这一级下，下面解释各个字段

### vm_config

可以配置 Lua 虚拟机。
可配置项:

`vm_id`: 虚拟机 id, id 相同的 Rider filter 共用一个 Lua VM, 默认为 0
`package_path`: 可以配置 `_G.package.path`

### code

获取代码的配置，目前只支持本地文件

`local.filename` 本地代码路径

For details, see [Rider filter proto](https://github.com/hango-io/envoy-proxy/blob/main/api/proxy/filters/http/rider/v3alpha1/rider.proto).

### name

Plugin name, 需要唯一

### conifg

Plugin configuration
