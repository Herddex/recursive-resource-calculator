local Decomposer = require "logic/decomposer"

local function compute_for_product(product_full_name, production_rate, recipe, player_index)
    local energy_consumption_multiplier = Decomposer.module_effect_multiplier(player_index, recipe.name, "consumption")
    local crafting_machine_name = global[player_index].names_of_chosen_crafting_machines_by_recipe_name[recipe.name]
    local crafting_machine = game.entity_prototypes[crafting_machine_name]

    local machine_amount = Decomposer.machine_amount(product_full_name, production_rate, crafting_machine, player_index)
    energy_consumption = crafting_machine.energy_usage * 60 * machine_amount * energy_consumption_multiplier

    local pollution_multiplier = Decomposer.module_effect_multiplier(player_index, recipe.name, "pollution")
    pollution = global.pollution_by_crafting_machine[crafting_machine.name] * machine_amount * pollution_multiplier * energy_consumption_multiplier

    return energy_consumption, pollution
end

return function(player_index, production_rates)
    local total_energy_usage = 0
    local total_pollution = 0

    for product_full_name, production_rate in pairs(production_rates) do
        local recipe = global[player_index].recipe_preferences[product_full_name]
        if recipe then
            local energy_usage, pollution = compute_for_product(product_full_name, production_rate, recipe, player_index)
            total_energy_usage = total_energy_usage + energy_usage
            total_pollution = total_pollution + pollution
        end
    end

    return total_energy_usage, total_pollution
end