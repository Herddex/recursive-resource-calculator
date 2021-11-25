--Handles GUI migrations from older versions of the mod
--When updating the mod, all the update functions in this file that correspond to versions greater than the old version should be executed in order from the oldest version to the newest version
local Sheet = require "gui/sheet"

local Updates = {}
local versions = {"1.0.0", "1.0.1", "1.0.2", "1.0.3", "1.0.4", "1.0.5", "1.0.6"}

function Updates.update_from(old_version)
    local newer_versions_reached = false --flag
    for _, version in ipairs(versions) do --iterate trough the versions array in order
        if newer_versions_reached and Updates[version] then --if the currently iterated version is newer then the old one and there are updates to apply from this version
            for player_index, _ in pairs(game.players) do --for all the players:
                Updates[version](player_index) --apply the update
            end
        end
        if old_version == version then --set the newer_versions_reached flag
            newer_versions_reached = true
        end
    end
end

Updates["1.0.6"] = function(player_index)
    --GUI change added in 1.0.6: the sheets' input flow label "/m" is changed to a dropdown menu with options "/m" and "/s"
    for _, tab_and_contents in ipairs(global[player_index].sheet_section.sheet_pane.tabs) do
        local input_flow = tab_and_contents.content.input_flow
        local textfield_text = input_flow.hxrrc_input_textfield.text
        local item_input_button_value = input_flow.item_input_button.elem_value
        input_flow.clear()
        --new function that populates the input flow with the new versions of elements
        Sheet.populate_input_flow(input_flow, textfield_text, item_input_button_value)
    end
end

return Updates