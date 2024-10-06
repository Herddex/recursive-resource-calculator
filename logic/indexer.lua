local Indexer = {}

local function insert_multimap(multimap, key, value)
    if not multimap[key] then
        multimap[key] = {value}
    else
        table.insert(multimap[key], value)
    end
end

local function index_recipes()
    local recipes = {}
    for _, recipe_prototype in pairs(game.recipe_prototypes) do
        for _, product in ipairs(recipe_prototype.products) do
            insert_multimap(recipes, product.type .. "/" .. product.name, recipe_prototype)
        end
    end
    global.recipe_lists_by_product_full_name = recipes
end

local function compute_pollution(entity_prototype)
    local energy_source = entity_prototype.electric_energy_source_prototype or entity_prototype.burner_prototype or entity_prototype.heat_energy_source_prototype or entity_prototype.fluid_energy_source_prototype or entity_prototype.void_energy_source_prototype
    if energy_source then
      return entity_prototype.max_energy_usage * energy_source.emissions * 60
    end
    return 0
end

local function index_crafting_machines()
    local crafting_machines_by_category = {}
    for _, machine in pairs(game.get_filtered_entity_prototypes{{filter="crafting-machine"}}) do
        for category, _ in pairs(machine.crafting_categories) do
            insert_multimap(crafting_machines_by_category, category, machine)
        end
    end
    global.crafting_machines_by_category = crafting_machines_by_category
end

local function index_crafting_machine_pollution()
    local pollution_by_crafting_machine = {}
    for machine_name, machine in pairs(game.get_filtered_entity_prototypes{{filter="crafting-machine"}}) do
        pollution_by_crafting_machine[machine_name] = compute_pollution(machine)
    end
    global.pollution_by_crafting_machine = pollution_by_crafting_machine
end

local function index_modules()
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
                table.insert(allowed_modules_by_recipe[recipe_name], module)
            end
        end
    end

    global.modules_by_name = modules_by_name
    global.universally_allowed_modules = universally_allowed_modules
    global.allowed_modules_by_recipe = allowed_modules_by_recipe
end

function Indexer.run()
    index_recipes()
    index_crafting_machines()
    index_crafting_machine_pollution()
    index_modules()
end

return Indexer