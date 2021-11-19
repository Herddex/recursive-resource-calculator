local Calculator = require "gui/calculator"
local Cacher = require "logic/cacher"
local Initializer = require "logic/initializer"
local Reinitializer = require "logic/reinitializer"

script.on_init(function()
    Cacher.cache()
    global.computation_stack = {}
    for _, player in pairs(game.players) do
        Initializer.initialize_player_data(player.index)
        Calculator.build(player)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    Initializer.initialize_player_data(event.player_index)
    Calculator.build(game.get_player(event.player_index))
end)

local function check_for_deleted_modules()
    for _, module in pairs(global.modules_by_name) do
        if not module.valid then
            modules_were_deleted = true
            return
        end
    end
    modules_were_deleted = false
end

script.on_configuration_changed(function()
    global.computation_stack = {}
    check_for_deleted_modules()
    Cacher.cache()
    for _, player in pairs(game.players) do
        Reinitializer.reinitialize(player.index)
        Calculator.recompute_everything(player.index)
    end
end)

script.on_event(defines.events.on_player_removed, function(event)
    Calculator.destroy(game.get_player(event.player_index))
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
    Calculator.recompute_everything(event.player_index)
end)