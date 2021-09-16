local Initializer = {}

local function initialize_crafting_machine_preferences(player_index)
    local crafting_machine_preferences = {}
    for category, crafting_machine_prototype_list in pairs(global.crafting_machines_by_category) do
        crafting_machine_preferences[category] = crafting_machine_prototype_list[1]
    end
    global[player_index].crafting_machine_preferences = crafting_machine_preferences
end

local function initialize_recipe_preferences(player_index)
    local recipe_preferences = {}
    for item_or_fluid_full_name, recipe_prototype_list in pairs(global.recipes) do
        recipe_preferences[item_or_fluid_full_name] = recipe_prototype_list[1]
    end
    global[player_index].recipe_preferences = recipe_preferences
end

local function initialize_module_preferences(player_index)
    local module_preferences_by_recipe_name = {}
    for recipe_name, _ in pairs(game.recipe_prototypes) do
        module_preferences_by_recipe_name[recipe_name] = {}
        module_preferences_by_recipe_name[recipe_name].effects = {consumption = {bonus = 0}, speed = {bonus = 0}, productivity = {bonus = 0}, pollution = {bonus = 0}}
    end
    global[player_index].module_preferences_by_recipe_name = module_preferences_by_recipe_name
end

function Initializer.initialize_player_data(player_index)
    global[player_index] = {}
    initialize_crafting_machine_preferences(player_index)
    initialize_recipe_preferences(player_index)
    initialize_module_preferences(player_index)
end

return Initializer