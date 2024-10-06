local ModuleGUI = require "gui/modulegui"
local Decomposer = require "logic/decomposer"

local Report = {}

local function format_by_precision(float, player_index)
    local precision = settings.get_player_settings(player_index)["hxrrc-displayed-floating-point-precision"].value

    return string.format("%." .. precision .. "f", float)
end

local function add_header(report, caption, tooltip)
    local header = report.add{type = "flow"}
    header.style.horizontally_stretchable = true
    header.style.horizontal_align = "center"
    local label = header.add{type = "label", caption = caption, tooltip = tooltip}
    label.style.right_padding = 4
end

local function setup_headers(report, energy_consumption, pollution)
    add_header(report, {"", {"hxrrc.consumption"}, ":"}, {"hxrrc.consumption_header_tooltip"})
    report.add{type = "label", caption = format_by_precision(energy_consumption / 1000000, report.player_index) .. " MW"}

    add_header(report, {"", {"hxrrc.pollution"}, ":"}, {"hxrrc.pollution_header_tooltip"})
    report.add{type = "flow", name = "pollution_flow"}

    report.pollution_flow.add{type = "label", caption = format_by_precision(pollution * 60, report.player_index) .. " /m"}

    for _, caption in ipairs({
        {"hxrrc.production_rates_table_header"},
        {"hxrrc.machine_counts_table_header"},
        {"hxrrc.modules"},
        {"hxrrc.recipes_used_table_header"}}) do
            add_header(report, caption)
    end
end

local function split_product_name(product_full_name)
    local slash_position = string.find(product_full_name, "/", 1, true)
    return product_full_name:sub(1, slash_position - 1), product_full_name:sub(slash_position + 1)
end

local function add_item_cell(report, product_full_name, production_rate)
    local item_cell = report.add{type = "flow"}
    item_cell.style.horizontally_stretchable = true

    local type, short_name = split_product_name(product_full_name)

    local prototype = type == "item" and game.item_prototypes[short_name] or game.fluid_prototypes[short_name]
    item_cell.add{type = "sprite", sprite = product_full_name, tooltip = prototype.localised_name}
    
    item_cell.add{type = "label", caption = format_by_precision(production_rate, report.player_index) .. " /s"}
end

local function add_undecomposed_product_widgets(report, explanation_caption)
    report.add{type = "label", caption = explanation_caption}
    report.add{type = "empty-widget"}
    report.add{type = "empty-widget"}
end

local function add_byproduct_widgets(report)
    add_undecomposed_product_widgets(report, {"hxrrc.byproduct"})
end

local function add_undecomposable_product_widgets(report)
    add_undecomposed_product_widgets(report, {"hxrrc.undecomposable"})
end

local function add_recipe_cell(report, product_full_name, recipe)
    local recipe_cell = report.add{type = "flow"}
    recipe_cell.style.horizontally_stretchable = true
    local type, product_short_name = split_product_name(product_full_name)
    recipe_cell.add{
        tooltip = {"hxrrc.empty_the_recipe_button"},
        type = "choose-elem-button",
        elem_type = "recipe",
        name = "hxrrc_choose_recipe_button",
        recipe = recipe and recipe.name,
        tags = {product_full_name = product_full_name}, --used in Calculator.on_gui_elem_changed
        elem_filters = {
            {
                filter = type == "item" and "has-product-item" or "has-product-fluid",
                elem_filters = {{filter = "name", name = product_short_name}},
            },
        },
    }
end

local function add_row(report, product_full_name, production_rate)
    add_item_cell(report, product_full_name, production_rate)

    local energy_consumption, pollution = 0, 0
    local player_index = report.player_index
    local recipes = global.recipe_lists_by_product_full_name[product_full_name]
    local recipe = global[player_index].recipe_preferences[product_full_name]
    if recipes then
        --Crafting machine and module cells:
        if production_rate < 0 then
            add_byproduct_widgets(report)
        else
            if not recipe then --the item is not a byproduct, but the player has no recipe selected
                report.add{type = "label", caption = {"hxrrc.unselected_recipe"}}
                report.add{type = "empty-widget"}
            else --the player has a recipe selected and the item/fluid has a positive production rate
                local category = recipe.category
                local crafting_machine = global[player_index].crafting_machine_preferences[category]
                if not crafting_machine then --the recipe only supports manual crafting:
                    report.add{type = "label", caption = {"hxrrc.not_automatically_craftable"}}
                    report.add{type = "empty-widget"}
                else --a machine and module cell will be added:
                    local machine_cell = report.add{type = "flow"}
                    machine_cell.style.horizontally_stretchable = true
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
                    local machine_amount = Decomposer.machine_amount(product_full_name, production_rate, crafting_machine, player_index)
                    local label = machine_cell.add{type = "label", name = "label"}
                    label.caption = " x " .. format_by_precision( machine_amount, player_index)

                    --Module cell:
                    ModuleGUI.new(report, recipe.name, crafting_machine.allowed_effects)
                end
            end
            add_recipe_cell(report, product_full_name, recipe)
        end
    else
        add_undecomposable_product_widgets(report)
    end

end

function Report.new(parent, production_rates, energy_consumption, pollution)
    local report = parent.add{type = "table", name = "report", column_count = 4, draw_horizontal_lines = true, draw_vertical_lines = true}

    setup_headers(report, energy_consumption, pollution)

    for product_full_name, production_rate in pairs(production_rates) do
        add_row(report, product_full_name, production_rate)
    end
end

return Report