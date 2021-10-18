local Report = require "report"
local Decomposer = require "logic/decomposer"

local Sheet = {}

function Sheet.new(sheet_pane)
    local sheet = sheet_pane.add{type = "tab", caption = {"hxrrc.empty_sheet"}}
    local sheet_flow = sheet_pane.add{type = "flow", direction = "vertical"}
    sheet_pane.add_tab(sheet, sheet_flow)

    sheet_flow.style.horizontal_align = "center"

    --Input section:
    local input_flow = sheet_flow.add{type = "flow", name = "input_flow", direction = "horizontal"}
    input_flow.style.vertical_align = "center"

    input_flow.add{
        type = "textfield",
        name = "hxrrc_input_textfield",
        tooltip = {"hxrrc.production_rate_input_tooltip"},
        numeric = true,
        allow_decimal = true,
        allow_negative = false,
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
    }
    input_flow.add{
        type = "label",
        caption = "/m",
    }
    input_flow.add{
        type = "choose-elem-button",
        name = "item_input_button",
        tooltip = {"hxrrc.item_input_tooltip"},
        elem_type = "item",
    }
    input_flow.add{
        type = "button",
        name = "hxrrc_compute_button",
        caption = {"hxrrc.compute_button_caption"},
    }

    --Output section:
    local output_flow = sheet_flow.add{type = "flow", name = "output_flow"}
    output_flow.style.horizontally_stretchable = true
    output_flow.style.vertically_stretchable = true
end

local function update_totals_table_after_change(sheet_flow, new_production_rates) --subtracts from the global[player_index].total_production_rates table the rates that were just cleared from the sheet's previous computation (if there are any) and (if new_production_rates is not nil) adds the new ones that were just computed to that table instead.
    local old_production_rates = sheet_flow.tags
    local total_production_rates = global[sheet_flow.player_index].total_production_rates
    for prototype_name, old_rate in pairs(old_production_rates) do
        total_production_rates[prototype_name] = total_production_rates[prototype_name] - old_rate
        if math.abs(total_production_rates[prototype_name]) < 0.0000001 then total_production_rates[prototype_name] = nil end --delete the item/fluid entirely if it's associated production rate becomes 0
    end

    if new_production_rates then -- if there is even new data to speak of
        for prototype_name, new_rate in pairs(new_production_rates) do
            if total_production_rates[prototype_name] then
                total_production_rates[prototype_name] = total_production_rates[prototype_name] + new_rate --add the new rate to the running count
            else
                total_production_rates[prototype_name] = new_rate
            end
        end
    end
end

function Sheet.delete_selected_sheet(sheet_pane)
    if #sheet_pane.tabs > 1 then
        local tab_and_sheet = sheet_pane.tabs[sheet_pane.selected_tab_index]
        sheet_pane.remove_tab(tab_and_sheet.tab)
        tab_and_sheet.tab.destroy()

        local sheet_flow = tab_and_sheet.content
        update_totals_table_after_change(sheet_flow)
        sheet_flow.destroy()

        sheet_pane.selected_tab_index = 1
    else
        game.get_player(sheet_pane.player_index).create_local_flying_text{text = {"hxrrc.cannot_remove_all_sheets_error"}, create_at_cursor = true}
    end
end

local function update_sheet_title(sheet_pane, sheet_index)
    local sheet_and_flow = sheet_pane.tabs[sheet_index]
    local item_name = sheet_and_flow.content.input_flow.item_input_button.elem_value
    sheet_and_flow.tab.caption = item_name and game.item_prototypes[item_name].localised_name or {"hxrrc.empty_sheet"}
end

--Performs the calculator computation for the sheet that either owns the passed input_flow_element or belongs to the given sheet_pane and has the given sheet_index (if input_flow_element is not nil, the two other arguments are ignored; if it is nil, the other two arguments are used and thus must be specified)
function Sheet.calculate(input_flow_element, sheet_pane, sheet_index)
    local input_flow, sheet_flow
    if input_flow_element then
        input_flow = input_flow_element.parent
        sheet_flow = input_flow.parent
        sheet_pane = sheet_flow.parent
        sheet_index = sheet_pane.selected_tab_index
    else
        local sheet_and_flow = sheet_pane.tabs[sheet_index]
        sheet_flow = sheet_and_flow.content
        input_flow = sheet_flow.input_flow
    end

    local production_rate = tonumber(input_flow.hxrrc_input_textfield.text)
    if not production_rate then
        game.get_player(sheet_flow.player_index).create_local_flying_text{text = {"hxrrc.invalid_production_rate_error"}, create_at_cursor = true}
        return
    end
    production_rate = production_rate  / 60
    
    update_sheet_title(sheet_pane, sheet_index)
    local output_flow = input_flow.parent.output_flow
    output_flow.clear()

    local item_name = input_flow.item_input_button.elem_value
    if item_name then
        local production_rates = {}
        local full_prototype_name = "item/" .. item_name
        
        Decomposer.decompose(production_rate, full_prototype_name, production_rates, sheet_flow.player_index, {})

        update_totals_table_after_change(sheet_flow, production_rates)
        sheet_flow.tags = production_rates --save the results as the "tags" table of the sheet_flow, so that they can be used by the next call to the function just above

        Report.new(output_flow, production_rates)
    else --No item selected, so the sheet should be cleared
        update_totals_table_after_change(sheet_flow)
        sheet_flow.tags = {}
    end
end

return Sheet