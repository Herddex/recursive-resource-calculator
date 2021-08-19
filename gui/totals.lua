local Report = require "report"
local Totals = {}

--Build a new totals section into the given parent gui element and returns it
function Totals.new(parent)
    return parent.add{type = "flow"}
end

function Totals.update(totals_table_flow)
    totals_table_flow.clear()
    Report.new(totals_table_flow, global[totals_table_flow.player_index].total_production_rates)
end

function Totals.update_crafting_machines(totals_table_flow)
    Report.update_crafting_machines(totals_table_flow.report)
end

return Totals