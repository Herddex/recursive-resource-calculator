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

    module_gui.choose_module_buttons_flow.add{
        type = "choose-elem-button",
        tags = {is_hxrrc_choose_module_button = true},
        tooltip = {"hxrrc.choose_module_button_tooltip"},
        elem_type = "item",
        item = module_name,
        elem_filters = {{filter = "name", name = names_of_allowed_modules}},
    }
    local textfield = module_gui.textfields_flow.add{
        type = "textfield",
        tags = {is_hxrrc_module_count_textfield = true},
        tooltip = {"hxrrc.module_count_textfield_tooltip"},
        text = module_count,
        enabled = not not module_count,
        numeric = true,
        allow_decimal = true,
        allow_negative = false,
        lose_focus_on_confirm = true,
        clear_and_focus_on_right_click = true,
    }
    textfield.style.width = 40
end

function ModuleGUI.new(parent, recipe_name)
    local module_gui = parent.add{type = "flow", direction = "vertical"}
    module_gui.tags = {recipe_name = recipe_name}
    module_gui.style.horizontally_stretchable = true
    local choose_module_buttons_flow = module_gui.add{type = "flow", name = "choose_module_buttons_flow", direction = "horizontal"}
    choose_module_buttons_flow.style.right_padding = 4
    local textfields_flow = module_gui.add{type = "flow", name = "textfields_flow", direction = "horizontal"}
    textfields_flow.style.right_padding = 4

    local modules = global[module_gui.player_index].module_preferences_by_recipe_name[recipe_name]
    for index, module_name in ipairs(modules) do
        add_module_slot(module_gui, module_name, modules[-index])
    end
    add_module_slot(module_gui)
end

function ModuleGUI.on_gui_elem_changed(event)
    local choose_module_button = event.element
    local index = choose_module_button.get_index_in_parent()
    local recipe_name = choose_module_button.parent.parent.tags.recipe_name
    local module_list = global[choose_module_button.player_index].module_preferences_by_recipe_name[recipe_name]

    if not choose_module_button.elem_value and index < #choose_module_button.parent.children then
        --a button that was not the last one was emptied, so the module data must be shifted to fill the gap, and the button must be deleted along with its textfield buddy
        for i = index + 1, #module_list do
            module_list[i - 1] = module_list[i]
            module_list[-i + 1] = module_list[-i]
        end
        module_list[#module_list], module_list[-#module_list] = nil, nil

        choose_module_button.parent.parent.textfields_flow.children[index].destroy()
        choose_module_button.destroy()

    elseif choose_module_button.elem_value then
        module_list[index] = choose_module_button.elem_value
        if index == #choose_module_button.parent.children then
            --the last module button was set, so its textfiled must be enabled, the module's count set to 0, and a new one must be added
            choose_module_button.parent.parent.textfields_flow.children[index].enabled = true
            module_list[-index] = 0
            add_module_slot(choose_module_button.parent.parent)
        end
    end
end

function ModuleGUI.on_gui_confirmed(event)
    local textfield = event.element
    local index = textfield.get_index_in_parent()
    local recipe_name = textfield.parent.parent.tags.recipe_name
    local module_list = global[textfield.player_index].module_preferences_by_recipe_name[recipe_name]
    module_list[-index] = tonumber(textfield.text) or 0
end

return ModuleGUI