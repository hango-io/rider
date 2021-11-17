require("rider")

local envoy = envoy

local bodyHandler = {}

function bodyHandler:on_request()
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
    envoy.logDebug("httpcall_resp_body1: "..body);

    local headers2, body2 = envoy.httpCall(
      "web_service",
      {
        [":method"] = "GET",
        [":path"] = "/",
        [":authority"] = "web_service"
      },
      nil,
      5000)
    envoy.logDebug("httpcall_resp_body2: "..body2);

    envoy.respond({[":status"] = 200}, "ddddd")
end

function bodyHandler:on_response()
  local body = envoy.resp.get_body()
  if body == nil then
      envoy.logDebug("no resp_body");
      return
  end
  local string = body:getBytes(0, body:length())
  envoy.logDebug("resp_body: "..string);
end

return bodyHandler
