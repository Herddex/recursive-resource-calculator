local Calculator = require "gui/calculator"
local Rational = require "utils/rational"
local Cacher = require "logic/cacher"

--Create/Destroy calucators:
script.on_init(function()
    Cacher.cache()
    for _, player in pairs(game.players) do
        Calculator.build(player)
    end
end)
script.on_event(defines.events.on_player_created, function(event)
    Calculator.build(game.get_player(event.player_index))
end)
script.on_configuration_changed(function(config_changed_data)
    Cacher.cache()
    for _, player in pairs(game.players) do
        Calculator.destroy(player)
        Calculator.build(player)
    end
end)
script.on_event(defines.events.on_player_removed, function(event)
    Calculator.destroy(game.get_player(event.player_index))
end)
script.on_event("hxrrc_reset_calculator", function(event)
    Calculator.destroy(game.get_player(event.player_index))
    Calculator.build(game.get_player(event.player_index))
end)

--Open/close calculator:
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