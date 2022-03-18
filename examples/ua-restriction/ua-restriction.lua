require("rider")
local envoy = envoy
local get_req_header = envoy.req.get_header
local ipairs = ipairs
local re_find = string.find
local respond = envoy.respond
local logDebug = envoy.logDebug

local uaRestrictionHandler = {}

local BAD_REQUEST = 400
local FORBIDDEN = 403

local MATCH_EMPTY     = 0
local MATCH_WHITELIST = 1
local MATCH_BLACKLIST = 2

local json_validator = require("rider.json_validator")

local base_json_schema = {
    type = 'object',
    properties = {},
}

local route_json_schema = {
    type = 'object',
    properties = {
      allowlist = {
        type = 'array',
        items = {
          type = 'string',
        },
      },
      denylist = {
        type = 'array',
        items = {
          type = 'string',
        },
      },
    },
}
json_validator.register_validator(base_json_schema, route_json_schema)

--- strips whitespace from a string.
local function strip(str)
  if str == nil then
    return ""
  end
  str = tostring(str)
  if #str > 200 then
    return str:gsub("^%s+", ""):reverse():gsub("^%s+", ""):reverse()
  else
    return str:match("^%s*(.-)%s*$")
  end
end

local function get_user_agent()
  return get_req_header("user-agent")
end

local function examine_agent(user_agent, allowlist, denylist)
  user_agent = strip(user_agent)

  if allowlist then
    for _, rule in ipairs(allowlist) do
      logDebug("allowist: compare "..rule.." and "..user_agent)
      if re_find(user_agent, rule) then
        return MATCH_WHITELIST
      end
    end
  end

  if denylist then
    for _, rule in ipairs(denylist) do
      logDebug("denylist: compare "..rule.." and "..user_agent)
      if re_find(user_agent, rule) then
        return MATCH_BLACKLIST
      end
    end
  end

  return MATCH_EMPTY
end

function uaRestrictionHandler:on_request()
  local config = envoy.get_route_config()
  if config == nil then
    return
  end

  logDebug("Checking user-agent");

  local user_agent = get_user_agent()
  if user_agent == nil then
    return respond({[":status"] = BAD_REQUEST}, "user-agent not found")
  end

  local match  = examine_agent(user_agent, config.allowlist, config.denylist)

  if match > 1 then
    logDebug("UA is now allowed: "..user_agent);
    return respond({[":status"] = FORBIDDEN}, "Forbidden")
  end
end

return uaRestrictionHandler
