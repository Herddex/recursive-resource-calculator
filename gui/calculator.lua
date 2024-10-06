local Sheet = require "gui/sheet"
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

--Will associate all categories that the new crafting machine belongs to to the new crafting machine and update all the gui data accordingly
local function update_crafting_machines(player_index, name_of_new_crafting_machine)
    local crafting_machine_prototype = game.entity_prototypes[name_of_new_crafting_machine]
    for category, _ in pairs(crafting_machine_prototype.crafting_categories) do
        global[player_index].crafting_machine_preferences[category] = crafting_machine_prototype
    end
    Calculator.recompute_everything(player_index)
end

event_handlers.on_gui_elem_changed["hxrrc_choose_recipe_button"] = function(event)
    --Update the recipe preference:
    global[event.player_index].recipe_preferences[event.element.tags.product_full_name] = game.recipe_prototypes[event.element.elem_value]
    Calculator.recompute_everything(event.player_index)
end

event_handlers.on_gui_elem_changed["hxrrc_choose_crafting_machine_button"] = function(event)
    local new_value = event.element.elem_value
    local category = event.element.elem_filters[1].crafting_category
    event.element.elem_value = global[event.player_index].crafting_machine_preferences[category].name --reset the button to its previous value for now, in order not to mess with updating later and to also prevent it from being emptied

    if not new_value then
        game.get_player(event.player_index).create_local_flying_text{text = {"hxrrc.cannot_empty_a_choose_crafting_machine_button_error"}, create_at_cursor = true}
    elseif new_value ~= event.element.elem_value then --if the value has truly changed
        update_crafting_machines(event.player_index, new_value)
    end
end

event_handlers.on_gui_elem_changed["hxrrc_choose_module_button"] = function(event)
    ModuleGUI.on_gui_elem_changed(event)
    Calculator.recompute_everything(event.player_index)
end

event_handlers.on_gui_confirmed["hxrrc_module_count_textfield"] = function(event)
    ModuleGUI.on_gui_confirmed(event)
    Calculator.recompute_everything(event.player_index)
end

return Calculator