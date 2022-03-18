require("rider.v2")
local envoy = envoy
local get_header = envoy.req.get_header
local set_header = envoy.req.set_header
local rm_header = envoy.req.remove_header
local get_body = envoy.resp.get_body

local bodyHandler = {}

bodyHandler.version = "v2"

function bodyHandler:on_request_header()
    for i = 1, 20, 1 do
        set_header("test"..i, "hahahaha")
    end
    for i = 1, 10, 1 do
        local header = get_header("test"..i)
        if header ~= "hahahaha" then 
            logErr("header mistach!")
        end
    end

    for i = 1, 20, 1 do
        rm_header("test"..i)
    end

end

function bodyHandler:on_response_body()
    for i = 1, 30, 1 do
        local body = get_body()
    end
end

return bodyHandler
