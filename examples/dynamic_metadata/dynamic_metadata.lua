require("rider.v2")

local envoy = envoy

local DynamicMetadataHandler = {}

DynamicMetadataHandler.version = "v2"

function DynamicMetadataHandler:on_request_header()
  envoy.req.set_dynamic_metadata("foo", "bar", "dynamic.metadata.test")
end

function DynamicMetadataHandler:on_response_header()
    local value = envoy.req.get_dynamic_metadata("foo", "dynamic.metadata.test")
    if (value == nil) then
        envoy.logErr("no dynamic metadata value for dynamic.metadata.test!")
        return
    end
    envoy.logInfo("dynamic metadata value: "..value)
end

return DynamicMetadataHandler
