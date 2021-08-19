local Set = require "utils/set"
local Cacher = {}

--A function that 1) computes a table mapping each item/fluid in the game to a list of recipes that have it as a product, but deletes entries of items/fluids with multiple recipes and ignores recipies with byproducts; 2) Computes two tables mapping each item/fluid to its inbound dependencies (the items/fluids needed to make it) and its outbound dependencies (items/fluids that use it as an ingredient) respectively, only using the afromentioned recipes.
local function cache_recipes_and_dependencies()
    local recipes = {}
    local inbound_dependencies = {}
    local outbound_dependencies = {}
    for _, recipe_prototype in pairs(game.recipe_prototypes) do
        if recipe_prototype.allow_decomposition then
            for _, product in ipairs(recipe_prototype.products) do
                local product_full_name = product.type .. "/" .. product.name
                if not inbound_dependencies[product_full_name] then
                    inbound_dependencies[product_full_name] = Set.new()
                end

                for _, ingredient in ipairs(recipe_prototype.ingredients) do
                    local ingridient_full_name = ingredient.type .. "/" .. ingredient.name
                    Set.add(inbound_dependencies[product_full_name], ingridient_full_name)

                    if not outbound_dependencies[ingridient_full_name] then
                        outbound_dependencies[ingridient_full_name] = Set.new()
                    end
                    Set.add(outbound_dependencies[ingridient_full_name], product_full_name)
                end
                
                if recipes[product_full_name] then
                    recipes[product_full_name][#recipes[product_full_name] + 1] = recipe_prototype
                else
                    recipes[product_full_name] = {recipe_prototype}
                end
            end
        end
    end
    
    global.recipes = recipes
    global.inbound_dependencies = inbound_dependencies
    global.outbound_dependencies = outbound_dependencies
end

--A function that computes a table mapping each recipe category to a list of all the crafting machines that can execute recipes of that category
local function cache_crafting_machines()
    local crafting_machines_by_category = {}
    for _, machine in pairs(game.get_filtered_entity_prototypes{{filter="crafting-machine"}}) do
        for category, _ in pairs(machine.crafting_categories) do
            if crafting_machines_by_category[category] then
                crafting_machines_by_category[category][#crafting_machines_by_category[category] + 1] = machine
            else
                crafting_machines_by_category[category] = {machine}
            end
        end
    end
    global.crafting_machines_by_category = crafting_machines_by_category
end

function Cacher.cache()
    cache_recipes_and_dependencies()
    cache_crafting_machines()
end

return Cacher