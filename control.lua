event_handlers = {}
event_handlers.on_gui_click = {}
event_handlers.on_gui_confirmed = {}
event_handlers.on_gui_elem_changed = {}

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

--Register handlers for which event.element.name exists
for _, event_type in ipairs({
    "on_gui_click",
    "on_gui_elem_changed",
    "on_gui_confirmed",
    }) do
    script.on_event(defines.events[event_type], function(event)
        local handler = event_handlers[event_type][event.element.name]
        if handler then handler(event) end
    end)
end

--Do each sheet calculation in its own tick
script.on_event(defines.events.on_tick, function()
    if global.computation_stack[1] then
        local call_and_parameters = table.remove(global.computation_stack)
        call_and_parameters.call(table.unpack(call_and_parameters.parameters))
        local player_index = call_and_parameters.player_index
        game.get_player(player_index).gui.screen.hxrrc_calculator.enabled = global[player_index].backlogged_computation_count == 0
    end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting == "hxrrc-displayed-floating-point-precision" then
        Calculator.recompute_everything(event.player_index)
    end
end)