local ModuleGUI = {}

local function add_module_names(names_of_allowed_modules, source)
    for _, module in ipairs(source) do
        names_of_allowed_modules[#names_of_allowed_modules+1] = module.name
    end
end

local function add_module_slot(module_gui, module_name, module_count)
    local names_of_allowed_modules = {}
    add_module_names(names_of_allowed_modules, global.universally_allowed_modules)
    add_module_names(names_of_allowed_modules, global.allowed_modules_by_recipe[module_gui.tags.recipe_name])

    local module_slot = module_gui.add{type = "flow", direction = "vertical"}
    module_slot.style.horizontal_align = "center"
    module_slot.add{
        type = "choose-elem-button",
        name = "hxrrc_choose_module_button",
        tooltip = {"hxrrc.choose_module_button_tooltip"},
        elem_type = "item",
        item = module_name,
        elem_filters = {{filter = "name", name = names_of_allowed_modules}},
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
        clear_and_focus_on_right_click = true,
    }
    textfield.style.width = 32
end

local function add_module_data(main_module_flow)
    local label_flow = main_module_flow.add{type = "flow", direction = "vertical"}
    local module_preferences = global[main_module_flow.player_index].module_preferences_by_recipe_name[main_module_flow.tags.recipe_name]
    for _, effect in ipairs{"consumption", "speed", "productivity", "pollution"} do
        label_flow.add{type = "label", caption = effect .. ": " .. string.format("%.0f", module_preferences.effects[effect].bonus * 100) .. "%"}
    end
end

function ModuleGUI.new(parent, recipe_name)
    local main_module_flow = parent.add{type = "flow", direction = "horizontal"}
    main_module_flow.tags = {recipe_name = recipe_name}

    local module_gui = main_module_flow.add{type = "flow", direction = "horizontal"}
    module_gui.tags = {recipe_name = recipe_name}
    module_gui.style.horizontally_stretchable = true
    module_gui.style.right_padding = 4

    local modules = global[module_gui.player_index].module_preferences_by_recipe_name[recipe_name]
    for index, module_name in ipairs(modules) do
        add_module_slot(module_gui, module_name, modules[-index])
    end
    add_module_slot(module_gui)

    --add_module_data(main_module_flow)
end

function ModuleGUI.on_gui_elem_changed(event)
    local choose_module_button = event.element
    local module_slot = choose_module_button.parent
    local module_gui = module_slot.parent
    local index = module_slot.get_index_in_parent()
    local recipe_name = module_gui.tags.recipe_name
    local module_preferences = global[choose_module_button.player_index].module_preferences_by_recipe_name[recipe_name]

    if not choose_module_button.elem_value and index < #module_gui.children then
        local module_prototype = game.item_prototypes[module_preferences[index]]
        for _, effect in ipairs({"consumption", "speed", "productivity", "pollution"}) do
            if module_prototype.module_effects[effect] then
                module_preferences.effects[effect].bonus = module_preferences.effects[effect].bonus - module_preferences[-index] * module_prototype.module_effects[effect].bonus 
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
            --the last module slot was set, so its textfiled must be enabled, the module's count set to 0, and a new one must be added
            module_slot.hxrrc_module_count_textfield.enabled = true
            module_preferences[-index] = 0
            add_module_slot(module_gui)
        else
            --a previous module was replaced
            local module_prototype = game.item_prototypes[module_preferences[index]]
            for _, effect in ipairs({"consumption", "speed", "productivity", "pollution"}) do
                if module_prototype.module_effects[effect] then
                    module_preferences.effects[effect].bonus = module_preferences.effects[effect].bonus - module_preferences[-index] * module_prototype.module_effects[effect].bonus 
                end
            end
        end
        module_preferences[index] = choose_module_button.elem_value
        local module_prototype = game.item_prototypes[module_preferences[index]]
        for _, effect in ipairs({"consumption", "speed", "productivity", "pollution"}) do
            if module_prototype.module_effects[effect] then
                module_preferences.effects[effect].bonus = module_preferences.effects[effect].bonus + module_preferences[-index] * module_prototype.module_effects[effect].bonus
            end
        end
    end
end

function ModuleGUI.on_gui_confirmed(event)
    local textfield = event.element
    local module_slot = textfield.parent
    local index = module_slot.get_index_in_parent()
    local recipe_name = module_slot.parent.tags.recipe_name
    local module_preferences = global[textfield.player_index].module_preferences_by_recipe_name[recipe_name]
    local module_prototype = game.item_prototypes[module_preferences[index]]

    local new_value = tonumber(textfield.text) or 0
    local delta = new_value - module_preferences[-index]
    for _, effect in ipairs({"consumption", "speed", "productivity", "pollution"}) do
        if module_prototype.module_effects[effect] then
            module_preferences.effects[effect].bonus = module_preferences.effects[effect].bonus + delta * module_prototype.module_effects[effect].bonus 
        end
    end

    module_preferences[-index] = new_value
end

return ModuleGUI