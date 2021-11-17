require("rider.v2")

local envoy = envoy

local bodyHandler = {}

bodyHandler.version = "v2"

function bodyHandler:on_request_header()
    local header = envoy.req.get_header("test")
    if header == nil then
        envoy.logDebug("no req_header");
    else
        envoy.logDebug("req_header: "..header);
    end

    local headers, body = envoy.httpCall(
      "web_service",
      {
        [":method"] = "GET",
        [":path"] = "/",
        [":authority"] = "web_service"
      },
      nil,
      5000)
    envoy.logDebug("httpcall_req_body1: "..body);


end

function bodyHandler:on_request_body()


    local headers, body2 = envoy.httpCall(
      "web_service",
      {
        [":method"] = "GET",
        [":path"] = "/",
        [":authority"] = "web_service"
      },
      nil,
      5000)
    envoy.logDebug("httpcall_resp_body3: "..body2);

    envoy.respond({[":status"] = 200}, "ddddd")

end

function bodyHandler:on_response_header()
    local header = envoy.resp.get_header("test")
    if header == nil then
        envoy.logDebug("no resp_header");
        return
    end
    envoy.logDebug("resp_header: "..header);

    local headers, body2 = envoy.httpCall(
      "web_service",
      {
        [":method"] = "GET",
        [":path"] = "/",
        [":authority"] = "web_service"
      },
      nil,
      5000)
    envoy.logDebug("httpcall_resp_body3: "..body2);

end

function bodyHandler:on_response_body()
    local body = envoy.resp.get_body()
    if body == nil then
        envoy.logDebug("no resp_body");
        return
    end
    envoy.logDebug("resp_body: "..body);
    local headers, body2 = envoy.httpCall(
      "web_service",
      {
        [":method"] = "GET",
        [":path"] = "/",
        [":authority"] = "web_service"
      },
      nil,
      5000)
    envoy.logDebug("httpcall_resp_body3: "..body2);
end

return bodyHandler
