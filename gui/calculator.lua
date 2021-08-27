local Sheet = require "sheet"
local Totals = require "totals"
local ModuleGUI = require "modulegui"
local Initializer = require "logic/initializer"
local Calculator = {}

function Calculator.build(player)
    Initializer.initialize_player_data(player.index)

    --Main frame:
    local calculator = player.gui.screen.add{
        type = "frame",
        name = "hxrrc_calculator",
        caption = {"hxrrc.calculator_title"},
        visible = false,
    }
    global[player.index].calculator = calculator
    calculator.auto_center = true
    calculator.style.maximal_height = 800
    calculator.style.maximal_width = 1700
    local main_scroll_area = calculator.add{type = "scroll-pane", direction = "horizontal", name = "main_scroll_area"}
    local main_scroll_area_flow = main_scroll_area.add{type = "flow", direction = "horizontal", name = "main_scroll_area_flow"}

    --Sheet section:
    local sheet_section = main_scroll_area_flow.add{type = "flow", direction = "vertical", name = "sheet_section"}
    global[player.index].sheet_section = sheet_section
    sheet_section.style.horizontally_stretchable = true
    --Sheet addition, removal and totals section switching buttons: 
    local sheet_buttons_flow = sheet_section.add{type = "flow"}
    sheet_buttons_flow.style.horizontal_align = "right"
    sheet_buttons_flow.style.horizontally_stretchable = true
    sheet_buttons_flow.add{
        type = "button",
        name = "hxrrc_switch_sections_button",
        caption = {"hxrrc.totals"},
        tooltip = {"hxrrc.switch_to_totals_section"},
    }
    local new_sheet_button = sheet_buttons_flow.add{
        type = "button",
        name = "hxrrc_new_sheet_button",
        caption = {"hxrrc.new_sheet"},
        tooltip = {"hxrrc.add_new_sheet"},
    }
    local delete_sheet_button = sheet_buttons_flow.add{
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
    global[player.index] = nil
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
    elseif event.element.name == "hxrrc_new_sheet_button" then
        Sheet.new(event.element.parent.parent.sheet_pane)
        global[event.player_index].calculator.force_auto_center()
    elseif event.element.name == "hxrrc_delete_sheet_button" then
        Sheet.delete_selected_sheet(event.element.parent.parent.sheet_pane)
        global[event.player_index].calculator.force_auto_center()
    end
end

--Will associate all categories that the new crafting machine belongs to to the new crafting machine and update all the gui data accordingly
local function update_crafting_machines(player_index, name_of_new_crafting_machine)
    local crafting_machine_prototype = game.entity_prototypes[name_of_new_crafting_machine]
    for category, _ in pairs(crafting_machine_prototype.crafting_categories) do
        global[player_index].crafting_machine_preferences[category] = crafting_machine_prototype
    end

    for _, sheet_and_flow in ipairs(game.get_player(player_index).gui.screen.hxrrc_calculator.main_scroll_area.main_scroll_area_flow.sheet_section.sheet_pane.tabs) do
        Sheet.update_crafting_machines(sheet_and_flow.content)
    end
    Totals.update_crafting_machines(global[player_index].totals_table_flow)
end

local function recompute_everything(player_index)
    local profiler = game.create_profiler()
    local sheet_pane = global[player_index].sheet_section.sheet_pane
    for sheet_index, _ in ipairs(sheet_pane.tabs) do
        Sheet.calculate(nil, sheet_pane, sheet_index)
    end
    profiler.stop()
    game.print({"", "Recomputation took ", profiler})
end

function Calculator.on_gui_elem_changed(event)
    if event.element.name == "hxrrc_choose_recipe_button" then
        --Update the recipe preference:
        global[event.player_index].recipe_preferences[event.element.tags.product_full_name] = game.recipe_prototypes[event.element.elem_value]
        recompute_everything(event.player_index)
    elseif event.element.name == "hxrrc_choose_crafting_machine_button" then
        local new_value = event.element.elem_value
        local category = event.element.elem_filters[1].crafting_category
        event.element.elem_value = global[event.player_index].crafting_machine_preferences[category].name --reset the button to its previous value for now, in order not to mess with updating later and to also prevent it from being emptied

        if not new_value then
            game.get_player(event.player_index).create_local_flying_text{text = {"hxrrc.cannot_empty_a_choose_crafting_machine_button_error"}, create_at_cursor = true}
        elseif new_value ~= event.element.elem_value then --if the value has truly changed
            update_crafting_machines(event.player_index, new_value)
        end
    elseif event.element.tags.is_hxrrc_choose_module_button then
        ModuleGUI.on_gui_elem_changed(event)
        recompute_everything(event.player_index)
    end
end

function Calculator.on_gui_confirmed(event)
    if event.element.tags.is_hxrrc_module_count_textfield then
        ModuleGUI.on_gui_confirmed(event)
        recompute_everything(event.player_index)
    end
end

return Calculator