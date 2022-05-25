require("rider")

local envoy = envoy
local get_req_header = envoy.req.get_header
local set_resp_header = envoy.resp.set_header
local ipairs = ipairs
local re_find = string.find
local respond = envoy.respond
local logDebug = envoy.logDebug
local logErr = envoy.logErr
--local inspect = require("inspect")

local json_validator = require("rider.json_validator")

-- See https://json-schema.org/understanding-json-schema for how to write json schema
local base_json_schema = {
    type = 'object',
    properties = {
        message = {
          type = 'string',
        },
        destination = {
          type = 'string',
        },
        source = {
          type = 'string',
        },
        external_service = {
          type = 'string',
        },
        external_service_authority = {
          type = 'string',
        },
        header_name = {
          type = 'string',
        }
    },
    required = {"source", "destination"},
}

local route_json_schema = {
    type = 'object',
    properties = {
        message = {
          type = 'string',
        },
        destination = {
          type = 'string',
        },
        source = {
          type = 'string',
        },
        external_service = {
          type = 'string',
        },
        external_service_authority = {
          type = 'string',
        },
        header_name = {
          type = 'string',
        }
    },
    required = {"source", "destination"},
}

json_validator.register_validator(base_json_schema, route_json_schema)

local echoHandler = {}

-- Source types specify where to get data.
-- Header: get a request header value by header_name argument.
-- Body: get request body.
-- Fib: get next Fibonacci number.
-- Static: use message argument.
local ENUM_SOURCE = {}
ENUM_SOURCE.Header = "Header"
ENUM_SOURCE.Body = "Body"
ENUM_SOURCE.Fib = "Fib"
ENUM_SOURCE.External = "External"
ENUM_SOURCE.Static = "Static"

-- Destination types specify where to set data.
-- Header: set to response header.
-- Body: sent a local reply with custom body.
local ENUM_DESTINATION = {}
ENUM_DESTINATION.Header = "Header"
ENUM_DESTINATION.Body = "Body"

local fibTable = {}
local fibTableIndex = 1

function echoHandler:on_configure()
  fibTable[1] = 0
  fibTable[2] = 1
  for i = 3, 100, 1 do
    fibTable[i] = fibTable[i-1] + fibTable[i-2]
  end
end

-- Must only be called in on_request.
local function get_message_from_source(config, result)
  if config.source == ENUM_SOURCE.Header then
    if #config.header_name == -1 then
      logErr("header_name is required when source.type is Header")
      result.error = 1
      return
    end
    result.message = get_req_header(config.header_name)
  elseif config.source == ENUM_SOURCE.FIB then
    result.message = tostring(fibTable[fibTableIndex])
    fibTableIndex = fibTableIndex % 99 + 1
  elseif config.source == ENUM_SOURCE.Static then
    result.message = config.message
  elseif config.source == ENUM_SOURCE.Body then
    local body = envoy.req.get_body()
    if body == nil then
      envoy.respond({[":status"] = 400}, "Please give body data!")
    end
    if body:length() == 0 then
      logErr("source type is Body but body is empty")
      result.error = 1
      return
    end
    result.message = body:getBytes(0, body:length())
  elseif config.source == ENUM_SOURCE.External then
    local headers, body = envoy.httpCall(
      config.external_service,
      {
        [":method"] = "POST",
        [":path"] = "/",
        [":authority"] = config.external_service_authority,
      },
      "hello world",
      5000)
    result.message = body
  else
    logErr("unknown source.type: "..tostring(config.source.type))
    result.error = 1
    return
  end
end

local function get_config()
  local base_config = envoy.get_base_config()
  local route_config = envoy.get_route_config()
  if route_config ~= nil and #route_config.source > 0 and #route_config.destination > 0 then
    return route_config
  end
  return base_config
end

function echoHandler:on_request()
  local config = get_config()
  local shared = envoy.stream.shared

  local metadata = envoy.req.get_metadata("api_id", "proxy.filters.http.rider")
  if metadata ~= nil then
    envoy.respond({[":status"] = 200}, metadata)
    return
  end

  get_message_from_source(config, shared)

  if config.destination == ENUM_DESTINATION.Body then
    envoy.respond({[":status"] = 200}, shared.message)
  end
end

function echoHandler:on_response()
  local config = get_config()
  local shared = envoy.stream.shared

  if shared.error == 1 then
    logDebug("skip handle response due to error")
    return
  end

  local dest_type = config.destination
  if dest_type == ENUM_DESTINATION.Header then
    set_resp_header(config.header_name, config.message)
  end
end

return echoHandler
