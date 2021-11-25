local Sheet = require "gui/sheet"
local Totals = require "gui/totals"
local ModuleGUI = require "gui/modulegui"
local Calculator = {}

function Calculator.build(player)
    --Main frame:
    local calculator = player.gui.screen.add{
        type = "frame",
        name = "hxrrc_calculator",
        caption = {"hxrrc.calculator_title"},
        visible = false,
    }
    global[player.index].calculator = calculator
    calculator.auto_center = true
    local main_scroll_area = calculator.add{type = "scroll-pane", direction = "horizontal", name = "main_scroll_area"}
    local main_scroll_area_flow = main_scroll_area.add{type = "flow", direction = "horizontal", name = "main_scroll_area_flow"}

    --Sheet section:
    local sheet_section = main_scroll_area_flow.add{type = "flow", direction = "vertical", name = "sheet_section"}
    global[player.index].sheet_section = sheet_section
    sheet_section.style.horizontally_stretchable = true
    --Sheet addition, removal and totals section switching buttons:
    local sheet_buttons_flow = sheet_section.add{type = "flow", direction = "horizontal"}
    sheet_buttons_flow.style.horizontal_align = "right"
    sheet_buttons_flow.style.horizontally_stretchable = true
    sheet_buttons_flow.add{
        type = "button",
        name = "hxrrc_switch_sections_button",
        caption = {"hxrrc.totals"},
        tooltip = {"hxrrc.switch_to_totals_section"},
    }
    sheet_buttons_flow.add{
        type = "button",
        name = "hxrrc_new_sheet_button",
        caption = {"hxrrc.new_sheet"},
        tooltip = {"hxrrc.add_new_sheet"},
    }
    sheet_buttons_flow.add{
        type = "button",
        name = "hxrrc_delete_sheet_button",
        caption = {"hxrrc.delete_sheet"},
        tooltip = {"hxrrc.delete_selected_sheet"},
    }
    --Sheet pane and first sheet:
    local sheet_pane = sheet_section.add{type = "tabbed-pane", name = "sheet_pane"}
    Sheet.new(sheet_pane)
    sheet_pane.selected_tab_index = 1

    --Totals section:
    local totals_section = Totals.new(main_scroll_area_flow)
    global[player.index].totals_section = totals_section
    totals_section.visible = false
    
    local totals_main_flow = totals_section.add{type = "flow", direction = "vertical"}
    totals_main_flow.add{
        type = "button",
        name = "hxrrc_switch_sections_button",
        caption = {"hxrrc.sheets"},
        tooltip = {"hxrrc.switch_to_sheets_section"},
    }
    global[player.index].totals_table_flow = totals_main_flow.add{type = "flow"}
    global[player.index].total_production_rates = {}
end

function Calculator.destroy(player)
    player.gui.screen.hxrrc_calculator.destroy()
end

function Calculator.toggle(player)
    local calculator = player.gui.screen.hxrrc_calculator
    calculator.visible = not calculator.visible
    player.opened = calculator.visible and calculator or nil
end

function Calculator.switch_sections(player_index)
    global[player_index].totals_section.visible = not global[player_index].totals_section.visible
    global[player_index].sheet_section.visible = not global[player_index].sheet_section.visible
end

function Calculator.on_gui_click(event)
    if event.element.name == "hxrrc_compute_button" then
        Sheet.calculate(event.element)
        global[event.player_index].calculator.force_auto_center()
    elseif event.element.name == "hxrrc_switch_sections_button" then
        Calculator.switch_sections(event.player_index)
        if global[event.player_index].totals_section.visible then
            Totals.update(global[event.player_index].totals_table_flow)
        end
    elseif event.element.name == "hxrrc_new_sheet_button" then
        Sheet.new(event.element.parent.parent.sheet_pane)
        global[event.player_index].calculator.force_auto_center()
    elseif event.element.name == "hxrrc_delete_sheet_button" then
        Sheet.delete_selected_sheet(event.element.parent.parent.sheet_pane)
        global[event.player_index].calculator.force_auto_center()
    end
end

function Calculator.recompute_everything(player_index)
    local sheet_pane = global[player_index].sheet_section.sheet_pane
    
    if global[player_index].totals_section.visible then
        global.computation_stack[#global.computation_stack+1] = {player_index = player_index, call = Totals.update, parameters = {global[player_index].totals_table_flow}}
        global[player_index].backlogged_computation_count = global[player_index].backlogged_computation_count + 1
    end
    
    for sheet_index, _ in ipairs(sheet_pane.tabs) do
        global.computation_stack[#global.computation_stack+1] = {player_index = player_index, call = Sheet.calculate, parameters = {false, sheet_pane, sheet_index}}
        global[player_index].backlogged_computation_count = global[player_index].backlogged_computation_count + 1
    end
    
    global.computation_stack[#global.computation_stack+1] = {player_index = player_index, call = global[player_index].calculator.force_auto_center, parameters = {}}
    global[player_index].backlogged_computation_count = global[player_index].backlogged_computation_count + 1
end

--Will associate all categories that the new crafting machine belongs to to the new crafting machine and update all the gui data accordingly
local function update_crafting_machines(player_index, name_of_new_crafting_machine)
    local crafting_machine_prototype = game.entity_prototypes[name_of_new_crafting_machine]
    for category, _ in pairs(crafting_machine_prototype.crafting_categories) do
        global[player_index].crafting_machine_preferences[category] = crafting_machine_prototype
    end
    Calculator.recompute_everything(player_index)
end

function Calculator.on_gui_elem_changed(event)
    if event.element.name == "hxrrc_choose_recipe_button" then
        --Update the recipe preference:
        global[event.player_index].recipe_preferences[event.element.tags.product_full_name] = game.recipe_prototypes[event.element.elem_value]
        Calculator.recompute_everything(event.player_index)
    elseif event.element.name == "hxrrc_choose_crafting_machine_button" then
        local new_value = event.element.elem_value
        local category = event.element.elem_filters[1].crafting_category
        event.element.elem_value = global[event.player_index].crafting_machine_preferences[category].name --reset the button to its previous value for now, in order not to mess with updating later and to also prevent it from being emptied

        if not new_value then
            game.get_player(event.player_index).create_local_flying_text{text = {"hxrrc.cannot_empty_a_choose_crafting_machine_button_error"}, create_at_cursor = true}
        elseif new_value ~= event.element.elem_value then --if the value has truly changed
            update_crafting_machines(event.player_index, new_value)
        end
    elseif event.element.name == "hxrrc_choose_module_button" then
        ModuleGUI.on_gui_elem_changed(event)
        Calculator.recompute_everything(event.player_index)
    end
end

function Calculator.on_gui_confirmed(event)
    if event.element.name == "hxrrc_module_count_textfield" then
        ModuleGUI.on_gui_confirmed(event)
        Calculator.recompute_everything(event.player_index)
    end
end

function Calculator.on_tick()
    if #global.computation_stack > 0 then
        local call_and_parameters = table.remove(global.computation_stack)
        call_and_parameters.call(table.unpack(call_and_parameters.parameters))
        local player_index = call_and_parameters.player_index
        game.get_player(player_index).gui.screen.hxrrc_calculator.enabled = global[player_index].backlogged_computation_count == 0
    end
end

return Calculator