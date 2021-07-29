local Calculator = require "gui/calculator"
local Rational = require "utils/rational"
local Decomposer = require "logic/decomposer"
local RecipeCacher = require "logic/recipe_cacher"

--Create/Destroy calucators:
script.on_init(function()
    RecipeCacher.cache()
    for _, player in pairs(game.players) do
        global[player.index] = {}
        Calculator.build(player)
    end
end)
script.on_event(defines.events.on_player_created, function(event)
    global[event.player_index] = {}
    Calculator.build(game.get_player(event.player_index))
end)
script.on_configuration_changed(function(config_changed_data)
    RecipeCacher.cache()
    for _, player in pairs(game.players) do
        Calculator.destroy(player)
        Calculator.build(player)
    end
end)
script.on_event(defines.events.on_player_removed, function(event)
    global[player.index] = nil
    Calculator.destroy(game.get_player(event.player_index))
end)
script.on_event("hxrrc_rebuild_calculator", function(event) --for debugging only
    Calculator.destroy(game.get_player(event.player_index))
    RecipeCacher.cache()
    Calculator.build(game.get_player(event.player_index))
end)

--Open/close calcualtors:
script.on_event("hxrrc_toggle_calculator", function(event)
    Calculator.toggle(game.get_player(event.player_index))
end)
script.on_event(defines.events.on_gui_closed, function(event)
    if event.element and event.element.name == "hxrrc_calculator" and event.element.visible then
        Calculator.toggle(game.get_player(event.player_index))
    end
end)

--Read and dispatch calculator input:
script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "hxrrc_confirmation_button" then
        --Attempt to do the calculation:
        Calculator.calculate(game.get_player(event.player_index))
    end
end)