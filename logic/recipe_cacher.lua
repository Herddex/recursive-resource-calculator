local RecipeCacher = {}

--A function that computes a table mapping each item/fluid in the game to a list of recipes that have it as a product
local function cache_recipes()
    local recipes = {}
    for _, recipe in pairs(game.forces[1].recipes) do
        if recipe.prototype.allow_decomposition and #recipe.products == 1 then
            for _, product in ipairs(recipe.products) do
                local full_name = product.type .. "/" .. product.name
                if recipes[full_name] then
                    recipes[full_name][#recipes[full_name] + 1] = recipe
                else
                    recipes[full_name] = {recipe} 
                end
            end
        end
    end

    --Delete cached recipes for items with multiple recipes
    for full_name, recipe_list in pairs(recipes) do
        if #recipe_list > 1 then
            recipes[full_name] = nil
        end
    end
    
    global.recipes = recipes
end

--A function that computes a table mapping each recipe category to a list of all the crafting machines that can execute recipes of that category
local function cache_crafting_machines()
    local crafting_machines_for_category = {}
    for _, machine in pairs(game.get_filtered_entity_prototypes{{filter="crafting-machine"}}) do
        for category, _ in pairs(machine.crafting_categories) do
            if crafting_machines_for_category[category] then
                crafting_machines_for_category[category][#crafting_machines_for_category[category] + 1] = machine
            else
                crafting_machines_for_category[category] = {machine}
            end
        end
    end
    global.crafting_machines_for_category = crafting_machines_for_category
end

function RecipeCacher.cache()
    cache_recipes()
    cache_crafting_machines()
end

return RecipeCacher