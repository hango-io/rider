local config = require("rider.config")
local jsonschema = require("jsonschema")
local inspect = require("inspect")

local exports = {}

local function register_validator(base_config_schema, route_config_schema)
    local base_config_validator
    if base_config_schema ~= nil then
        local validator = jsonschema.generate_validator(base_config_schema)
        base_config_validator = function(base_config_object)
            local result, err = validator(base_config_object, base_config_schema)
            if not result then
                return config.VALIDATE_FAIL, "base config validate failed: "..inspect(err)
            end

            return config.VALIDATE_OK
        end
    end

    local route_config_validator
    if route_config_schema ~= nil then
        local validator = jsonschema.generate_validator(route_config_schema)
        route_config_validator = function(route_config_object)
            local result, err = validator(route_config_object, route_config_schema)
            if not result then
                return config.VALIDATE_FAIL, "route config validate failed: "..inspect(err)
            end

            return config.VALIDATE_OK
        end
    end

    config.register_config_validator(base_config_validator, route_config_validator)
end
exports.register_validator = register_validator

return exports