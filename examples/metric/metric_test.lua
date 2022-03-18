require("rider.v2")

local envoy = envoy

local MetricHandler = {}

MetricHandler.version = "v2"


function MetricHandler:on_request_header()
    if not metric_id  then
        metric_id = envoy.define_metric(0, "test")
        if metric_id < 0 then
            error("define metric errror")
        end

    end
    envoy.increment_metric(metric_id, 1)
    envoy.record_metric(metric_id, 1)
    local metric_value = envoy.get_metric(metric_id)
    if metric_value < 0 then
        error("get metric errror")
    end
    envoy.logInfo("metric value: "..metric_value)
end

return MetricHandler
