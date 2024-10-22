--Handles control-side migrations from older versions of the mod
--When updating the mod, all the update functions in this file that correspond to versions greater than the old version will be executed in order from the oldest version to the newest version
local Sheet = require "gui.sheet"
local PlayerData = require "logic.player_data"

local Updates = {}
local versions = {"1.0.0", "1.0.1", "1.0.2", "1.0.3", "1.0.4", "1.0.5", "1.0.6", "1.0.7", "1.0.8", "1.1.0"}

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
    for _, player in pairs(game.players) do
        local player_index = player.index
        storage[player_index].totals_section.destroy()
        storage[player_index].totals_section = nil
        storage[player_index].totals_table_flow = nil
        storage[player_index].total_production_rates = nil
        storage[player_index].sheet_section.visible = true
        storage[player_index].sheet_section.children[1].children[1].destroy()
        for _, tab_and_content in ipairs(storage[player_index].sheet_section.sheet_pane.tabs) do
            tab_and_content.content.tags = {}
        end
    end
end

local function update_old_preferences()
    for player_index, _ in pairs(game.players) do
        storage[player_index].crafting_machine_preferences = nil
        storage[player_index].names_of_chosen_crafting_machines_by_recipe_name = {}
        storage[player_index].recipe_preferences = nil
        PlayerData.initialize_recipe_bindings(player_index)
    end
end

Updates["1.1.0"] = function()
    remove_totals_section()
    Sheet._repair_old_sheets()
    update_old_preferences()
end

Updates["1.1.1"] = function()
    storage.universally_allowed_modules = nil
    storage.allowed_modules_by_recipe = nil
    storage.modules_by_name = nil
end

return Updates