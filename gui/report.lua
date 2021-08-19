local Rational = require "utils/rational"
local Decomposer = require "logic/decomposer"

Report = {}

local function set_machine_amount_for_label(label, machine_amount)
    local rational_string = Rational.to_string(machine_amount)
    label.caption = " x " .. rational_string
    label.tooltip = "~" .. tostring(Rational.numerical_approximation(machine_amount)) .. "/s"
    label.tags = {amount = rational_string}
end

--Receives an ordered topologically sorted list of items, as well as a dictionary mapping each said item to a production rate, to build the final intermediate items' production rates report
function Report.new(parent, production_rates)
    local report = parent.add{type = "table", name = "report", column_count = 3, draw_horizontal_lines = true, draw_vertical_lines = true}

    --Headers:
    report.add{
        type = "label",
        caption = {"hxrrc.production_rates_table_header"}
    }
    report.add{
        type = "label",
        caption = {"hxrrc.machine_counts_table_header"},
    }
    report.add{
        type = "label",
        caption = {"hxrrc.recipes_used_table_header"},
    }

    for item_or_fluid_full_name, production_rate in pairs(production_rates) do
        --Item/fluid and its production rate cell:
        local item_cell = report.add{type = "flow"}
        item_cell.style.horizontally_stretchable = true

        local slash_position = string.find(item_or_fluid_full_name, "/", 1, true)
        local type = slash_position == 5 and "item" or "fluid"
        local short_name = string.sub(item_or_fluid_full_name, slash_position + 1)
        local prototype = type == "item" and game.item_prototypes[short_name] or game.fluid_prototypes[short_name]
        item_cell.add{type = "sprite", sprite = item_or_fluid_full_name, tooltip = prototype.localised_name}
        
        item_cell.add{type = "label", caption = Rational.to_string(production_rate) .. " /s ", tooltip = "~" .. tostring(Rational.numerical_approximation(production_rate)) .. "/s"}

        local recipes = global.recipes[item_or_fluid_full_name]
        local recipe = global[report.player_index].recipe_preferences[item_or_fluid_full_name]
        if recipes then
            --Crafting machine cell:
            if production_rate.numerator < 0 then
                report.add{type = "label", caption = {"hxrrc.byproduct"}} --byproduct that has to be pulled out of the system, no sense conveying how to make more of it trough crafting machines.
            elseif not recipe then --the item is not a byproduct, but the player has no recipe selected, so no crafting machines can be shown
                report.add{type = "label", caption = {"hxrrc.unselected_recipe"}}
            else --the player has a recipe selected and the item/fluid has a positive production rate, so a crafting machine cell will be placed
                local machine_cell = report.add{type = "flow"}
                machine_cell.style.horizontally_stretchable = true
                
                local category = recipe.category
                local crafting_machine = global[report.player_index].crafting_machine_preferences[category]

                --the machine:
                local machine_button = machine_cell.add{
                    type = "choose-elem-button",
                    name = "hxrrc_choose_crafting_machine_button",
                    elem_type = "entity",
                    entity = crafting_machine.name,
                    elem_filters = {{filter = "crafting-category", crafting_category = category}},
                    enabled = #global.crafting_machines_by_category[category] > 1,
                }

                --the machine amount:
                local machine_amount = Decomposer.machine_amount(item_or_fluid_full_name, production_rate, crafting_machine, report.player_index)
                local label = machine_cell.add{type = "label", name = "label"}
                set_machine_amount_for_label(label, machine_amount)
            end

            --Recipe cell:
            local recipe_cell = report.add{type = "flow"}
            recipe_cell.style.horizontally_stretchable = true
            local recipe_button = recipe_cell.add{
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
                    {
                        filter = "allow-decomposition",
                        mode = "and",
                    }
                },
                enabled = #recipes > 1,
            }
        else
            report.add{type = "label", caption = {"hxrrc.raw_resource"}}
            report.add{type = "label", caption = {"hxrrc.raw_resource"}}
        end
    end
end

local function recompute_machine_amount(current_machine, new_machine, current_amount)
    local speed_multiplier = Rational.from_string(tostring(current_machine.crafting_speed)) / Rational.from_string(tostring(new_machine.crafting_speed))
    return current_amount * speed_multiplier
end

function Report.update_crafting_machines(report)
    local entity_prototypes = game.entity_prototypes
    local cell_array = report.children
    for i = 5, #cell_array, 3 do
        local machine_cell = cell_array[i]
        if machine_cell.type == "flow" then
            local machine_button = machine_cell.hxrrc_choose_crafting_machine_button
            local category = machine_button.elem_filters[1].crafting_category
            local new_preferred_crafting_machine = global[report.player_index].crafting_machine_preferences[category]
            if machine_button.elem_value ~= new_preferred_crafting_machine.name then
                local old_preferred_crafting_machine = entity_prototypes[machine_button.elem_value]
                machine_button.elem_value = new_preferred_crafting_machine.name

                local current_machine_amount = Rational.from_string(machine_cell.label.tags.amount)
                local new_amount = recompute_machine_amount(old_preferred_crafting_machine, new_preferred_crafting_machine, current_machine_amount)
                set_machine_amount_for_label(machine_cell.label, new_amount)
            end
        end
    end
end

return Report