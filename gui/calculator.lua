local Decomposer = require "logic/decomposer"
local Rational = require "utils/rational"
local Report = require "report"
local Set = require "utils/set"
local TopoSort = require "logic/topo_sort"

local Calculator = {}

local function build_preferances_section(parent)
    local preferences_table = parent.add{type = "table", column_count = 2}

    local crafting_machine_buttons = {} --a dictionary mapping crafting categories to the choose elem buttons that specify which machine should be used for that crafting category
    local crafting_machines_for_category = global.crafting_machines_for_category
    for category, crafting_machines_list in pairs(crafting_machines_for_category) do
        if #crafting_machines_list > 1 then --no sense displaying a button for categories with only one choice
            local button = preferences_table.add{
                type = "choose-elem-button",
                elem_type = "entity",
                entity = global.saved_crafting_machine_names and global.saved_crafting_machine_names[category] and game.entity_prototypes[global.saved_crafting_machine_names[category]] and global.saved_crafting_machine_names[category] or crafting_machines_for_category[category][1].name, --if we had a saved crafting machine preference for this category in the previous configuration and this crafting machine still exists, then continue to use this preferance; otherwise, just pick a default one (the first one found in the current configuration of the game)
                elem_filters = {{filter = "crafting-category", crafting_category = category}}
            }
            crafting_machine_buttons[category] = button
            preferences_table.add{type = "label", caption = category}
        end
    end
    global[preferences_table.player_index].crafting_machine_buttons = crafting_machine_buttons
    global[preferences_table.player_index].preferences_table = preferences_table
    preferences_table.visible = false
end

function Calculator.build(player)
    --Main frame:
    local main_frame = player.gui.screen.add{
        type = "frame",
        name = "hxrrc_calculator",
        direction = "vertical",
        caption = {"hxrrc.main_window_title"},
        visible = false,
    }
    main_frame.auto_center = true
    main_frame.style.maximal_height = 950

    --Controls section:
    local controls_flow = main_frame.add{type = "flow"}
    local preferences_toggle_button = controls_flow.add {
        type = "button",
        name = "hxrrc_preferences_toggle_button",
        caption = {"hxrrc.preferences"},
        tooltip = {"hxrrc.toggle_preferences"},
    }

    local main_flow = main_frame.add{type = "flow"}

    --Preferences section:
    build_preferances_section(main_flow)

    --Tabbed pane:
    local tabbed_pane = main_flow.add{type = "tabbed-pane"}
    local compute_tab = tabbed_pane.add{type = "tab", caption = "Calculator"}
    local compute_flow = tabbed_pane.add{type = "flow", direction = "vertical"}
    tabbed_pane.add_tab(compute_tab, compute_flow)

    --Input section:
    local input_flow = compute_flow.add{type = "flow", direction = "horizontal"}
    input_flow.style.vertical_align = "center"

    local input_textfield = input_flow.add{
        type = "textfield",
        tooltip = {"hxrrc.production_rate_input_tooltip"},
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
    }
    input_flow.add{
        type = "label",
        caption = "/s",
    }
    local choose_item_button = input_flow.add {
        type = "choose-elem-button",
        tooltip = {"hxrrc.item_input_tooltip"},
        elem_type = "item",
    }
    local confirmation_button = input_flow.add {
        type = "button",
        name = "hxrrc_confirmation_button",
        caption = {"hxrrc.confirmation_button"},
    }

    --Output section:
    local scroll_pane = compute_flow.add{type = "scroll-pane"}
    local output_flow = scroll_pane.add{type = "flow", direction = "horizontal"}
    output_flow.style.horizontally_stretchable = true
    output_flow.style.vertically_stretchable = true

    --Store the widgets to which we will use references later:
    global[player.index].textfield = input_textfield
    global[player.index].item_button = choose_item_button
    global[player.index].output_flow = output_flow
end

function Calculator.destroy(player)
    local saved_crafting_machine_names = {} --a dictionary mapping previously existing crafting categories to their previously existing preffered crafting machine name
    for category, button in pairs(global[player.index].crafting_machine_buttons) do
        saved_crafting_machine_names[category] = button.elem_value
    end
    global.saved_crafting_machine_names = saved_crafting_machine_names
    player.gui.screen.hxrrc_calculator.destroy()
end

function Calculator.toggle_calculator(player)
    local calculator = player.gui.screen.hxrrc_calculator
    calculator.visible = not calculator.visible
    player.opened = calculator.visible and calculator or nil
end

function Calculator.toggle_preferences(player)
    global[player.index].preferences_table.visible = not global[player.index].preferences_table.visible
end

function Calculator.calculate(player)
    local production_rate = Rational.from_string(global[player.index].textfield.text)
    local item_name = global[player.index].item_button.elem_value
    
    --Handle incorrect input:
    error_message = {""}
    if production_rate == nil then
        error_message[#error_message + 1] = {"hxrrc.invalid_production_rate_error"}
    end
    if item_name == nil then
        error_message[#error_message + 1] = {"hxrrc.item_not_chosen_error"}
    end

    if #error_message > 1 then
        --Invalid request
        player.create_local_flying_text{text = error_message, create_at_cursor = true}
    else
        --Fulfill request
        local output_flow = global[player.index].output_flow
        output_flow.clear()

        local total_production_rates = {}
        local inbound_dependencies = {}
        local outbound_dependencies = {}
        local full_prototype_name = "item/" .. item_name
        inbound_dependencies[full_prototype_name] = Set.new()
        outbound_dependencies[full_prototype_name] = Set.new()
        
        Decomposer.decompose(production_rate, full_prototype_name, total_production_rates, inbound_dependencies, outbound_dependencies)

        local list = TopoSort.topo_sort(inbound_dependencies, outbound_dependencies)
        Report.new(output_flow, list, total_production_rates)
    end

    player.gui.screen.hxrrc_calculator.force_auto_center()
end

return Calculator