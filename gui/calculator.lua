local Report = require "gui.report"
local Sheet = require "gui.sheet"
local ModuleGUI = require "gui.modulegui"
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
    --Sheet addition and removal buttons:
    local sheet_buttons_flow = sheet_section.add{type = "flow", direction = "horizontal"}
    sheet_buttons_flow.style.horizontal_align = "right"
    sheet_buttons_flow.style.horizontally_stretchable = true
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
end

event_handlers.on_gui_click["hxrrc_new_sheet_button"] = function(event)
    Sheet.new(event.element.parent.parent.sheet_pane)
    global[event.player_index].calculator.force_auto_center()
end

event_handlers.on_gui_click["hxrrc_delete_sheet_button"] = function(event)
    Sheet.delete_selected_sheet(event.element.parent.parent.sheet_pane)
    global[event.player_index].calculator.force_auto_center()
end

function Calculator.toggle(player)
    local calculator = player.gui.screen.hxrrc_calculator
    calculator.visible = not calculator.visible
    player.opened = calculator.visible and calculator or nil
end

function Calculator.recompute_everything(player_index)
    local sheet_pane = global[player_index].sheet_section.sheet_pane

    for sheet_index, _ in ipairs(sheet_pane.tabs) do
        global.computation_stack[#global.computation_stack+1] = {player_index = player_index, call = Sheet.calculate, parameters = {false, sheet_pane, sheet_index}}
        global[player_index].backlogged_computation_count = global[player_index].backlogged_computation_count + 1
    end

    global.computation_stack[#global.computation_stack+1] = {player_index = player_index, call = global[player_index].calculator.force_auto_center, parameters = {}}
    global[player_index].backlogged_computation_count = global[player_index].backlogged_computation_count + 1
end

event_handlers.on_gui_elem_changed["hxrrc_choose_module_button"] = function(event)
    ModuleGUI.on_gui_elem_changed(event)
    Calculator.recompute_everything(event.player_index)
end

event_handlers.on_gui_confirmed["hxrrc_module_count_textfield"] = function(event)
    ModuleGUI.on_gui_confirmed(event)
    Calculator.recompute_everything(event.player_index)
end

event_handlers.on_gui_elem_changed["hxrrc_choose_recipe_button"] = function(event)
    if Report.handle_recipe_binding_change(event) then
        Calculator.recompute_everything(event.player_index)
    end
end

event_handlers.on_gui_elem_changed["hxrrc_choose_crafting_machine_button"] = function(event)
    if Report.handle_crafting_machine_change(event) then
        Calculator.recompute_everything(event.player_index)
    end
end

return Calculator