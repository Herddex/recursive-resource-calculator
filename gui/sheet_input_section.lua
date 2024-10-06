local SheetInputSection = {}

local function addRow(parent)
    local row = parent.add{
        type = "flow",
        direction = "horizontal"
    }
    row.add{
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
        type = "drop-down",
        name = "hxrrc_time_unit_dropdown",
        selected_index = 1,
        items = {"/m", "/s"}
    }
    input_flow.add{
        type = "choose-elem-button",
        name = "item_input_button",
        tooltip = {"hxrrc.item_input_tooltip"},
        elem_type = "item",
        item = item_input_button_value,
    }
end

function SheetInputSection.new(parent)
    parent.add{
        type="flow"
    }
    
end

return SheetInputSection