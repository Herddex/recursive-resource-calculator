--Handles control-side migrations from older versions of the mod
--When updating the mod, all the update functions in this file that correspond to versions greater than the old version will be executed in order from the oldest version to the newest version
local Sheet = require "gui/sheet"

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

Updates["1.1.0"] = function()
    Sheet._repair_old_sheets()
end

return Updates