local ModuleGUI = require "modulegui"
local Decomposer = require "logic/decomposer"

local Report = {}

local function add_header(report, caption, tooltip)
    local header = report.add{type = "flow"}
    header.style.horizontally_stretchable = true
    header.style.horizontal_align = "center"
    local label = header.add{type = "label", caption = caption, tooltip = tooltip}
    label.style.right_padding = 4
end

--Receives a dictionary mapping each item/fluid to a production rate, to build the final intermediate items' production rates report
function Report.new(parent, production_rates)
    local report = parent.add{type = "table", name = "report", column_count = 4, draw_horizontal_lines = true, draw_vertical_lines = true}
    local player_index = report.player_index

    --Total energy consumption, pollution, headers:
    add_header(report, {"", {"hxrrc.consumption"}, ":"}, {"hxrrc.consumption_header_tooltip"})
    report.add{type = "flow", name = "consumption_flow"}
    add_header(report, {"", {"hxrrc.pollution"}, ":"}, {"hxrrc.pollution_header_tooltip"})
    report.add{type = "flow", name = "pollution_flow"}
    for _, caption in ipairs({
        {"hxrrc.production_rates_table_header"},
        {"hxrrc.machine_counts_table_header"},
        {"hxrrc.modules"},
        {"hxrrc.recipes_used_table_header"}}) do
            add_header(report, caption)
    end
    local total_energy_usage = 0
    local total_pollution = 0

    for item_or_fluid_full_name, production_rate in pairs(production_rates) do
        --Item/fluid and its production rate cell:
        local item_cell = report.add{type = "flow"}
        item_cell.style.horizontally_stretchable = true

        local slash_position = string.find(item_or_fluid_full_name, "/", 1, true)
        local type = slash_position == 5 and "item" or "fluid"
        local short_name = string.sub(item_or_fluid_full_name, slash_position + 1)
        local prototype = type == "item" and game.item_prototypes[short_name] or game.fluid_prototypes[short_name]
        item_cell.add{type = "sprite", sprite = item_or_fluid_full_name, tooltip = prototype.localised_name}
        
        item_cell.add{type = "label", caption = production_rate .. " /s "}

        local recipes = global.recipes[item_or_fluid_full_name]
        local recipe = global[player_index].recipe_preferences[item_or_fluid_full_name]
        if recipes then
            --Crafting machine and module cells:
            if production_rate < 0 then
                report.add{type = "label", caption = {"hxrrc.byproduct"}} --byproduct that has to be pulled out of the system
                report.add{type = "empty-widget"}
            elseif not recipe then --the item is not a byproduct, but the player has no recipe selected
                report.add{type = "label", caption = {"hxrrc.unselected_recipe"}}
                report.add{type = "empty-widget"}
            else --the player has a recipe selected and the item/fluid has a positive production rate, so a crafting machine cell will be placed
                local machine_cell = report.add{type = "flow"}
                machine_cell.style.horizontally_stretchable = true
                
                local category = recipe.category
                local crafting_machine = global[player_index].crafting_machine_preferences[category]

                --the machine:
                machine_cell.add{
                    type = "choose-elem-button",
                    name = "hxrrc_choose_crafting_machine_button",
                    elem_type = "entity",
                    entity = crafting_machine.name,
                    elem_filters = {{filter = "crafting-category", crafting_category = category}},
                    enabled = #global.crafting_machines_by_category[category] > 1,
                }

                --the machine amount:
                local machine_amount = Decomposer.machine_amount(item_or_fluid_full_name, production_rate, crafting_machine, player_index)
                local label = machine_cell.add{type = "label", name = "label"}
                label.caption = " x " .. machine_amount

                --consumption and pollution calculations:
                local energy_consumption_multiplier = Decomposer.module_effect_multiplier(player_index, recipe.name, "consumption")
                total_energy_usage = total_energy_usage + crafting_machine.energy_usage * 60 * machine_amount * energy_consumption_multiplier
                assert(global.pollution_per_minute_of_crafting_machines[crafting_machine.name])
                total_pollution = total_pollution + global.pollution_per_minute_of_crafting_machines[crafting_machine.name] * machine_amount * Decomposer.module_effect_multiplier(player_index, recipe.name, "pollution") * energy_consumption_multiplier
                
                --Module cell:
                ModuleGUI.new(report, recipe.name, crafting_machine.allowed_effects)
            end

            --Recipe cell:
            local recipe_cell = report.add{type = "flow"}
            recipe_cell.style.horizontally_stretchable = true
            recipe_cell.add{
                tooltip = {"hxrrc.empty_the_recipe_button"},
                type = "choose-elem-button",
                elem_type = "recipe",
                name = "hxrrc_choose_recipe_button",
                recipe = recipe and recipe.name,
                tags = {product_full_name = item_or_fluid_full_name}, --used in Calculator.on_gui_elem_changed
                elem_filters = {
                    {
                        filter = type == "item" and "has-product-item" or "has-product-fluid",
                        elem_filters = {{filter = "name", name = short_name}},
                    },
                },
            }
        else
            report.add{type = "label", caption = {"hxrrc.undecomposable"}}
            report.add{type = "empty-widget"}
            report.add{type = "empty-widget"}
        end
    end

    --setting the total energy consumption and total pollution properly:
    report.consumption_flow.add{type = "label", caption = (total_energy_usage / 1000000) .. "MW"}
    report.pollution_flow.add{type = "label", caption = (total_pollution * 60) .. "/m"}
end

return Report