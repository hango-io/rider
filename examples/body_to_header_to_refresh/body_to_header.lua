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