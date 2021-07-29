local Rational = require "utils/rational"
local Set = require "utils/set"

Decomposer = {}

--computes the average amount of product for the given LuaProduct
local function compute_amount(product)
    local amount = product.amount
    if not amount then
        local average = (product.amount_min + product.amount_max) / 2
        amount = average * product.probability
    end
    return Rational.from_string(tostring(amount))
end

function Decomposer.decompose(production_rate, full_prototype_name, total_production_rates, inbound_dependencies, outbound_dependencies)
    total_production_rates[full_prototype_name] = total_production_rates[full_prototype_name] and total_production_rates[full_prototype_name] + production_rate or production_rate
    
    local viable_recipes = global.recipes[full_prototype_name]
    if viable_recipes and #viable_recipes == 1 then
        local recipe = viable_recipes[1]
        local product = recipe.products[1]
        local amount = compute_amount(product)
        local rate_coefficient = production_rate / amount

        for _, ingredient in ipairs(recipe.ingredients) do
            local full_ingridient_name = ingredient.type .. "/" .. ingredient.name
            
            --Record the dependency in both directions after initializing the dependency sets for the ingridient if necesarry
            if not inbound_dependencies[full_ingridient_name] then
                inbound_dependencies[full_ingridient_name] = Set.new()
                outbound_dependencies[full_ingridient_name] = Set.new()
            end
            Set.add(outbound_dependencies[full_ingridient_name], full_prototype_name)
            Set.add(inbound_dependencies[full_prototype_name], full_ingridient_name)

            local base_amount = Rational.from_string(tostring(ingredient.amount))
            local final_rate = base_amount * rate_coefficient
            Decomposer.decompose(final_rate, full_ingridient_name, total_production_rates, inbound_dependencies, outbound_dependencies)
        end
    end
end

--Returns the (rational) number of machines of the type crafting_machine needed to achieve the specified production rate of the given item/fluid given by its full_prototype_name 
function Decomposer.machine_amount(full_prototype_name, production_rate, crafting_machine)
    local recipe = global.recipes[full_prototype_name][1]
    local product = recipe.products[1]
    local amount = compute_amount(product)
    local base_recipe_production_per_second = amount / Rational.from_string(tostring(recipe.energy))
    local crafting_speed = Rational.from_string(tostring(crafting_machine.crafting_speed))
    local production_per_machine_per_second = base_recipe_production_per_second * crafting_speed
    return production_rate / production_per_machine_per_second
end

return Decomposer