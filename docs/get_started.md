# Get started

## Prerequisites

Need to install: docker, docker-compose

## Run echo plugin

```
./scripts/dev/local-up.sh
```

以上命令会在本地以容器的方式启动 Envoy。Envoy 已经配置好了 [echo](../plugins/echo) 插件。
echo 插件是一个专门用于展示 SDK 用法的插件，它的效果是根据 `source` 获取数据，再根据 `destination` 设置数据，例如提取 request body 然后在 response 中返回。echo 插件会优先使用 VirtualHost 和 Route 中的配置。

docker-compose 配置文件: [docker-compose.yaml](../scripts/dev/docker-compose.yaml)。Envoy 的 80 端口映射到本地的 8002。

Envoy 配置文件: [envoy.yaml](../scripts/dev/envoy.yaml)
在 80 listener 上，配置的路由分别为:


### Route 1

```yaml
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

上面的配置表示，使用 `message` 指定的数据，写入响应的 header 中，header name 由 `header_name` 指定。

```
#curl -v  http://127.0.0.1:8002/static-to-header  
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to 127.0.0.1 (127.0.0.1) port 8002 (#0)
> GET /static-to-header HTTP/1.1
> Host: 127.0.0.1:8002
> User-Agent: curl/7.58.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< x-powered-by: Express
< content-type: application/json; charset=utf-8
< content-length: 542
< etag: W/"21e-zjYcDx3cTx63FXVYM8xG6WwsQQw"
< date: Mon, 19 Jul 2021 13:07:02 GMT
< x-envoy-upstream-service-time: 2
< x-echo-foo: Lua is awesome!
< server: envoy
```

可以看到 response 中 `x-echo-foo` header 已经设置了。

### Route 2

```yaml
              - match:
                  prefix: "/external-to-body"
                route: 
                  cluster: web_service
                typed_per_filter_config:
                  proxy.filters.http.rider:
                    "@type": type.googleapis.com/proxy.filters.http.rider.v3alpha1.RouteFilterConfig
                    plugins:
                      - name: echo
                        config:
                          external_service: example_service
                          external_service_authority: example.com
                          source: External
                          destination: Body
```

该配置表示，访问 exmaple.com 获取 body 后，再将 body 数据作为 response body 返回

```
#curl http://127.0.0.1:8002/external-to-body   
<!doctype html>
<html>
<head>
    <title>Example Domain</title>
...
```

### Route 3

```yaml
              - match:
                  prefix: "/body-to-body"
                route: 
                  cluster: web_service
                typed_per_filter_config:
                  proxy.filters.http.rider:
                    "@type": type.googleapis.com/proxy.filters.http.rider.v3alpha1.RouteFilterConfig
                    plugins:
                      - name: echo
                        config:
                          source: Body
                          destination: Body
```

该配置表示，读取 request body 再设置到本地返回 response 中的 body 中。

```
#curl  http://127.0.0.1:8002/body-to-body --data "hello world"  
hello world%  
```

### Route 4

```yaml
              - match:
                  prefix: "/"
                route: 
                  cluster: web_service
```

这条路由会匹配不满足上面的路由的其他所有请求。由于没有定义 echo plugin 配置，echo plugin 会使用 base config。

```
#curl  http://127.0.0.1:8002/aaaaaa                           
C++ is awesome!%
```