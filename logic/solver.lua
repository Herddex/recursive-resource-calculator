local Utils = require "logic.utils"

local Solver = {}

local function determine_used_recipes(recipe, used_recipe_name_set, player_index)
    if not recipe or used_recipe_name_set[recipe.name] then
        return
    end

    used_recipe_name_set[recipe.name] = true

    for _, ingredient in ipairs(recipe.ingredients) do
        local ingridient_full_name = ingredient.type .. "/" .. ingredient.name
        local ingridient_recipe = storage[player_index].recipes_by_product_full_name[ingridient_full_name]
        determine_used_recipes(ingridient_recipe, used_recipe_name_set, player_index)
    end
end

local function get_total_productivity_multiplier_for_recipe(recipe, player_index)
    local crafting_machine_identifier = storage[player_index].identifiers_of_chosen_crafting_machines_by_recipe_name[recipe.name]
    local base_productivity = (crafting_machine_identifier and prototypes.entity[crafting_machine_identifier.name].effect_receiver.base_effect.productivity or 0) + 1
    return base_productivity * Utils.module_effect_multiplier(player_index, recipe.name, "productivity")
end

local function prepare_matrix(used_recipe_name_list, production_rates_by_product_full_name, player_index)
    local N = #used_recipe_name_list
    local A = {}
    local line_numbers_by_product_full_name = {}
    local column_numbers_by_recipe_name = {}
    for i, recipe_name in ipairs(used_recipe_name_list) do
        A[i] = {}

        local product_full_name = storage[player_index].product_full_names_by_recipe_name[recipe_name]
        line_numbers_by_product_full_name[product_full_name] = i
        column_numbers_by_recipe_name[recipe_name] = i
        A[i][N+1] = (production_rates_by_product_full_name[product_full_name] or 0)
    end

    for _, recipe_name in ipairs(used_recipe_name_list) do
        local column = column_numbers_by_recipe_name[recipe_name]
        local recipe = prototypes.recipe[recipe_name]
        --TODO catalysts into account.
        local productivity_multiplier = get_total_productivity_multiplier_for_recipe(recipe, player_index)
        for _, product in ipairs(recipe.products) do
            local product_full_name = product.type .. "/" .. product.name
            local line = line_numbers_by_product_full_name[product_full_name]
            if line then
                A[line][column] = productivity_multiplier * Utils.product_amount(product)
            end
        end
        for _, ingredient in ipairs(recipe.ingredients) do
            local ingredient_full_name = ingredient.type .. "/" .. ingredient.name
            local line = line_numbers_by_product_full_name[ingredient_full_name]
            if line then
                A[line][column] = -ingredient.amount
            end
        end
    end

    return A
end

local function to_nil_if_zero(x)
    return x ~= 0 and x or nil
end

local function is_nil_or_close_to_zero(x)
    return not x or (-0.001 < x and x < 0.001)
end

local function gauss_solve(A)
    for i = 1, #A do
        local pivot_value = A[i][i]
        if is_nil_or_close_to_zero(pivot_value) then
            return --matrix unsolvable for now
        end

        for k = i + 1, #A do
            local k_coefficient = A[k][i]
            if not is_nil_or_close_to_zero(k_coefficient) then
                for column, pivot_line_value in pairs(A[i]) do
                    A[k][column] = to_nil_if_zero((A[k][column] or 0) - pivot_line_value / pivot_value * k_coefficient)
                end
            end
        end
    end

    local solution_values_by_column = {}
    for i = #A, 1, -1 do
        local partial_solution_value = A[i][#A+1] or 0
        for column, coefficient in pairs(A[i]) do
            if column ~= i and column ~= #A + 1 then
                if not solution_values_by_column[column] then
                    partial_solution_value = 0
                end
                partial_solution_value = partial_solution_value - coefficient * solution_values_by_column[column]
            end
        end
        solution_values_by_column[i] = partial_solution_value / A[i][i]
    end

    return solution_values_by_column
end

local function compute_product_rates_by_product_full_name(recipe_rates_by_recipe_name, production_rates_of_final_products_by_product_full_name, player_index)
    local demanded_rates = {}
    local supplied_rates = {}

    for final_product_full_name, production_rate in pairs(production_rates_of_final_products_by_product_full_name) do
        demanded_rates[final_product_full_name] = production_rate
    end

    for recipe_name, recipe_rate in pairs(recipe_rates_by_recipe_name) do
        local recipe = prototypes.recipe[recipe_name]
        for _, ingredient in pairs(recipe.ingredients) do
            local ingredient_full_name = ingredient.type .. "/" .. ingredient.name
            demanded_rates[ingredient_full_name] = (demanded_rates[ingredient_full_name] or 0) + recipe_rate * Utils.product_amount(ingredient)
        end
        for _, product in pairs(recipe.products) do
            --TODO Handle catalysts
            local product_full_name = product.type .. "/" .. product.name
            local productivity_multiplier = get_total_productivity_multiplier_for_recipe(recipe, player_index)
            supplied_rates[product_full_name] = (supplied_rates[product_full_name] or 0) + recipe_rate * productivity_multiplier * Utils.product_amount(product)
        end
    end

    for potential_byproduct_full_name, supplied_rate in pairs(supplied_rates) do
        local demanded_product_rate = demanded_rates[potential_byproduct_full_name] or 0
        if 0.001 < supplied_rate - demanded_product_rate then
            demanded_rates[potential_byproduct_full_name] = demanded_product_rate - supplied_rate
        end
    end

    return demanded_rates
end

function Solver.solve_for(production_rates_by_product_full_name, player_index)
    local used_recipe_name_set = {}
    for product_full_name, _ in pairs(production_rates_by_product_full_name) do
        determine_used_recipes(storage[player_index].recipes_by_product_full_name[product_full_name], used_recipe_name_set, player_index)
    end

    local used_recipe_name_list = {}
    for recipe_name, _ in pairs(used_recipe_name_set) do
        table.insert(used_recipe_name_list, recipe_name)
    end

    local solutions_by_recipe_index = gauss_solve(prepare_matrix(used_recipe_name_list, production_rates_by_product_full_name, player_index))
    if not solutions_by_recipe_index then
        return
    end

    local recipe_rates_by_recipe_name = {}
    for recipe_index, recipe_name in ipairs(used_recipe_name_list) do
        recipe_rates_by_recipe_name[recipe_name] = solutions_by_recipe_index[recipe_index]
    end

    return recipe_rates_by_recipe_name, compute_product_rates_by_product_full_name(recipe_rates_by_recipe_name, production_rates_by_product_full_name, player_index)
end

return Solver