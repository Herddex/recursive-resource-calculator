local Reinitializer = {}

local function reinitialize_crafting_machine_preferences(player_index)
    local crafting_machines_by_category = global.crafting_machines_by_category
    local crafting_machine_preferences = global[player_index].crafting_machine_preferences
    
    --initialize new categories:
    for category, crafting_machine_list in pairs(crafting_machines_by_category) do
        if not crafting_machine_preferences[category] then
            crafting_machine_preferences[category] = crafting_machine_list[1]
        end
    end

    --reset the crafting machines of current categories if their preferred crafting machine was deleted and delete categories without crafting machines:
    for category, preferred_crafting_machine in pairs(crafting_machine_preferences) do
        if not preferred_crafting_machine.valid then
            preferred_crafting_machine[category] = crafting_machines_by_category[category] and crafting_machines_by_category[category][1] or nil
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

local function reinitialize_recipe_preferences(player_index)
    local recipe_preferences = global[player_index].recipe_preferences

    --remove recipes that are no longer valid:
    for item_or_fluid_full_name, recipe_prototype in pairs(recipe_preferences) do
        if not recipe_prototype.valid or not has_product(recipe_prototype, item_or_fluid_full_name) then
            recipe_preferences[item_or_fluid_full_name] = nil
        end
    end
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

function Reinitializer.reinitialize(player_index)
    reinitialize_crafting_machine_preferences(player_index)
    reinitialize_recipe_preferences(player_index)
    reinitialize_module_preferences(player_index)
end

return Reinitializer