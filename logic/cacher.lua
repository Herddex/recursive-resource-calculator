local Cacher = {}

--A function that computes a table mapping each item/fluid in the game to a list of recipes that have it as a product
local function cache_recipes()
    local recipes = {}
    for _, recipe_prototype in pairs(game.recipe_prototypes) do
        for _, product in ipairs(recipe_prototype.products) do
            local product_full_name = product.type .. "/" .. product.name
            if recipes[product_full_name] then
                recipes[product_full_name][#recipes[product_full_name] + 1] = recipe_prototype
            else
                recipes[product_full_name] = {recipe_prototype}
            end
        end
    end
    
    global.recipes = recipes
end

local function pollution(entity_prototype)
    local energy_source = entity_prototype.electric_energy_source_prototype or entity_prototype.burner_prototype
    local energy_usage = entity_prototype.energy_usage
    if energy_source and energy_usage then
      return energy_usage * energy_source.emissions * 60
    end
    return 0
end

--A function that computes a table mapping each recipe category to a list of all the crafting machines that can execute recipes of that category, as well as a table mapping each crafting machine name (string) to its base pollution per minute (double)
local function cache_crafting_machines()
    local crafting_machines_by_category = {}
    local pollution_per_minute_of_crafting_machines = {}
    for machine_name, machine in pairs(game.get_filtered_entity_prototypes{{filter="crafting-machine"}}) do
        pollution_per_minute_of_crafting_machines[machine_name] = pollution(machine)
        for category, _ in pairs(machine.crafting_categories) do
            if crafting_machines_by_category[category] then
                crafting_machines_by_category[category][#crafting_machines_by_category[category]+1] = machine
            else
                crafting_machines_by_category[category] = {machine}
            end
        end
    end
    global.crafting_machines_by_category = crafting_machines_by_category
    global.pollution_per_minute_of_crafting_machines = pollution_per_minute_of_crafting_machines
end

local function cache_modules()
    local modules_by_name = {} --a dictionary mapping module names to their prototypes.
    local universally_allowed_modules = {} --array of all the modules that work with any recipe out there
    local allowed_modules_by_recipe = {} --a dictionary of recipe prototype names to arrays of modules; binds each recipe in the game to an array of all the modules that work with that recipe (excluding the universally allowed modules)
    for recipe_name, _ in pairs(game.recipe_prototypes) do
        allowed_modules_by_recipe[recipe_name] = {} --initializing the arrays
    end

    for module_name, module in pairs(game.get_filtered_item_prototypes({{filter = "type", type = "module"}})) do
        modules_by_name[module_name] = module
        if #module.limitations == 0 then
            universally_allowed_modules[#universally_allowed_modules+1] = module
        else
            for _, recipe_name in ipairs(module.limitations) do
                allowed_modules_by_recipe[recipe_name][#allowed_modules_by_recipe[recipe_name]+1] = module
            end
        end
    end

    global.modules_by_name = modules_by_name
    global.universally_allowed_modules = universally_allowed_modules
    global.allowed_modules_by_recipe = allowed_modules_by_recipe
end

function Cacher.cache()
    cache_recipes()
    cache_crafting_machines()
    cache_modules()
end

return Cacher