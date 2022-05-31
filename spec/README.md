# Rider Plugin Image Specification

This document provides the steps to generate the `rider plugin image` which will be fetched by `pilot agent` in future plan.

## Steps

* First, we prepare the following Dockerfile:
```
$ cat Dockerfile

FROM scratch

COPY plugin.lua ./
```
**Note: you must have exactly one `COPY` instruction in the Dockerfile in order to end up having only one layer in produced images**

* Then, build your image via `docker build` command
```
$ docker build . -t my-registry/mylua:0.1.0
```

* Finally, push the image to your registry via `docker push` command
```
$ docker push my-registry/mylua:0.1.0
```

## Reference
* https://github.com/solo-io/wasm/blob/master/spec/spec-compat.md
