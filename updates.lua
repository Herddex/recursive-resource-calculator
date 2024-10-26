--Handles control-side migrations from older versions of the mod
--When updating the mod, all the update functions in this file that correspond to versions greater than the old version will be executed in order from the oldest version to the newest version
local Sheet = require "gui.sheet"
local PlayerData = require "logic.player_data"

local Updates = {}
local versions = {"1.0.0", "1.0.1", "1.0.2", "1.0.3", "1.0.4", "1.0.5", "1.0.6", "1.0.7", "1.0.8", "1.1.0", "1.1.1", "1.1.2", "1.1.3", "1.1.4"}

function Updates.update_from(old_version)
    local newer_versions_reached = false --flag
    for _, version in ipairs(versions) do --iterate trough the versions array in order
        if newer_versions_reached and Updates[version] then --if the currently iterated version is newer then the old one and there are updates to apply from this version
            Updates[version]() --apply the update
        end
        if old_version == version then --set the newer_versions_reached flag
            newer_versions_reached = true
        end
    end
end

local function remove_totals_section()
    for pi, _ in pairs(game.players) do
        storage[pi].totals_section.destroy()
        storage[pi].totals_section = nil
        storage[pi].totals_table_flow = nil
        storage[pi].total_production_rates = nil
        storage[pi].sheet_section.visible = true
        storage[pi].sheet_section.children[1].children[1].destroy()
        for _, tab_and_content in ipairs(storage[pi].sheet_section.sheet_pane.tabs) do
            tab_and_content.content.tags = {}
        end
    end
end

local function update_old_1_0_preferences()
    for pi, _ in pairs(game.players) do
        storage[pi].crafting_machine_preferences = nil
        storage[pi].names_of_chosen_crafting_machines_by_recipe_name = {}
        storage[pi].recipe_preferences = nil
        PlayerData.initialize_recipe_bindings(pi)
    end
end

Updates["1.1.0"] = function()
    remove_totals_section()
    Sheet._repair_old_sheets()
    update_old_1_0_preferences()
end

local function update_crafting_machine_preferences_to_be_quality_compatible()
    for pi, _ in pairs(game.players) do
        storage[pi].identifiers_of_chosen_crafting_machines_by_recipe_name = {}
        for recipe_name, crafting_machine_name in pairs(storage[pi].names_of_chosen_crafting_machines_by_recipe_name) do
            storage[pi].identifiers_of_chosen_crafting_machines_by_recipe_name[recipe_name] = {name = crafting_machine_name}
        end
        storage[pi].names_of_chosen_crafting_machines_by_recipe_name = nil
    end
end

local function update_old_module_preferences()
    for pi, _ in pairs(game.players) do
        for _, module_preference in pairs(storage[pi].module_preferences_by_recipe_name) do
            for effect_name, old_bonus_table in pairs(module_preference.effects) do
                module_preference.effects[effect_name] = old_bonus_table.bonus
            end
            module_preference.effects.quality = 0
        end
    end
end

Updates["1.1.4"] = function()
    storage.universally_allowed_modules = nil
    storage.allowed_modules_by_recipe = nil
    storage.modules_by_name = nil
    update_crafting_machine_preferences_to_be_quality_compatible()
    update_old_module_preferences()
end

return Updates