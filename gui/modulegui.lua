local Utils = require "logic.utils"

local ModuleGUI = {}

local function add_module_slot(module_gui, recipe_name, module_name, module_count)
    local module_slot = module_gui.add{type = "flow", direction = "vertical"}
    module_slot.style.horizontal_align = "center"
    module_slot.add{
        type = "choose-elem-button",
        name = "hxrrc_choose_module_button",
        tooltip = {"hxrrc.choose_module_button_tooltip"},
        elem_type = "item",
        item = module_name,
        elem_filters = {{filter = "name", name = storage.names_of_allowed_modules_by_recipe_name[recipe_name]}},
    }
    local textfield = module_slot.add{
        type = "textfield",
        name = "hxrrc_module_count_textfield",
        tooltip = {"hxrrc.module_count_textfield_tooltip"},
        text = module_count,
        enabled = not not module_count,
        numeric = true,
        allow_decimal = true,
        lose_focus_on_confirm = true,
    }
    textfield.style.width = 32
end

local function add_module_data(main_module_flow)
    local label_flow = main_module_flow.add{type = "flow", direction = "vertical"}
    local module_preferences = storage[main_module_flow.player_index].module_preferences_by_recipe_name[main_module_flow.tags.recipe_name]
    for _, effect in ipairs(Utils.module_effect_names) do
        local effect_value = module_preferences.effects[effect]
        if math.abs(effect_value) >= 0.01 then
            label_flow.add{type = "label", caption = {"", {"hxrrc." .. effect}, ": ", string.format("%+.0f", (effect_value > -0.8 and effect_value or -0.8) * 100) .. "%"}}
        end
    end
end

function ModuleGUI.new(parent, recipe_name, allowed_effects)
    if allowed_effects then
        local an_allowed_effect = false
        for _, value in pairs(allowed_effects) do
            if(value) then an_allowed_effect = true end
        end
        if an_allowed_effect then
            local main_module_flow = parent.add{type = "flow", direction = "horizontal"}
            main_module_flow.tags = {recipe_name = recipe_name}

            local module_gui = main_module_flow.add{type = "flow", direction = "horizontal"}
            module_gui.tags = {recipe_name = recipe_name}
            module_gui.style.right_padding = 4

            local modules = storage[module_gui.player_index].module_preferences_by_recipe_name[recipe_name]
            for index, module_name in ipairs(modules) do
                add_module_slot(module_gui, recipe_name, module_name, modules[-index])
            end
            add_module_slot(module_gui, recipe_name)

            add_module_data(main_module_flow)
        else
            parent.add{type = "empty-widget"}
        end
    else
        parent.add{type = "empty-widget"}
    end
end

function ModuleGUI.on_gui_elem_changed(event)
    local choose_module_button = event.element
    local module_slot = choose_module_button.parent
    local module_gui = module_slot.parent
    local index = module_slot.get_index_in_parent()
    local recipe_name = module_gui.tags.recipe_name
    local module_preferences = storage[choose_module_button.player_index].module_preferences_by_recipe_name[recipe_name]

    if not choose_module_button.elem_value and index < #module_gui.children then
        local module_prototype = prototypes.item[module_preferences[index]]
        for _, effect in ipairs(Utils.module_effect_names) do
            if module_prototype.module_effects[effect] then
                module_preferences.effects[effect] = module_preferences.effects[effect] - module_preferences[-index] * module_prototype.module_effects[effect]
            end
        end
        --a button that was not the last one was emptied, so the module data must be shifted to fill the gap, and the button must be deleted along with its textfield buddy
        for i = index + 1, #module_preferences do
            module_preferences[i - 1] = module_preferences[i]
            module_preferences[-i + 1] = module_preferences[-i]
        end
        module_preferences[#module_preferences], module_preferences[-#module_preferences] = nil, nil

        module_slot.destroy()

    elseif choose_module_button.elem_value then
        if index == #module_gui.children then
            --the last module slot was set, so its textfiled must be enabled, the module's count set to 1 by default, and a new one must be added
            module_slot.hxrrc_module_count_textfield.enabled = true
            module_preferences[-index] = 1
            add_module_slot(module_gui, recipe_name)
        else
            --a previous module was replaced
            local module_prototype = prototypes.item[module_preferences[index]]
            for _, effect in ipairs(Utils.module_effect_names) do
                if module_prototype.module_effects[effect] then
                    module_preferences.effects[effect] = module_preferences.effects[effect] - module_preferences[-index] * module_prototype.module_effects[effect]
                end
            end
        end
        module_preferences[index] = choose_module_button.elem_value
        local module_prototype = prototypes.item[module_preferences[index]]
        for _, effect in ipairs(Utils.module_effect_names) do
            if module_prototype.module_effects[effect] then
                module_preferences.effects[effect] = module_preferences.effects[effect] + module_preferences[-index] * module_prototype.module_effects[effect]
            end
        end
    end
end

function ModuleGUI.on_gui_confirmed(event)
    local textfield = event.element
    local module_slot = textfield.parent
    local index = module_slot.get_index_in_parent()
    local recipe_name = module_slot.parent.tags.recipe_name
    local module_preferences = storage[textfield.player_index].module_preferences_by_recipe_name[recipe_name]
    local module_prototype = prototypes.item[module_preferences[index]]

    local new_value = tonumber(textfield.text) or 0
    local delta = new_value - module_preferences[-index]
    for _, effect in ipairs(Utils.module_effect_names) do
        if module_prototype.module_effects[effect] then
            module_preferences.effects[effect] = module_preferences.effects[effect] + delta * module_prototype.module_effects[effect]
        end
    end

    module_preferences[-index] = new_value
end

return ModuleGUI