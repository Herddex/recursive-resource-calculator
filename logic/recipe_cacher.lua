local RecipeCacher = {}

--A function that (re)computes a table mapping each item/fluid in the game to a list of recipes that have it as a product
function RecipeCacher.cache()
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
    global.recipes = recipes
end

return RecipeCacher