## Plugin development

### Run with docker-compose

一般的本地开发模式是: 编写插件 -> 构建镜像(将插件打包到 envoy base 镜像中) -> 启动 Envoy 和一个后端 app -> 向 Envoy 发送请求

可以使用 [scripts/dev/local-up.sh](../scripts/dev/local-up.sh) 来启动本地部署

**安装 docker-compose**

本地部署依赖 docker-compose , 如果没有需要先安装 https://docs.docker.com/compose/install/

**修改本地 envoy 配置**

修改 `./scripts/envoy.yaml`, 将需要测试的插件加到配置里

**启动本地部署**

```
./scripts/dev/local-up.sh
```

启动后, envoy 默认监听本地 8002 端口，通过 `curl -v localhost:8002` 访问

**停止本地部署**

```
./scripts/dev/local-down.sh
```
