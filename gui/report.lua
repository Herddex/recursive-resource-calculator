local Rational = require "utils/rational"
local Decomposer = require "logic/decomposer"

Report = {}

--[[
    Receives an ordered topologically sorted list of items, as well as a dictionary mapping each said item to a production rate, to build the final intermediate production rates report
]]
function Report.new(parent, list, total_production_rates)
    local report = parent.add{type = "table", column_count = 2, draw_horizontal_lines = true, draw_vertical_lines = true}

    for _, sprite in ipairs(list) do
        --item and production rate cell:
        local item_flow = report.add{type = "flow"}
        item_flow.add{type = "sprite", sprite = sprite}
        local production_rate = total_production_rates[sprite]
        item_flow.add{type = "label", caption = Rational.to_string(production_rate) .. " /s ", tooltip = "~" .. tostring(Rational.numerical_approximation(production_rate)) .. "/s"}

        --crafting machine cell:
        local recipes = global.recipes[sprite]
        if recipes then
            local machine_flow = report.add{type = "flow"} 
            local category = recipes[1].category
            local crafting_machine = #global.crafting_machines_for_category[category] == 1 and global.crafting_machines_for_category[category][1] or
            game.entity_prototypes[global[report.player_index].crafting_machine_buttons[category].elem_value]

            --the machine:
            local crafting_machine_sprite = "item/" .. crafting_machine.name
            machine_flow.add{type = "sprite", sprite = crafting_machine_sprite}

            --the machine amount:
            local machine_amount = Decomposer.machine_amount(sprite, production_rate, crafting_machine)
            machine_flow.add{type = "label", caption = " x " .. Rational.to_string(machine_amount)}
        else
            report.add{type = "empty-widget"}
        end
    end
end

return Report