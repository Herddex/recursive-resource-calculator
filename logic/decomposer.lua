local Decomposer = {}

--computes the average amount of product for the given LuaProduct
local function compute_amount(product)
    return (product.amount or ((product.amount_min + product.amount_max) / 2)) * product.probability
end

local function get_products(recipe, main_product_full_name)
    local main_product
    local byproducts = {}
    for _, product in ipairs(recipe.products) do
        if product.type .. "/" .. product.name == main_product_full_name then
            main_product = product
        else
            byproducts[#byproducts + 1] = product
        end
    end
    return main_product, byproducts
end

function Decomposer.module_effect_multiplier(player_index, recipe_name, effect)
    local multiplier = global[player_index].module_preferences_by_recipe_name[recipe_name].effects[effect].bonus + 1
    return multiplier > 0.2 and multiplier or 0.2
end

function Decomposer.decompose(product_production_rate, full_product_name, production_rates, player_index, set_of_current_branch)
    if set_of_current_branch[full_product_name] then
        --Cycle detected
        return
    end
    set_of_current_branch[full_product_name] = true

    production_rates[full_product_name] = production_rates[full_product_name] and production_rates[full_product_name] + product_production_rate or product_production_rate  
    local recipe = global[player_index].recipe_preferences[full_product_name]
    if recipe then
        local productivity_multiplier = Decomposer.module_effect_multiplier(player_index, recipe.name, "productivity")
        --Get the product and possible byproducts:
        local product, byproducts = get_products(recipe, full_product_name)
        local main_product_amount = compute_amount(product) * productivity_multiplier
        local recipes_per_second = product_production_rate / main_product_amount

        for _, byproduct in ipairs(byproducts) do
            local byproduct_amount = compute_amount(byproduct) * productivity_multiplier
            local byproduct_full_name = byproduct.type .. "/" .. byproduct.name
            local byproduct_production_rate = byproduct_amount * recipes_per_second
            production_rates[byproduct_full_name] = production_rates[byproduct_full_name] and 
            production_rates[byproduct_full_name] - byproduct_production_rate or -byproduct_production_rate
        end
        
        for _, ingredient in ipairs(recipe.ingredients) do
            local full_ingridient_name = ingredient.type .. "/" .. ingredient.name
            local ingredient_amount = ingredient.amount
            local ingredient_production_rate = ingredient_amount * recipes_per_second
            Decomposer.decompose(ingredient_production_rate, full_ingridient_name, production_rates, player_index, set_of_current_branch)
        end
    end

    set_of_current_branch[full_product_name] = nil
end
--Returns the number of machines of the type crafting_machine needed to achieve the specified production rate of the given item/fluid given by its full_product_name 
function Decomposer.machine_amount(full_product_name, product_production_rate, crafting_machine, player_index)
    local recipe = global[player_index].recipe_preferences[full_product_name]
    local speed_multiplier = Decomposer.module_effect_multiplier(player_index, recipe.name, "speed")
    local productivity_multiplier = Decomposer.module_effect_multiplier(player_index, recipe.name, "productivity") * (crafting_machine.base_productivity + 1)
    local product = get_products(recipe, full_product_name)
    local amount = compute_amount(product)
    local base_recipe_production_per_second = amount / recipe.energy
    local crafting_speed = crafting_machine.crafting_speed * speed_multiplier * productivity_multiplier
    local production_per_machine_per_second = base_recipe_production_per_second * crafting_speed
    return product_production_rate / production_per_machine_per_second
end

return Decomposer