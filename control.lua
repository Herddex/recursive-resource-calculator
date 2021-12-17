local Calculator = require "gui/calculator"
local Cacher = require "logic/cacher"
local Initializer = require "logic/initializer"
local Reinitializer = require "logic/reinitializer"
local Updates = require "updates"

script.on_init(function()
    Cacher.cache()
    global.computation_stack = {}
    for player_index, player in pairs(game.players) do
        Initializer.initialize_player_data(player_index)
        Calculator.build(player)
    end
end)

script.on_configuration_changed(function(configuration_changed_data)
    local rrc_version_change = configuration_changed_data.mod_changes.RecursiveResourceCalculator
    if rrc_version_change then
        Updates.update_from(rrc_version_change.old_version)
    end

    global.computation_stack = {}
    Cacher.cache()
    for _, player in pairs(game.players) do
        Reinitializer.reinitialize(player.index)
        Calculator.recompute_everything(player.index)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    Initializer.initialize_player_data(event.player_index)
    Calculator.build(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_player_removed, function(event)
    global[event.player_index] = nil
end)

script.on_event("hxrrc_toggle_calculator", function(event)
    Calculator.toggle(game.get_player(event.player_index))
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "hxrrc_calculator" and event.element.visible then
        Calculator.toggle(game.get_player(event.player_index))
    end
end)

script.on_event(defines.events.on_gui_click, Calculator.on_gui_click)

script.on_event(defines.events.on_gui_elem_changed, Calculator.on_gui_elem_changed)

script.on_event(defines.events.on_gui_confirmed, Calculator.on_gui_confirmed)

script.on_event(defines.events.on_tick, Calculator.on_tick)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting == "hxrrc-displayed-floating-point-precision" then
        Calculator.recompute_everything(event.player_index)
    end
end)