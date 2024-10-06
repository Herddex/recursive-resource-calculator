local Report = require "gui/report"
local compute_power_and_pollution = require "logic.compute_power_and_pollution"

local Totals = {}

--Build a new totals section into the given parent gui element and return it
function Totals.new(parent)
    return parent.add{type = "flow"}
end

function Totals.update(totals_table_flow)
    totals_table_flow.clear()
    local player_index = totals_table_flow.player_index
    local production_rates = global[player_index].total_production_rates
    local energy_consumption, pollution = compute_power_and_pollution(player_index, production_rates)
    Report.new(totals_table_flow, production_rates, energy_consumption, pollution)
end

return Totals