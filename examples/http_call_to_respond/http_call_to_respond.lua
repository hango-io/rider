require("rider.v2")

local envoy = envoy

local exampleHandler = {}

exampleHandler.version = "v2"

function exampleHandler:on_request_header()
    local headers_1, body_1 = envoy.httpCall(
      "web_service",
      {
        [":method"] = "GET",
        [":path"] = "/",
        [":authority"] = "web_service"
      },
      nil,
      5000)

    local headers_2, body_2 = envoy.httpCall(
      "web_service",
      {
        [":method"] = "GET",
        [":path"] = "/",
        [":authority"] = "web_service"
      },
      nil,
      5000)

      body_2 = body_1..body_2
    
    for k,v in pairs(headers_1) do
        headers_2[k] = v
    end

    envoy.respond(headers_2, body_2)
    
end

return exampleHandler