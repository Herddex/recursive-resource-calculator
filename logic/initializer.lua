local Initializer = {}

local function initialize_chosen_crafting_machines(player_index)
    local machine_names_by_recipe_name = {}
    for recipe_name, recipe in pairs(game.recipe_prototypes) do
        machine_names_by_recipe_name[recipe_name] = global.crafting_machines_by_category[recipe.category][1].name
    end
    global[player_index].names_of_chosen_crafting_machines_by_recipe_name = machine_names_by_recipe_name
end

local function initialize_used_recipes(player_index)
    local recipe_preferences = {}
    for product_full_name, recipe_prototype_list in pairs(global.recipe_lists_by_product_full_name) do
        if #recipe_prototype_list == 1 then
            recipe_preferences[product_full_name] = recipe_prototype_list[1]
        end
    end
    global[player_index].recipe_preferences = recipe_preferences
end

local function initialize_module_effects(player_index)
    local module_effects_by_recipe = {}
    for recipe_name, _ in pairs(game.recipe_prototypes) do
        module_effects_by_recipe[recipe_name] = {effects = {consumption = {bonus = 0}, speed = {bonus = 0}, productivity = {bonus = 0}, pollution = {bonus = 0}}}
    end
    global[player_index].module_preferences_by_recipe_name = module_effects_by_recipe
end

function Initializer.initialize_player_data(player_index)
    global[player_index] = {}
    global[player_index].backlogged_computation_count = 0
    initialize_chosen_crafting_machines(player_index)
    initialize_used_recipes(player_index)
    initialize_module_effects(player_index)
end

return Initializer