local PlayerDataUpdater = {}

local function reinitialize_chosen_crafting_machines(player_index)
    local machine_name_by_recipe_name = global[player_index].names_of_chosen_crafting_machines_by_recipe_name
    for recipe_name, crafting_machine_name in pairs(machine_name_by_recipe_name) do
        local recipe = game.recipe_prototypes[recipe_name]
        if not recipe then
            machine_name_by_recipe_name[recipe_name] = nil
        elseif not game.entity_prototypes[crafting_machine_name] then
            machine_name_by_recipe_name[recipe_name] = global.crafting_machines_by_category[recipe.category][1].name
        end
    end

    for recipe_name, recipe in pairs(game.recipe_prototypes) do
        if not machine_name_by_recipe_name[recipe_name] then
            machine_name_by_recipe_name[recipe_name] = global.crafting_machines_by_category[recipe.category][1].name
        end
    end
end

local function has_product(recipe_prototype, product_full_name)
    for _, product in ipairs(recipe_prototype.products) do
        if product.type .. "/" .. product.name == product_full_name then
            return true
        end
    end
    return false
end

local function rebuild_inverse_recipe_bindings(player_index)
    local product_full_names_by_recipe_name = {}

    for product_full_name, recipe in pairs(global[player_index].recipes_by_product_full_name) do
        product_full_names_by_recipe_name[recipe.name] = product_full_name
    end

    global[player_index].product_full_names_by_recipe_name = product_full_names_by_recipe_name
end

local function update_recipe_bindings(player_index)
    local recipes_by_product_full_name = global[player_index].recipes_by_product_full_name

    --remove recipes that are no longer valid:
    for item_or_fluid_full_name, recipe_prototype in pairs(recipes_by_product_full_name) do
        if not recipe_prototype.valid or not has_product(recipe_prototype, item_or_fluid_full_name) then
            recipes_by_product_full_name[item_or_fluid_full_name] = nil
        end
    end

    rebuild_inverse_recipe_bindings(player_index)
end

local function check_for_deleted_modules()
    local modules_were_deleted = false
    for _, module in pairs(global.modules_by_name) do
        if not module.valid then
            modules_were_deleted = true
            return
        end
    end
    return modules_were_deleted
end

local function reinitialize_module_preferences(player_index)
    local modules_were_deleted = check_for_deleted_modules()
    local module_preferences = global[player_index].module_preferences_by_recipe_name
    local modules_by_name = global.modules_by_name
    for recipe_name, _ in pairs(game.recipe_prototypes) do
        if not module_preferences[recipe_name] then
            module_preferences[recipe_name] = {effects = {consumption = {bonus = 0}, speed = {bonus = 0}, productivity = {bonus = 0}, pollution = {bonus = 0}}}
        end
    end
    for recipe_name, preferences_table in pairs(module_preferences) do
        if not game.recipe_prototypes[recipe_name] then
            module_preferences[recipe_name] = nil
        elseif modules_were_deleted then
            local effects_table_recomputation_needed = false
            for index, module_name in ipairs(preferences_table) do
                if not modules_by_name[module_name] then
                    preferences_table[-index] = preferences_table[-#preferences_table]
                    preferences_table[-#preferences_table] = nil
                    preferences_table[index] = preferences_table[#preferences_table]
                    preferences_table[#preferences_table] = nil
                    effects_table_recomputation_needed = true
                end
            end
            if effects_table_recomputation_needed then
                for _, effect in ipairs({"consumption", "speed", "productivity", "pollution"}) do
                    module_preferences.effects[effect].bonus = 0
                end
                for index, module_name in ipairs(preferences_table) do
                    local module_prototype = modules_by_name[module_name]
                    for _, effect in ipairs({"consumption", "speed", "productivity", "pollution"}) do
                        if module_prototype.module_effects[effect] then
                            module_preferences.effects[effect].bonus = module_preferences.effects[effect].bonus - module_preferences[-index] * module_prototype.module_effects[effect].bonus
                        end
                    end
                end
            end
        end
    end
end

function PlayerDataUpdater.reinitialize(player_index)
    reinitialize_chosen_crafting_machines(player_index)
    update_recipe_bindings(player_index)
    reinitialize_module_preferences(player_index)
end

return PlayerDataUpdater