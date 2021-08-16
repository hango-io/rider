# Rider

## Introduction

Rider is a plugin framework which allows you to write Lua plugin for Envoy.

Features:

- Rider provide a SDK for plugin development.
- Most of SDK functions are implemented using [FFI](https://luajit.org/ext_ffi.html), which is much more fast compared to pure Lua functions.
- You can configure Lua plugin like other Envoy HTTP filters, and choose which configuration to use at runtime.
- You can add custom configuration validators. Rider provide a json schema validator by default.
- Lua plugin can be hot reload or load at runtime like Envoy HTTP filters.

Rider contains two components: 
- [C++ Envoy HTTP filter](https://github.com/hango-io/envoy-proxy/tree/main/source/filters/http/rider), which is modified from [Envoy Lua filter](https://github.com/envoyproxy/envoy/tree/v1.17.3/source/extensions/filters/http/lua)
- [Lua Plugin SDK](https://github.com/hango-io/rider)

## Docs

[Get started](./docs/get_started.md)

[Plugin configuration](./docs/configuration.md)

[Plugin development](./docs/development.md)

[SDK](./docs/api.md)


## TODO

- Support L4 plugin
- Support timer, metrics and other features supported by Envoy Wasm filter
- Support load plugin code from remote

## Thanks

The design of Rider comes from these awesome projects:
- [OpenResty](https://github.com/openresty/lua-resty-core): we learn from its source code about the implementation of FFI binding.
- Envoy [Lua filter](https://github.com/envoyproxy/envoy/tree/v1.17.3/source/extensions/filters/http/lua) and [Wasm filter](https://github.com/envoyproxy/envoy/tree/v1.17.3/source/extensions/filters/http/wasm): Rider HTTP filter is modified from Envoy Lua filter and the design refers to the Wasm filter.
- [Kong](https://github.com/Kong/kong): the SDK API style is from OpenResty and Kong's PDK.

Rider is started from an internal project at Netease. The original goal is to allow users write Lua plugins for Envoy API Gateway, like Kong plugins.
The first version was written by [YuXing Zeng](https://github.com/zengyuxing007), and then rewritten by [Tong Cai](https://github.com/caitong93) and [BaiPing Wang](https://github.com/wbpcode).

The latest version of Rider refers to [spec](https://github.com/proxy-wasm/spec/tree/master/abi-versions/vNEXT) and implementation of Wasm filter.
It's a design goal to provide a consistent user exprrience as Wasm filter.

## Notes

Internal version of Rider has been stable and used on production for a long time, tested with high concurrency and large traffic. But open source version is still under development,
so there is no garantee for stability. Please do as much as possible tests before use it on production.
