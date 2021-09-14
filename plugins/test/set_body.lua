require("rider")

local envoy = envoy

local bodyHandler = {}

function bodyHandler:on_request()
  local str = "I am req body"
  envoy.req.set_body(str)
  local body = envoy.req.get_body()
  local body_str = body:getBytes(0, body:length())
  envoy.logDebug("req_body: "..body_str);
end

function bodyHandler:on_response()
  local str = "I am resp body"
  envoy.resp.set_body(str)
  local body = envoy.resp.get_body()
  local body_str = body:getBytes(0, body:length())
  envoy.logDebug("resp_body: "..body_str);
end

return bodyHandler
