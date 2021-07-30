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
            local crafting_machine
            if #global.crafting_machines_for_category[category] == 1 then
                crafting_machine = global.crafting_machines_for_category[category][1]
            else
                local crafting_machine_name = global[report.player_index].crafting_machine_buttons[category].elem_value
                if crafting_machine_name then
                    crafting_machine = game.entity_prototypes[crafting_machine_name]
                else
                    game.get_player(parent.player_index).create_local_flying_text{
                        text = {
                            "",
                            {"hxrrc.preference_not_found_for_category_1"},
                            category .. ".\n",
                            {"hxrrc.preference_not_found_for_category_2"},
                            },
                        create_at_cursor = true,
                    }
                    report.destroy()
                    return
                end
            end

            --the machine:
            local crafting_machine_sprite = "item/" .. crafting_machine.name
            machine_flow.add{type = "sprite", sprite = crafting_machine_sprite, tooltip = crafting_machine.localised_name}

            --the machine amount:
            local machine_amount = Decomposer.machine_amount(sprite, production_rate, crafting_machine)
            machine_flow.add{type = "label", caption = " x " .. Rational.to_string(machine_amount), tooltip = "~" .. tostring(Rational.numerical_approximation(machine_amount)) .. "/s"}
        else
            report.add{type = "empty-widget"}
        end
    end
end

return Report