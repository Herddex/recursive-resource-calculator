local Set = require "utils/set"
local Cacher = {}

--A function that computes a table mapping each item/fluid in the game to a list of recipes that have it as a product
local function cache_recipes()
    local recipes = {}
    for _, recipe_prototype in pairs(game.recipe_prototypes) do
        if recipe_prototype.allow_decomposition then
            for _, product in ipairs(recipe_prototype.products) do
                local product_full_name = product.type .. "/" .. product.name
                if recipes[product_full_name] then
                    recipes[product_full_name][#recipes[product_full_name] + 1] = recipe_prototype
                else
                    recipes[product_full_name] = {recipe_prototype}
                end
            end
        end
    end
    
    global.recipes = recipes
end

--A function that computes a table mapping each recipe category to a list of all the crafting machines that can execute recipes of that category
local function cache_crafting_machines()
    local crafting_machines_by_category = {}
    for _, machine in pairs(game.get_filtered_entity_prototypes{{filter="crafting-machine"}}) do
        for category, _ in pairs(machine.crafting_categories) do
            if crafting_machines_by_category[category] then
                crafting_machines_by_category[category][#crafting_machines_by_category[category]+1] = machine
            else
                crafting_machines_by_category[category] = {machine}
            end
        end
    end
    global.crafting_machines_by_category = crafting_machines_by_category
end

local function cache_modules()
    local universally_allowed_modules = {} --array of all the modules that work with any recipe out there
    local allowed_modules_by_recipe = {} --a dictionary of recipe prototype names to arrays of modules; binds each recipe in the game to an array of all the modules that work with that recipe (excluding the universally allowed modules)
    for recipe_name, _ in pairs(game.recipe_prototypes) do
        allowed_modules_by_recipe[recipe_name] = {} --initializing the arrays
    end

    for _, module in pairs(game.get_filtered_item_prototypes({{filter = "type", type = "module"}})) do
        if #module.limitations == 0 then
            universally_allowed_modules[#universally_allowed_modules+1] = module
        else
            for _, recipe_name in ipairs(module.limitations) do
                allowed_modules_by_recipe[recipe_name][#allowed_modules_by_recipe[recipe_name]+1] = module
            end
        end
    end

    global.universally_allowed_modules = universally_allowed_modules
    global.allowed_modules_by_recipe = allowed_modules_by_recipe
end

function Cacher.cache()
    cache_recipes()
    cache_crafting_machines()
    cache_modules()
end

return Cacher